import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:yaml/yaml.dart';

/// Parses `config/seeds.yaml` and, optionally, `config/roadmap.json`.
/// Throws [FormatException] on malformed input; use [validateCatalog] for
/// semantic checks.
Catalog parseSeeds(String source, {String? roadmapJson}) {
  final doc = loadYaml(source);
  if (doc is! YamlMap) throw const FormatException('seeds.yaml must be a map');
  final json = _plain(doc) as Map<String, Object?>;

  final hof = json['hall_of_fame'] as Map<String, Object?>?;
  return Catalog(
    categories: (json['categories'] as Map<String, Object?>? ?? {}).cast<String, String>(),
    categoryGroups: {
      for (final e in (json['category_groups'] as Map<String, Object?>? ?? {}).entries)
        e.key: (e.value as List<Object?>).cast<String>(),
    },
    projects: [
      for (final p in (json['projects'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
        Project.fromJson(p),
    ],
    hallOfFame: hof == null ? null : HallOfFameEdition.fromJson(hof),
    discovery: Discovery.fromJson(json['discovery'] as Map<String, Object?>? ?? const {}),
    topicCategories: {
      for (final e in (json['topic_categories'] as Map<String, Object?>? ?? {}).entries)
        e.key: [for (final t in (e.value as List<Object?>).cast<String>()) t.toLowerCase()],
    },
    roadmap: roadmapJson == null ? const {} : RoadmapFile.fromJson(jsonDecode(roadmapJson) as Json).tracks,
  );
}

/// Where discovered projects that match no topic go.
const otherCategory = 'other';

final _idPattern = RegExp(r'^[a-z0-9][a-z0-9_-]*$');
final _repoPattern = RegExp(r'^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$');
const _sdks = {'Dart', 'Flutter'};
const _platforms = {'iOS', 'Android', 'Web', 'WASM', 'macOS', 'Windows', 'Linux'};

/// Offline consistency checks. Returns a list of problems (empty = valid).
List<String> validateCatalog(Catalog c) {
  final errors = <String>[];
  final ids = <String>{};
  for (final p in c.projects) {
    final where = 'project "${p.id}"';
    if (!_idPattern.hasMatch(p.id)) errors.add('$where: id must match ${_idPattern.pattern}');
    if (!ids.add(p.id)) errors.add('$where: duplicate id');
    if (p.pub == null && p.repo == null) errors.add('$where: needs `pub`, `repo` or both');
    if (p.repo != null && !_repoPattern.hasMatch(p.repo!)) errors.add('$where: repo must be "owner/name"');
    if (p.categories.isEmpty) errors.add('$where: needs at least one category');
    for (final cat in p.categories) {
      if (!c.categories.containsKey(cat)) errors.add('$where: unknown category "$cat"');
    }
    if (p.sdk != null && !_sdks.contains(p.sdk)) errors.add('$where: sdk must be Dart or Flutter');
    for (final pl in p.platforms ?? const <String>[]) {
      if (!_platforms.contains(pl)) errors.add('$where: unknown platform "$pl"');
    }
  }
  for (final p in c.projects) {
    for (final r in p.related) {
      if (!ids.contains(r)) errors.add('project "${p.id}": unknown related project "$r"');
    }
  }
  for (final MapEntry(key: group, value: cats) in c.categoryGroups.entries) {
    for (final cat in cats) {
      if (!c.categories.containsKey(cat)) errors.add('category_groups "$group": unknown category "$cat"');
    }
  }
  for (final cat in c.topicCategories.keys) {
    if (!c.categories.containsKey(cat)) errors.add('topic_categories: unknown category "$cat"');
  }
  if (c.discovery.enabled && !c.categories.containsKey(otherCategory)) {
    errors.add('categories: discovery needs an "$otherCategory" category for unmatched projects');
  }
  for (final h in c.hallOfFame?.projects ?? const <HallOfFameProject>[]) {
    if (!ids.contains(h.id)) errors.add('hall_of_fame: unknown project "${h.id}"');
  }
  for (final d in c.hallOfFame?.developers ?? const <HallOfFameDeveloper>[]) {
    for (final pid in d.projects) {
      if (!ids.contains(pid)) errors.add('hall_of_fame developer "${d.handle}": unknown project "$pid"');
    }
  }
  return errors;
}

Object? _plain(Object? node) => switch (node) {
  final YamlMap m => {for (final e in m.entries) e.key.toString(): _plain(e.value)},
  final YamlList l => [for (final e in l) _plain(e)],
  _ => node,
};
