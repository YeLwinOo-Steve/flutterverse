import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Writes the generated JSON files under [dir].
class JsonWriter {
  JsonWriter(this.dir);

  final String dir;

  void write(String relativePath, Object? json) {
    final file = File(p.join(dir, relativePath))..parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(json));
  }

  /// Deletes `*.json` files directly in [subdir] that aren't in [keep]
  /// (e.g. detail pages for projects removed from the seeds).
  void prune(String subdir, Set<String> keep) {
    final d = Directory(p.join(dir, subdir));
    if (!d.existsSync()) return;
    for (final f in d.listSync().whereType<File>()) {
      if (f.path.endsWith('.json') && !keep.contains(p.basename(f.path))) f.deleteSync();
    }
  }
}
