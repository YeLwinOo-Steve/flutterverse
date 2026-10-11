import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';

/// Every repo's [CommitActivity] in one JSON file, keyed by the lowercased
/// `owner/name`. It carries activity over between runs, since each run only
/// refreshes some of the repos.
class ActivityStore {
  ActivityStore(this.path);

  final String path;

  Map<String, CommitActivity> read() {
    final file = File(path);
    if (!file.existsSync()) return {};
    final json = jsonDecode(file.readAsStringSync()) as Json;
    return {for (final e in json.entries) e.key: CommitActivity.fromJson(e.value as Json)};
  }

  void write(Map<String, CommitActivity> activity) {
    final sorted = activity.keys.toList()..sort();
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({for (final k in sorted) k: activity[k]!.toJson()}));
  }
}
