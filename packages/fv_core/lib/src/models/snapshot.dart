import '../json.dart';

/// Raw counters for one project on one day; one line in `history/<id>.ndjson`.
class Snapshot {
  const Snapshot({
    required this.date,
    this.stars,
    this.forks,
    this.openIssues,
    this.likes,
    this.points,
    this.downloads,
  });

  /// UTC calendar day, `YYYY-MM-DD`.
  final String date;
  final int? stars;
  final int? forks;
  final int? openIssues;
  final int? likes;
  final int? points;
  final int? downloads;

  DateTime get day => DateTime.parse('${date}T00:00:00Z');

  static String dayOf(DateTime t) => t.toUtc().toIso8601String().substring(0, 10);

  factory Snapshot.fromJson(Json json) => Snapshot(
    date: json['date'] as String,
    stars: asInt(json['stars']),
    forks: asInt(json['forks']),
    openIssues: asInt(json['openIssues']),
    likes: asInt(json['likes']),
    points: asInt(json['points']),
    downloads: asInt(json['downloads']),
  );

  Json toJson() => compact({
    'date': date,
    'stars': stars,
    'forks': forks,
    'openIssues': openIssues,
    'likes': likes,
    'points': points,
    'downloads': downloads,
  });
}
