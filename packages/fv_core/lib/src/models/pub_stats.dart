import '../json.dart';

/// A version released on pub.dev.
class Release {
  const Release({required this.version, required this.date});

  final String version;
  final DateTime date;

  factory Release.fromJson(Json json) =>
      Release(version: json['version'] as String, date: DateTime.parse(json['date'] as String));

  Json toJson() => {'version': version, 'date': isoDate(date)};
}

/// Current pub.dev numbers for a package.
class PubStats {
  const PubStats({
    this.version,
    this.published,
    this.firstPublished,
    this.releasesLastYear,
    this.majors = const [],
    this.likes,
    this.points,
    this.maxPoints,
    this.downloads,
    this.weeklyDownloads,
    this.weeklyDownloadsEnd,
    this.publisher,
    this.description,
    this.repository,
    this.license,
    this.dartSdk,
    this.flutterSdk,
    this.sdks = const [],
    this.platforms = const [],
    this.flutterFavorite = false,
  });

  final String? version;

  /// When [version] was published.
  final DateTime? published;
  final DateTime? firstPublished;

  /// Versions published in the 365 days before the snapshot.
  final int? releasesLastYear;

  /// The first stable release of each major version from 1.0.0 on.
  final List<Release> majors;
  final int? likes;
  final int? points;
  final int? maxPoints;

  /// Downloads over the last 30 days.
  final int? downloads;

  /// Up to 52 weekly download counts, oldest first, ending last week.
  final List<int>? weeklyDownloads;

  /// The day the last week in [weeklyDownloads] ends.
  final DateTime? weeklyDownloadsEnd;
  final String? publisher;
  final String? description;

  /// The pubspec `repository` (or `homepage`) URL.
  final String? repository;

  /// SPDX-style license from pub.dev's tags, e.g. `MIT`.
  final String? license;

  /// The pubspec's Dart SDK constraint, e.g. `^3.6.0`.
  final String? dartSdk;

  /// The pubspec's Flutter SDK constraint, if any.
  final String? flutterSdk;

  /// `Dart`, `Flutter`.
  final List<String> sdks;

  /// Display names: `iOS`, `Android`, `Web`, `WASM`, `macOS`, `Windows`, `Linux`.
  final List<String> platforms;
  final bool flutterFavorite;

  /// Relative change in weekly downloads over the last quarter (13 weeks).
  double? get downloadGrowth {
    final w = weeklyDownloads;
    if (w == null || w.length < 14) return null;
    final then = w[w.length - 14];
    return then == 0 ? null : (w.last - then) / then;
  }

  PubStats copyWith({bool? flutterFavorite}) => PubStats(
    version: version,
    published: published,
    firstPublished: firstPublished,
    releasesLastYear: releasesLastYear,
    majors: majors,
    likes: likes,
    points: points,
    maxPoints: maxPoints,
    downloads: downloads,
    weeklyDownloads: weeklyDownloads,
    weeklyDownloadsEnd: weeklyDownloadsEnd,
    publisher: publisher,
    description: description,
    repository: repository,
    license: license,
    dartSdk: dartSdk,
    flutterSdk: flutterSdk,
    sdks: sdks,
    platforms: platforms,
    flutterFavorite: flutterFavorite ?? this.flutterFavorite,
  );

  factory PubStats.fromJson(Json json) => PubStats(
    version: json['version'] as String?,
    published: asDate(json['published']),
    firstPublished: asDate(json['firstPublished']),
    releasesLastYear: asInt(json['releasesLastYear']),
    majors: asList(json['majors'], Release.fromJson),
    likes: asInt(json['likes']),
    points: asInt(json['points']),
    maxPoints: asInt(json['maxPoints']),
    downloads: asInt(json['downloads']),
    weeklyDownloads: asIntsOrNull(json['weeklyDownloads']),
    weeklyDownloadsEnd: asDate(json['weeklyDownloadsEnd']),
    publisher: json['publisher'] as String?,
    description: json['description'] as String?,
    repository: json['repository'] as String?,
    license: json['license'] as String?,
    dartSdk: json['dartSdk'] as String?,
    flutterSdk: json['flutterSdk'] as String?,
    sdks: asStrings(json['sdks']),
    platforms: asStrings(json['platforms']),
    flutterFavorite: json['flutterFavorite'] as bool? ?? false,
  );

  Json toJson() => compact({
    'version': version,
    'published': isoDate(published),
    'firstPublished': isoDate(firstPublished),
    'releasesLastYear': releasesLastYear,
    'majors': majors.isEmpty ? null : [for (final r in majors) r.toJson()],
    'likes': likes,
    'points': points,
    'maxPoints': maxPoints,
    'downloads': downloads,
    'weeklyDownloads': weeklyDownloads,
    'weeklyDownloadsEnd': isoDate(weeklyDownloadsEnd),
    'publisher': publisher,
    'description': description,
    'repository': repository,
    'license': license,
    'dartSdk': dartSdk,
    'flutterSdk': flutterSdk,
    'sdks': sdks,
    'platforms': platforms,
    'flutterFavorite': flutterFavorite ? true : null,
  });
}
