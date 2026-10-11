/// Shared Flutterverse models, metrics and formatters.
///
/// This library must stay free of `dart:io` so it compiles for the web.
library;

export 'src/format.dart';
export 'src/json.dart' show Json, schemaVersion;
export 'src/metrics/maintenance.dart';
export 'src/metrics/momentum.dart';
export 'src/metrics/timeline.dart';
export 'src/models/activity.dart';
export 'src/models/catalog.dart';
export 'src/models/gh_stats.dart';
export 'src/models/output.dart';
export 'src/models/project.dart';
export 'src/models/pub_stats.dart';
export 'src/models/roadmap.dart';
export 'src/models/snapshot.dart';
