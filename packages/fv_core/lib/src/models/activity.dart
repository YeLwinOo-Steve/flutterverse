import '../json.dart';
import 'snapshot.dart';

/// A repo's commits per day over the past year, from GitHub's weekly commit
/// activity stats. Kept between ingest runs and refreshed about weekly.
class CommitActivity {
  const CommitActivity({required this.start, required this.days, required this.fetched});

  /// The Sunday the first week starts on, `YYYY-MM-DD`.
  final String start;

  /// Commits per day from [start], whole weeks of seven. Days after
  /// [fetched] are zero.
  final List<int> days;

  /// When GitHub was asked, `YYYY-MM-DD`.
  final String fetched;

  int get total => days.fold(0, (a, b) => a + b);

  DateTime get startDay => DateTime.parse('${start}T00:00:00Z');
  DateTime get fetchedDay => DateTime.parse('${fetched}T00:00:00Z');

  /// The day [days] index [i] stands for.
  DateTime dayAt(int i) => startDay.add(Duration(days: i));

  /// Whole days since [fetched] at [now].
  int ageAt(DateTime now) => now.toUtc().difference(fetchedDay).inDays;

  /// Parses GitHub's `/stats/commit_activity` response: a list of weeks,
  /// each `{"week": <unix seconds of its Sunday>, "days": [7 counts]}`.
  /// Null when it isn't that shape.
  static CommitActivity? fromGithub(Object? json, DateTime now) {
    if (json is! List<Object?> || json.isEmpty) return null;
    final weeks = json.whereType<Json>().toList();
    if (weeks.length != json.length) return null;
    final first = asInt(weeks.first['week']);
    if (first == null) return null;
    final days = <int>[];
    for (final w in weeks) {
      final d = w['days'];
      if (d is! List<Object?> || d.length != 7) return null;
      days.addAll([for (final n in d) asInt(n) ?? 0]);
    }
    return CommitActivity(
      start: Snapshot.dayOf(DateTime.fromMillisecondsSinceEpoch(first * 1000, isUtc: true)),
      days: days,
      fetched: Snapshot.dayOf(now),
    );
  }

  factory CommitActivity.fromJson(Json json) => CommitActivity(
    start: json['start'] as String,
    days: asIntsOrNull(json['days']) ?? const [],
    fetched: json['fetched'] as String,
  );

  Json toJson() => {'start': start, 'days': days, 'fetched': fetched};
}
