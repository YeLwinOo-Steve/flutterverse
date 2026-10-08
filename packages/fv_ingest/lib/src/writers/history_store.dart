import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';
import 'package:path/path.dart' as p;

/// One `<id>.ndjson` file per project, one [Snapshot] per line, oldest first.
class HistoryStore {
  HistoryStore(this.dir);

  final String dir;

  File _file(String id) => File(p.join(dir, '$id.ndjson'));

  List<Snapshot> read(String id) {
    final file = _file(id);
    if (!file.existsSync()) return [];
    return [
      for (final line in file.readAsLinesSync())
        if (line.trim().isNotEmpty) Snapshot.fromJson(jsonDecode(line) as Map<String, Object?>),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Adds [snapshot], replacing any existing line for the same day so
  /// re-running the job on one day is idempotent. Returns the full history.
  List<Snapshot> upsert(String id, Snapshot snapshot) {
    final history = read(id)
      ..removeWhere((s) => s.date == snapshot.date)
      ..add(snapshot)
      ..sort((a, b) => a.date.compareTo(b.date));
    final file = _file(id)..parent.createSync(recursive: true);
    file.writeAsStringSync(history.map((s) => '${jsonEncode(s.toJson())}\n').join());
    return history;
  }
}
