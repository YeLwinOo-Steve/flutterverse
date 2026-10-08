import '../models/output.dart';
import '../models/pub_stats.dart';
import '../models/snapshot.dart';

/// Where a timeline event's date comes from.
enum EventSource {
  /// Reported by pub.dev or GitHub.
  source,

  /// Derived by Flutterverse, e.g. a star milestone from snapshots.
  calculated,
}

class TimelineEvent {
  const TimelineEvent(this.date, this.label, this.source);

  final DateTime date;
  final String label;
  final EventSource source;
}

const _milestones = [500, 1000, 2500, 5000, 10000, 20000, 50000];

/// Notable dates for a project, oldest first: creation, major releases, star
/// milestones crossed while tracked, and the latest release.
List<TimelineEvent> timelineOf(ProjectDetail d) {
  final events = <TimelineEvent>[];
  final created = d.gh?.createdAt ?? d.pub?.firstPublished;
  if (created != null) {
    events.add(TimelineEvent(created, d.gh?.createdAt != null ? 'Repository created' : 'First published', .source));
  }
  for (final r in d.pub?.majors ?? const <Release>[]) {
    events.add(TimelineEvent(r.date, 'v${r.version} released', .source));
  }
  Snapshot? prev;
  for (final s in d.history) {
    if (s.stars == null) continue;
    for (final m in _milestones) {
      if (prev != null && prev.stars! < m && s.stars! >= m) {
        events.add(TimelineEvent(s.day, '${_k(m)} GitHub stars', .calculated));
      }
    }
    prev = s;
  }
  if (d.pub?.published case final latest?) {
    events.add(TimelineEvent(latest, 'Latest release v${d.pub!.version}', .source));
  }
  return events..sort((a, b) => a.date.compareTo(b.date));
}

String _k(int n) => n >= 1000 ? '${n % 1000 == 0 ? n ~/ 1000 : (n / 1000).toStringAsFixed(1)}k' : '$n';
