import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2026, 10, 8);
final oldAccount = DateTime.utc(2020);

const catalog = Catalog(
  categories: {'state': 'State'},
  projects: [
    Project(id: 'flutter_bloc', name: 'Bloc', repo: 'felangel/bloc', categories: ['state']),
  ],
  hallOfFame: HallOfFameEdition(
    year: 2026,
    projects: [HallOfFameProject(id: 'flutter_bloc', category: 'Most Influential', reason: '…')],
    developers: [HallOfFameDeveloper(handle: 'felangel', name: 'Felix', category: 'x', tagline: 'y')],
  ),
);

String developerBody(String handle, {String reason = 'Great work'}) =>
    '### GitHub username\n\n$handle\n\n### Why they deserve it\n\n$reason';

String projectBody(String repo, {String category = 'Best UI'}) =>
    '### Repository\n\n$repo\n\n### Award category\n\n$category\n\n### Why they deserve it\n\n_No response_';

TriageResult triage(Nomination? n, {NominationFacts? facts}) => triageNomination(
  n,
  facts ?? NominationFacts(number: 10, author: 'alice', authorCreatedAt: oldAccount),
  catalog: catalog,
  now: now,
);

NominationFacts facts({
  GhAccount? developer,
  GhRepoInfo? repo,
  List<OpenNomination> open = const [],
  DateTime? authorCreatedAt,
}) => NominationFacts(
  number: 10,
  author: 'alice',
  authorCreatedAt: authorCreatedAt ?? oldAccount,
  openNominations: open,
  developer: developer,
  repo: repo,
);

GhAccount user(String login, {bool org = false}) => GhAccount(login: login, isOrganization: org, createdAt: oldAccount);

void main() {
  group('parseNomination', () {
    test('reads a developer form, accepting URLs and @handles', () {
      for (final raw in ['remi', '@remi', 'https://github.com/remi/']) {
        final n = parseNomination(developerBody(raw)) as DeveloperNomination;
        expect(n.handle, 'remi');
        expect(n.reason, 'Great work');
      }
    });

    test('reads a project form and treats "_No response_" as empty', () {
      final n = parseNomination(projectBody('https://github.com/gskinnerTeam/flutter-wonderous-app.git'))!;
      expect(n, isA<ProjectNomination>());
      n as ProjectNomination;
      expect(n.repo, 'gskinnerTeam/flutter-wonderous-app');
      expect(n.category, 'Best UI');
      expect(n.reason, '');
    });

    test('rejects malformed or unrelated bodies', () {
      expect(parseNomination('just some text'), isNull);
      expect(parseNomination(developerBody('not a handle!')), isNull);
      expect(parseNomination(projectBody('no-slash')), isNull);
      expect(parseNomination(projectBody('a/b', category: '_No response_')), isNull);
    });
  });

  group('triageNomination', () {
    const dev = DeveloperNomination(handle: 'remi');
    const project = ProjectNomination(repo: 'acme/ui', category: 'Best UI');
    const goodRepo = GhRepoInfo(fullName: 'acme/ui', stars: 500);

    test('accepts a valid developer nomination', () {
      final r = triage(dev, facts: facts(developer: user('remi')));
      expect(r.outcome, TriageOutcome.accept);
      expect(r.comment, contains('👍'));
    });

    test('accepts a valid project and flags that it is untracked', () {
      final r = triage(project, facts: facts(repo: goodRepo));
      expect(r.outcome, TriageOutcome.accept);
      expect(r.comment, contains("isn't tracked"));
    });

    test('rejects an incomplete form', () => expect(triage(null).outcome, TriageOutcome.reject));

    test('rejects new accounts but skips the check when the lookup failed', () {
      final young = facts(developer: user('remi'), authorCreatedAt: now.subtract(const Duration(days: 3)));
      expect(triage(dev, facts: young).comment, contains('30 days'));
      final unknown = NominationFacts(number: 10, author: 'alice', authorCreatedAt: null, developer: user('remi'));
      expect(triage(dev, facts: unknown).outcome, TriageOutcome.accept);
    });

    test('caps open nominations per author, case-insensitively', () {
      final open = [
        for (final n in [1, 2, 3]) OpenNomination(number: n, author: n.isOdd ? 'Alice' : 'alice', nomination: null),
        const OpenNomination(number: 4, author: 'bob', nomination: null),
      ];
      final r = triage(
        dev,
        facts: facts(developer: user('remi'), open: open),
      );
      expect(r.outcome, TriageOutcome.reject);
      expect(r.comment, contains('already have 3'));
      expect(
        triage(
          dev,
          facts: facts(developer: user('remi'), open: open.sublist(1)),
        ).outcome,
        TriageOutcome.accept,
      );
    });

    test('rejects missing accounts, organizations and current inductees', () {
      expect(triage(dev, facts: facts()).comment, contains("couldn't find"));
      expect(triage(dev, facts: facts(developer: user('remi', org: true))).comment, contains('organization'));
      final inducted = triage(
        const DeveloperNomination(handle: 'FELANGEL'),
        facts: facts(developer: user('felangel')),
      );
      expect(inducted.comment, contains('already in the 2026 Hall of Fame'));
    });

    test('rejects missing, archived, forked, small and inducted repos', () {
      String why(GhRepoInfo? r) => triage(project, facts: facts(repo: r)).comment;
      expect(why(null), contains("couldn't find"));
      expect(why(const GhRepoInfo(fullName: 'acme/ui', stars: 500, archived: true)), contains('archived'));
      expect(why(const GhRepoInfo(fullName: 'acme/ui', stars: 500, fork: true)), contains('fork'));
      expect(why(const GhRepoInfo(fullName: 'acme/ui', stars: 49)), contains('at least 50'));
      expect(why(const GhRepoInfo(fullName: 'Felangel/Bloc', stars: 9000)), contains('already in the 2026'));
    });

    test('closes duplicates of an earlier nomination, matching renamed repos', () {
      final open = [
        const OpenNomination(
          number: 7,
          author: 'bob',
          nomination: ProjectNomination(repo: 'Acme/UI', category: 'x'),
        ),
        const OpenNomination(
          number: 3,
          author: 'carol',
          nomination: ProjectNomination(repo: 'acme/old-ui', category: 'x'),
        ),
        const OpenNomination(
          number: 12,
          author: 'dan',
          nomination: ProjectNomination(repo: 'acme/ui', category: 'x'),
        ),
      ];
      final r = triage(
        const ProjectNomination(repo: 'acme/old-ui', category: 'Best UI'),
        facts: facts(repo: goodRepo, open: open),
      );
      expect(r.outcome, TriageOutcome.duplicate);
      expect(r.comment, contains('#3'));
      // A later issue (#12) never makes an earlier one a duplicate.
      expect(
        triage(
          project,
          facts: facts(repo: goodRepo, open: [open[2]]),
        ).outcome,
        TriageOutcome.accept,
      );
    });
  });

  group('GithubClient REST lookups', () {
    final client = MockClient((req) async {
      return switch (req.url.path) {
        '/users/remi' => http.Response(
          jsonEncode({'login': 'rrousselGit', 'type': 'User', 'created_at': '2015-01-01T00:00:00Z'}),
          200,
        ),
        '/repos/old/name' => http.Response(
          jsonEncode({'full_name': 'new/name', 'stargazers_count': 42, 'archived': false, 'fork': true}),
          200,
        ),
        '/repos/me/site/issues' => http.Response(
          jsonEncode([
            {
              'number': 1,
              'user': {'login': 'a'},
              'body': developerBody('remi'),
            },
            {
              'number': 2,
              'user': {'login': 'b'},
              'body': 'x',
              'pull_request': <String, Object?>{},
            },
          ]),
          200,
        ),
        _ => http.Response('{"message":"Not Found"}', 404),
      };
    });
    final gh = GithubClient(client, token: 't', retryDelay: Duration.zero);

    test('account and repoInfo follow canonical names; 404 is null', () async {
      final a = (await gh.account('remi'))!;
      expect((a.login, a.isOrganization, a.createdAt.year), ('rrousselGit', false, 2015));
      final r = (await gh.repoInfo('old/name'))!;
      expect((r.fullName, r.stars, r.fork), ('new/name', 42, true));
      expect(await gh.account('ghost'), isNull);
    });

    test('openNominations skips pull requests and parses bodies', () async {
      final open = await gh.openNominations('me/site');
      expect(open.map((o) => o.number), [1]);
      expect(open.single.nomination?.target, 'developer:remi');
    });
  });
}
