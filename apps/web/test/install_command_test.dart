import 'package:fv_core/fv_core.dart';
import 'package:fv_web/pages/detail/source_panels.dart';
import 'package:test/test.dart';

void main() {
  test('installCommand uses flutter pub add, or dart pub add for pure Dart packages', () {
    expect(installCommand(const ProjectRow(id: 'a', name: 'Dio', pub: 'dio', sdk: 'Flutter')), 'flutter pub add dio');
    expect(installCommand(const ProjectRow(id: 'b', name: 'http', pub: 'http', sdk: 'Dart')), 'dart pub add http');
    expect(
      installCommand(const ProjectRow(id: 'c', name: 'x', pub: 'x')),
      'flutter pub add x',
      reason: 'unknown SDK',
    );
  });
}
