import 'package:fv_core/fv_core.dart';

/// Field labels shared with `.github/ISSUE_TEMPLATE/nominate-*.yml`. GitHub
/// renders each issue-form field as `### <label>` followed by its value, so
/// renaming a label there means renaming it here too.
abstract final class NominationField {
  static const username = 'GitHub username';
  static const repo = 'Repository';
  static const category = 'Award category';
  static const reason = 'Why they deserve it';
}

/// A Hall of Fame nomination parsed from an issue-form body.
sealed class Nomination {
  const Nomination({required this.reason});

  final String reason;

  /// What two nominations must share to count as duplicates (lowercased).
  String get target;
}

final class DeveloperNomination extends Nomination {
  const DeveloperNomination({required this.handle, super.reason = ''});

  final String handle;

  @override
  String get target => 'developer:${handle.toLowerCase()}';
}

final class ProjectNomination extends Nomination {
  const ProjectNomination({required this.repo, required this.category, super.reason = ''});

  /// `owner/name`.
  final String repo;
  final String category;

  @override
  String get target => 'project:${repo.toLowerCase()}';
}

final _section = RegExp(r'^###\s+(.+?)\s*$', multiLine: true);
final _handle = RegExp(r'^(?:https?://)?(?:www\.)?(?:github\.com/)?@?([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))/?$');
final _repo = RegExp(
  r'^(?:https?://)?(?:www\.)?(?:github\.com/)?([A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}?)(?:\.git)?/?$',
);

/// Parses an issue-form body. Returns null when it isn't a nomination form or
/// a required field is missing or malformed.
Nomination? parseNomination(String body) {
  final fields = <String, String>{};
  final heads = _section.allMatches(body).toList();
  for (final (i, m) in heads.indexed) {
    final end = i + 1 < heads.length ? heads[i + 1].start : body.length;
    final value = body.substring(m.end, end).trim();
    fields[m[1]!] = value == '_No response_' ? '' : value;
  }
  final reason = fields[NominationField.reason] ?? '';
  if (fields[NominationField.username] case final raw?) {
    final handle = _handle.firstMatch(raw.trim())?[1];
    return handle == null ? null : DeveloperNomination(handle: handle, reason: reason);
  }
  if (fields[NominationField.repo] case final raw?) {
    final repo = _repo.firstMatch(raw.trim())?[1];
    final category = fields[NominationField.category] ?? '';
    if (repo == null || category.isEmpty) return null;
    return ProjectNomination(repo: repo, category: category, reason: reason);
  }
  return null;
}

/// A GitHub user or organization, from `GET /users/<login>`.
class GhAccount {
  const GhAccount({required this.login, required this.isOrganization, required this.createdAt});

  final String login;
  final bool isOrganization;
  final DateTime createdAt;
}

/// The repository facts triage needs, from `GET /repos/<owner>/<name>`.
class GhRepoInfo {
  const GhRepoInfo({required this.fullName, required this.stars, this.archived = false, this.fork = false});

  /// Canonical `owner/name` (follows renames and transfers).
  final String fullName;
  final int stars;
  final bool archived;
  final bool fork;
}

/// Another open nomination issue.
class OpenNomination {
  const OpenNomination({required this.number, required this.author, required this.nomination});

  final int number;
  final String author;
  final Nomination? nomination;
}

/// Limits that keep the nomination queue reviewable.
class NominationRules {
  const NominationRules({this.maxOpenPerAuthor = 3, this.minAccountAge = const Duration(days: 30), this.minStars = 50});

  /// Open nominations one person may have at a time, this one included.
  final int maxOpenPerAuthor;

  /// Brand-new accounts are a common spam source.
  final Duration minAccountAge;

  /// Projects below this aren't plausible Hall of Fame entries yet.
  final int minStars;
}

/// Everything [triageNomination] decides from, gathered by the caller.
class NominationFacts {
  const NominationFacts({
    required this.number,
    required this.author,
    required this.authorCreatedAt,
    this.openNominations = const [],
    this.developer,
    this.repo,
  });

  /// This issue.
  final int number;
  final String author;

  /// Null when the author's account couldn't be looked up.
  final DateTime? authorCreatedAt;

  /// Other open nomination issues (this one may be included; it's skipped).
  final List<OpenNomination> openNominations;

  /// The nominated account, or null if it doesn't exist.
  final GhAccount? developer;

  /// The nominated repository, or null if it doesn't exist.
  final GhRepoInfo? repo;
}

enum TriageOutcome {
  /// Valid: label it for the editorial team.
  accept('needs-review'),

  /// Close it as a duplicate of another open nomination.
  duplicate('duplicate'),

  /// Close it: malformed, over a limit, or not eligible.
  reject('invalid');

  const TriageOutcome(this.label);

  /// Label added to the issue.
  final String label;
}

typedef TriageResult = ({TriageOutcome outcome, String comment});

/// Decides what happens to a new nomination issue. Pure, so every rule can be
/// unit-tested; `bin/triage_nomination.dart` gathers the facts and applies
/// the result.
TriageResult triageNomination(
  Nomination? nomination,
  NominationFacts facts, {
  required Catalog catalog,
  required DateTime now,
  NominationRules rules = const NominationRules(),
}) {
  TriageResult reject(String why) => (outcome: TriageOutcome.reject, comment: '$why\n\n$_footer');

  if (nomination == null) {
    return reject(
      "Thanks! This doesn't look like a complete nomination form, so I'm closing it. "
      'Please use one of the nomination forms (or the **Propose** buttons on the Hall of Fame page).',
    );
  }
  if (facts.authorCreatedAt case final created? when now.difference(created) < rules.minAccountAge) {
    return reject(
      'Thanks! To keep the queue free of spam, nominations need a GitHub account at least '
      '${rules.minAccountAge.inDays} days old. Please try again later.',
    );
  }
  final others = facts.openNominations.where((o) => o.number != facts.number).toList();
  final mine = others.where((o) => o.author.toLowerCase() == facts.author.toLowerCase()).length;
  if (mine + 1 > rules.maxOpenPerAuthor) {
    return reject(
      'Thanks! Each person can have up to ${rules.maxOpenPerAuthor} open nominations at a time, and you '
      'already have $mine. You can nominate again once one of them is reviewed.',
    );
  }
  final hof = catalog.hallOfFame;

  switch (nomination) {
    case DeveloperNomination(:final handle):
      final dev = facts.developer;
      if (dev == null) return reject("Thanks! I couldn't find a GitHub account called `@$handle`.");
      if (dev.isOrganization) {
        return reject(
          '`@${dev.login}` is an organization. Developer nominations are for people; '
          "to recognise the organization's work, nominate one of its projects instead.",
        );
      }
      final inducted = hof?.developers.any((d) => d.handle.toLowerCase() == dev.login.toLowerCase()) ?? false;
      if (inducted) return reject('`@${dev.login}` is already in the ${hof!.year} Hall of Fame. 🎉');

    case ProjectNomination(:final repo):
      final info = facts.repo;
      if (info == null) return reject("Thanks! I couldn't find the GitHub repository `$repo`.");
      if (info.archived) return reject('`${info.fullName}` is archived, so it isn\'t eligible.');
      if (info.fork) return reject('`${info.fullName}` is a fork. Please nominate the upstream repository.');
      if (info.stars < rules.minStars) {
        return reject(
          '`${info.fullName}` has ${info.stars} stars; Hall of Fame projects need at least ${rules.minStars}. '
          'Keep building and nominate it again later!',
        );
      }
      final repos = {for (final p in catalog.projects) p.id: p.repo?.toLowerCase()};
      final inducted = hof?.projects.any((h) => repos[h.id] == info.fullName.toLowerCase()) ?? false;
      if (inducted) return reject('`${info.fullName}` is already in the ${hof!.year} Hall of Fame. 🎉');
  }

  final canonical = switch (nomination) {
    DeveloperNomination() => DeveloperNomination(handle: facts.developer!.login).target,
    ProjectNomination() => ProjectNomination(repo: facts.repo!.fullName, category: '').target,
  };
  final dupes = [
    for (final o in others)
      if (o.number < facts.number && (o.nomination?.target == canonical || o.nomination?.target == nomination.target))
        o.number,
  ]..sort();
  if (dupes.isNotEmpty) {
    return (
      outcome: TriageOutcome.duplicate,
      comment:
          'Thanks! This has already been nominated in #${dupes.first}. Please add a 👍 reaction there '
          '(and any extra context as a comment) instead.\n\n$_footer',
    );
  }

  final tracked = switch (nomination) {
    ProjectNomination() => catalog.projects.any((p) => p.repo?.toLowerCase() == facts.repo!.fullName.toLowerCase()),
    DeveloperNomination() => true,
  };
  return (
    outcome: TriageOutcome.accept,
    comment: [
      'Thanks for the nomination! The checks passed and the editorial team will review it before the next edition.',
      '',
      'Want to support it? Add a 👍 reaction to this issue; the team sorts the queue by reactions.',
      if (!tracked) ...[
        '',
        '_Note for reviewers: `${facts.repo!.fullName}` isn\'t tracked in `config/seeds.yaml` yet._',
      ],
      '',
      _footer,
    ].join('\n'),
  );
}

const _footer = '<sub>Automated triage. A maintainer can reopen this if it was closed by mistake.</sub>';
