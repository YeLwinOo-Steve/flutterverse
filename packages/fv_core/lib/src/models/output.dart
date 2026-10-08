import '../json.dart';
import '../metrics/maintenance.dart';
import 'catalog.dart';
import 'gh_stats.dart';
import 'project.dart';
import 'pub_stats.dart';
import 'roadmap.dart';
import 'snapshot.dart';

/// One row of `index.json`: everything the tables, cards and lists need.
///
/// Any number can be null when its source failed or history is too short;
/// the UI shows "N/A". `—` is reserved for "not applicable" (e.g. pub.dev
/// numbers for an unpublished project, where [pub] is null).
class ProjectRow {
  const ProjectRow({
    required this.id,
    required this.name,
    this.kind = ProjectKind.package,
    this.sdk,
    this.owner,
    this.publisher,
    this.pub,
    this.repo,
    this.categories = const [],
    this.description,
    this.platforms = const [],
    this.stars,
    this.stars1d,
    this.stars7d,
    this.stars30d,
    this.stars365d,
    this.momentum,
    this.maintenance,
    this.likes,
    this.points,
    this.maxPoints,
    this.downloads,
    this.downloadGrowth,
    this.version,
    this.released,
    this.lastCommit,
    this.flutterFavorite = false,
    this.archived = false,
    this.sharedRepo = false,
    this.spark,
  });

  final String id;
  final String name;
  final ProjectKind kind;

  /// `Dart` or `Flutter`.
  final String? sdk;

  /// GitHub owner (or pub.dev publisher when there's no repo).
  final String? owner;

  /// The verified pub.dev publisher, e.g. `dart.dev`.
  final String? publisher;
  final String? pub;
  final String? repo;

  /// Category slugs; labels are in [IndexFile.categories].
  final List<String> categories;
  final String? description;
  final List<String> platforms;
  final int? stars;
  final int? stars1d;
  final int? stars7d;
  final int? stars30d;
  final int? stars365d;
  final int? momentum;
  final Maintenance? maintenance;
  final int? likes;
  final int? points;
  final int? maxPoints;
  final int? downloads;

  /// Relative change in weekly downloads over the last quarter.
  final double? downloadGrowth;
  final String? version;

  /// When [version] was published.
  final DateTime? released;
  final DateTime? lastCommit;
  final bool flutterFavorite;
  final bool archived;

  /// The repo is shared with other tracked packages, so repo-wide counters
  /// are omitted.
  final bool sharedRepo;

  /// Stars gained per day over the last 30 days, oldest first.
  final List<int>? spark;

  bool get isPublished => pub != null;

  /// 30-day star growth as a share of the stars 30 days ago.
  double? get growth30 {
    final s = stars, d = stars30d;
    if (s == null || d == null || s - d <= 0) return null;
    return d / (s - d);
  }

  factory ProjectRow.build({
    required Project project,
    PubStats? pub,
    GhStats? gh,
    bool sharedRepo = false,
    int? stars1d,
    int? stars7d,
    int? stars30d,
    int? stars365d,
    int? momentum,
    Maintenance? maintenance,
    List<int>? spark,
  }) => ProjectRow(
    id: project.id,
    name: project.name,
    kind: project.kind,
    // Pure-Dart packages are tagged for both SDKs; Flutter-only ones aren't
    // tagged `sdk:dart`.
    sdk: project.sdk ?? (pub == null ? null : (pub.sdks.contains('Dart') ? 'Dart' : 'Flutter')),
    owner: project.owner ?? pub?.publisher,
    publisher: pub?.publisher,
    pub: project.pub,
    repo: project.repo,
    categories: project.categories,
    description: project.description ?? pub?.description ?? gh?.description?.trim(),
    platforms: project.platforms ?? pub?.platforms ?? const [],
    stars: gh?.stars,
    stars1d: stars1d,
    stars7d: stars7d,
    stars30d: stars30d,
    stars365d: stars365d,
    momentum: momentum,
    maintenance: maintenance,
    likes: pub?.likes,
    points: pub?.points,
    maxPoints: pub?.maxPoints,
    downloads: pub?.downloads,
    downloadGrowth: pub?.downloadGrowth,
    version: pub?.version,
    released: pub?.published,
    lastCommit: gh?.lastCommit,
    flutterFavorite: pub?.flutterFavorite ?? false,
    archived: gh?.archived ?? false,
    sharedRepo: sharedRepo,
    spark: spark,
  );

  factory ProjectRow.fromJson(Json json) => ProjectRow(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: ProjectKind.parse(json['kind'] as String?),
    sdk: json['sdk'] as String?,
    owner: json['owner'] as String?,
    publisher: json['publisher'] as String?,
    pub: json['pub'] as String?,
    repo: json['repo'] as String?,
    categories: asStrings(json['categories']),
    description: json['description'] as String?,
    platforms: asStrings(json['platforms']),
    stars: asInt(json['stars']),
    stars1d: asInt(json['stars1d']),
    stars7d: asInt(json['stars7d']),
    stars30d: asInt(json['stars30d']),
    stars365d: asInt(json['stars365d']),
    momentum: asInt(json['momentum']),
    maintenance: Maintenance.parse(json['maintenance'] as String?),
    likes: asInt(json['likes']),
    points: asInt(json['points']),
    maxPoints: asInt(json['maxPoints']),
    downloads: asInt(json['downloads']),
    downloadGrowth: asDouble(json['downloadGrowth']),
    version: json['version'] as String?,
    released: asDate(json['released']),
    lastCommit: asDate(json['lastCommit']),
    flutterFavorite: json['flutterFavorite'] as bool? ?? false,
    archived: json['archived'] as bool? ?? false,
    sharedRepo: json['sharedRepo'] as bool? ?? false,
    spark: asIntsOrNull(json['spark']),
  );

  Json toJson() => compact({
    'id': id,
    'name': name,
    'kind': kind == ProjectKind.project ? 'project' : null,
    'sdk': sdk,
    'owner': owner,
    'publisher': publisher,
    'pub': pub,
    'repo': repo,
    'categories': categories,
    'description': description,
    'platforms': platforms.isEmpty ? null : platforms,
    'stars': stars,
    'stars1d': stars1d,
    'stars7d': stars7d,
    'stars30d': stars30d,
    'stars365d': stars365d,
    'momentum': momentum,
    'maintenance': maintenance?.name,
    'likes': likes,
    'points': points,
    'maxPoints': maxPoints,
    'downloads': downloads,
    'downloadGrowth': downloadGrowth == null ? null : (downloadGrowth! * 1000).round() / 1000,
    'version': version,
    'released': isoDate(released),
    'lastCommit': isoDate(lastCommit),
    'flutterFavorite': flutterFavorite ? true : null,
    'archived': archived ? true : null,
    'sharedRepo': sharedRepo ? true : null,
    'spark': spark,
  });
}

/// `p/<id>.json`: the full detail page.
class ProjectDetail {
  const ProjectDetail({required this.row, this.pub, this.gh, this.history = const [], this.related = const []});

  final ProjectRow row;
  final PubStats? pub;
  final GhStats? gh;

  /// Every snapshot since tracking began, oldest first.
  final List<Snapshot> history;

  /// [Project.related] ids.
  final List<String> related;

  factory ProjectDetail.fromJson(Json json) => ProjectDetail(
    row: ProjectRow.fromJson(json['row'] as Json),
    pub: json['pub'] == null ? null : PubStats.fromJson(json['pub'] as Json),
    gh: json['gh'] == null ? null : GhStats.fromJson(json['gh'] as Json),
    history: asList(json['history'], Snapshot.fromJson),
    related: asStrings(json['related']),
  );

  Json toJson() => compact({
    'row': row.toJson(),
    'pub': pub?.toJson(),
    'gh': gh?.toJson(),
    'history': [for (final s in history) s.toJson()],
    'related': related.isEmpty ? null : related,
  });
}

/// `index.json`.
class IndexFile {
  const IndexFile({required this.categories, required this.projects, this.categoryGroups = const {}});

  final Map<String, String> categories;
  final Map<String, List<String>> categoryGroups;
  final List<ProjectRow> projects;

  factory IndexFile.fromJson(Json json) => IndexFile(
    categories: (json['categories'] as Json).cast<String, String>(),
    categoryGroups: {
      for (final e in (json['categoryGroups'] as Json? ?? const {}).entries) e.key: asStrings(e.value),
    },
    projects: asList(json['projects'], ProjectRow.fromJson),
  );

  Json toJson() => {
    'categories': categories,
    'categoryGroups': categoryGroups,
    'projects': [for (final p in projects) p.toJson()],
  };
}

/// `pub.json`: pub.dev-wide data that isn't tied to one tracked project.
class PubFile {
  const PubFile({this.flutterFavorites});

  /// Every Flutter Favorite package name, or null if the search failed.
  final List<String>? flutterFavorites;

  factory PubFile.fromJson(Json json) =>
      PubFile(flutterFavorites: json['flutterFavorites'] == null ? null : asStrings(json['flutterFavorites']));

  Json toJson() => {'flutterFavorites': flutterFavorites};
}

/// `hof.json`: the current edition, with developer stats filled in.
class HallOfFameFile {
  const HallOfFameFile({this.edition});

  final HallOfFameEdition? edition;

  factory HallOfFameFile.fromJson(Json json) =>
      HallOfFameFile(edition: json['edition'] == null ? null : HallOfFameEdition.fromJson(json['edition'] as Json));

  Json toJson() => {'edition': edition?.toJson()};
}

/// `roadmap.json`.
class RoadmapFile {
  const RoadmapFile({required this.tracks});

  /// Track id → track, in display order.
  final Map<String, RoadmapTrack> tracks;

  factory RoadmapFile.fromJson(Json json) => RoadmapFile(
    tracks: {for (final e in json.entries) e.key: RoadmapTrack.fromJson(e.value as Json)},
  );

  Json toJson() => {for (final e in tracks.entries) e.key: e.value.toJson()};
}

/// `meta.json`.
class Meta {
  const Meta({required this.generatedAt, required this.projectCount, this.schema = schemaVersion});

  final DateTime generatedAt;
  final int projectCount;
  final int schema;

  factory Meta.fromJson(Json json) => Meta(
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    projectCount: asInt(json['projectCount'])!,
    schema: asInt(json['schema'])!,
  );

  Json toJson() => {
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'projectCount': projectCount,
    'schema': schema,
  };
}
