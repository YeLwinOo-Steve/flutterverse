import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';

/// All generated data, read from disk once at build time (server only).
///
/// Every file is optional so the site still builds before the first ingest.
class SiteData {
  const SiteData({
    this.meta,
    this.index = const IndexFile(categories: {}, projects: []),
    this.details = const {},
    this.hallOfFame = const HallOfFameFile(),
    this.roadmap = const RoadmapFile(tracks: {}),
    this.discontinued = const DiscontinuedFile(),
  });

  final Meta? meta;
  final IndexFile index;
  final Map<String, ProjectDetail> details;
  final HallOfFameFile hallOfFame;
  final RoadmapFile roadmap;
  final DiscontinuedFile discontinued;

  /// The Doctor verdict for a published [row], or null for an unpublished one.
  VerdictResult? verdict(ProjectRow row) {
    final name = row.pub;
    if (name == null) return null;
    return verdictOf(row, now: now, discontinued: discontinued.contains(name), replacedBy: discontinued.packages[name]);
  }

  /// The reference time for relative dates, so builds are reproducible.
  DateTime get now => meta?.generatedAt ?? DateTime.now().toUtc();

  ProjectRow? row(String id) => _byId[id];

  Map<String, ProjectRow> get _byId => {for (final r in index.projects) r.id: r};

  static SiteData load(String dir) {
    T? read<T>(String rel, T Function(Map<String, Object?>) parse) {
      final f = File('$dir/$rel');
      if (!f.existsSync()) return null;
      return parse(jsonDecode(f.readAsStringSync()) as Map<String, Object?>);
    }

    final meta = read('meta.json', Meta.fromJson);
    if (meta != null && meta.schema != schemaVersion) {
      stderr.writeln('WARN: data schema ${meta.schema} != site schema $schemaVersion; ignoring data');
      return const SiteData();
    }
    final index = read('index.json', IndexFile.fromJson);
    return SiteData(
      meta: meta,
      index: index ?? const IndexFile(categories: {}, projects: []),
      details: {
        for (final row in index?.projects ?? const <ProjectRow>[])
          row.id: ?read('p/${row.id}.json', ProjectDetail.fromJson),
      },
      hallOfFame: read('hof.json', HallOfFameFile.fromJson) ?? const HallOfFameFile(),
      roadmap: read('roadmap.json', RoadmapFile.fromJson) ?? const RoadmapFile(tracks: {}),
      discontinued: read('discontinued.json', DiscontinuedFile.fromJson) ?? const DiscontinuedFile(),
    );
  }
}
