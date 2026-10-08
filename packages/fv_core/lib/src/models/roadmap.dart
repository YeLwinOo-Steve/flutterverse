import '../json.dart';

/// A learning track (`Flutter`, `Dart`) made of ordered stages ("stops").
class RoadmapTrack {
  const RoadmapTrack({required this.name, required this.intro, required this.stages});

  final String name;
  final String intro;
  final List<RoadmapStage> stages;

  factory RoadmapTrack.fromJson(Json json) => RoadmapTrack(
    name: json['name'] as String,
    intro: json['intro'] as String,
    stages: asList(json['stages'], RoadmapStage.fromJson),
  );

  Json toJson() => {
    'name': name,
    'intro': intro,
    'stages': [for (final s in stages) s.toJson()],
  };
}

class RoadmapStage {
  const RoadmapStage({
    required this.title,
    required this.time,
    required this.blurb,
    required this.build,
    required this.topics,
  });

  final String title;

  /// Rough effort, e.g. `1 week`.
  final String time;
  final String blurb;

  /// The milestone project to build at this stop.
  final String build;
  final List<RoadmapTopic> topics;

  factory RoadmapStage.fromJson(Json json) => RoadmapStage(
    title: json['title'] as String,
    time: json['time'] as String,
    blurb: json['blurb'] as String,
    build: json['build'] as String,
    topics: asList(json['topics'], RoadmapTopic.fromJson),
  );

  Json toJson() => {
    'title': title,
    'time': time,
    'blurb': blurb,
    'build': build,
    'topics': [for (final t in topics) t.toJson()],
  };
}

class RoadmapTopic {
  const RoadmapTopic({
    required this.title,
    this.description,
    this.concepts = const [],
    this.resources = const [],
    this.project,
    this.optional = false,
  });

  final String title;
  final String? description;

  /// Key concepts, shown as a small tree.
  final List<String> concepts;

  /// `(label, url)` learning resources.
  final List<(String, String)> resources;

  /// A related [Project.id] to link to.
  final String? project;
  final bool optional;

  factory RoadmapTopic.fromJson(Json json) => RoadmapTopic(
    title: json['t'] as String,
    description: json['d'] as String?,
    concepts: asStrings(json['sub']),
    resources: [
      for (final r in (json['res'] as List<Object?>? ?? const []).cast<List<Object?>>())
        (r[0] as String, r[1] as String),
    ],
    project: json['pkg'] as String?,
    optional: json['opt'] as bool? ?? false,
  );

  Json toJson() => compact({
    't': title,
    'd': description,
    'sub': concepts.isEmpty ? null : concepts,
    'res': resources.isEmpty
        ? null
        : [
            for (final (l, u) in resources) [l, u],
          ],
    'pkg': project,
    'opt': optional ? true : null,
  });
}
