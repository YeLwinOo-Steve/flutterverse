import 'package:fv_core/fv_core.dart';

/// Learning progress for one track: which topics are learned, keyed
/// `track:stage:topic` like the design (stored in localStorage).
class TrackProgress {
  TrackProgress(this.trackId, this.track, this.learned);

  final String trackId;
  final RoadmapTrack track;

  /// Every learned key, across all tracks.
  final Set<String> learned;

  String key(int stage, RoadmapTopic topic) => '$trackId:$stage:${topic.title}';

  bool isLearned(int stage, RoadmapTopic topic) => learned.contains(key(stage, topic));

  /// A stop is done when its required topics are learned (or all topics,
  /// if every topic is optional).
  bool isDone(int stage) {
    final topics = track.stages[stage].topics;
    final required = topics.where((t) => !t.optional);
    return (required.isEmpty ? topics : required).every((t) => isLearned(stage, t));
  }

  int learnedIn(int stage) => track.stages[stage].topics.where((t) => isLearned(stage, t)).length;

  /// The first unfinished stop, or -1 when the track is complete.
  int get current {
    for (var i = 0; i < track.stages.length; i++) {
      if (!isDone(i)) return i;
    }
    return -1;
  }

  /// Where the helicopter sits: the current stop, or the last one.
  int get reach => current < 0 ? track.stages.length - 1 : current;

  int get total => track.stages.fold(0, (sum, s) => sum + s.topics.length);

  int get learnedCount => [
    for (final (i, s) in track.stages.indexed)
      for (final t in s.topics)
        if (isLearned(i, t)) t,
  ].length;

  /// Keys to set (or clear) to mark a whole stop learned.
  Iterable<String> stageKeys(int stage) => [for (final t in track.stages[stage].topics) key(stage, t)];
}
