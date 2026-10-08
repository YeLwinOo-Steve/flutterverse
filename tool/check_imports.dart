// Enforces the dependency rules in PLAN.md §3:
//   fv_core   → nothing in the repo, no dart:io (it must compile to the web)
//   fv_ingest → fv_core only
//   web       → fv_core only (never fv_ingest or the server)
//
// Run from the repo root: dart run tool/check_imports.dart
import 'dart:io';

const rules = {
  'packages/fv_core/lib': ['dart:io', 'dart:html', 'package:fv_ingest/', 'package:fv_web/', 'package:flutterverse_'],
  'packages/fv_ingest/lib': ['package:fv_web/', 'package:flutterverse_'],
  'packages/fv_ingest/bin': ['package:fv_web/', 'package:flutterverse_'],
  'apps/web/lib': ['package:fv_ingest/', 'package:flutterverse_server/'],
};

final _import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

void main() {
  final violations = <String>[];
  for (final MapEntry(key: dir, value: forbidden) in rules.entries) {
    final d = Directory(dir);
    if (!d.existsSync()) continue;
    for (final file in d.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in _import.allMatches(file.readAsStringSync())) {
        final uri = m[1]!;
        if (forbidden.any(uri.startsWith)) violations.add('${file.path}: imports $uri');
      }
    }
  }
  if (violations.isEmpty) {
    stdout.writeln('Import rules OK');
  } else {
    stderr.writeln('Forbidden imports:\n${violations.map((v) => '  - $v').join('\n')}');
    exitCode = 1;
  }
}
