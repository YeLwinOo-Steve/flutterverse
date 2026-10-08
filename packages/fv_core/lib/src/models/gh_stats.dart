import '../json.dart';

/// Current GitHub numbers for a repository.
class GhStats {
  const GhStats({
    this.stars,
    this.forks,
    this.openIssues,
    this.watchers,
    this.contributors,
    this.createdAt,
    this.pushedAt,
    this.lastCommit,
    this.license,
    this.languages = const [],
    this.topics = const [],
    this.archived = false,
    this.description,
  });

  final int? stars;
  final int? forks;
  final int? openIssues;
  final int? watchers;
  final int? contributors;
  final DateTime? createdAt;
  final DateTime? pushedAt;

  /// Date of the latest commit on the default branch.
  final DateTime? lastCommit;

  /// SPDX identifier, e.g. `MIT`.
  final String? license;

  /// Top languages with their share, e.g. `Dart 99.6%`.
  final List<String> languages;
  final List<String> topics;
  final bool archived;
  final String? description;

  /// Drops the repo-wide counters (stars, forks, issues, watchers,
  /// contributors), keeping activity and license. Used when several tracked
  /// packages share one monorepo, where those counters say nothing about any
  /// single package.
  GhStats withoutCounters() => GhStats(
    createdAt: createdAt,
    pushedAt: pushedAt,
    lastCommit: lastCommit,
    license: license,
    languages: languages,
    topics: topics,
    archived: archived,
    description: description,
  );

  factory GhStats.fromJson(Json json) => GhStats(
    stars: asInt(json['stars']),
    forks: asInt(json['forks']),
    openIssues: asInt(json['openIssues']),
    watchers: asInt(json['watchers']),
    contributors: asInt(json['contributors']),
    createdAt: asDate(json['createdAt']),
    pushedAt: asDate(json['pushedAt']),
    lastCommit: asDate(json['lastCommit']),
    license: json['license'] as String?,
    languages: asStrings(json['languages']),
    topics: asStrings(json['topics']),
    archived: json['archived'] as bool? ?? false,
    description: json['description'] as String?,
  );

  Json toJson() => compact({
    'stars': stars,
    'forks': forks,
    'openIssues': openIssues,
    'watchers': watchers,
    'contributors': contributors,
    'createdAt': isoDate(createdAt),
    'pushedAt': isoDate(pushedAt),
    'lastCommit': isoDate(lastCommit),
    'license': license,
    'languages': languages.isEmpty ? null : languages,
    'topics': topics.isEmpty ? null : topics,
    'archived': archived ? true : null,
    'description': description,
  });
}
