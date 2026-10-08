import 'package:fv_web/pages/roadmap/metro_layout.dart';
import 'package:test/test.dart';

void main() {
  test('splits stages into lines like the design', () {
    expect(MetroLayout(stageCount: 8, width: 1200).rows.map((r) => r.stops.length), [4, 4]);
    expect(MetroLayout(stageCount: 12, width: 1200).rows.length, 3);
    expect(MetroLayout(stageCount: 17, width: 1200).rows.map((r) => r.stops.length), [5, 4, 4, 4]);
  });

  test('lines alternate direction and step down halfway', () {
    final m = MetroLayout(stageCount: 16, width: 1200);
    final first = m.rows[0].stops, second = m.rows[1].stops;
    expect(first.first.x, 290);
    expect(first.last.x, 970);
    expect(second.first.x, 970, reason: 'the second line runs right to left');
    expect(first.first.y, 170);
    expect(first.last.y, 170 + MetroLayout.jog);
  });

  test('switches to a vertical list below 860px', () {
    final m = MetroLayout(stageCount: 6, width: 400);
    expect(m.vertical, isTrue);
    expect(m.scale, 1);
    expect(m.stops.map((s) => s.x).toSet(), {40});
  });

  test('scales horizontal maps to fit', () {
    expect(MetroLayout(stageCount: 6, width: 900).scale, closeTo(0.75, 0.001));
    expect(MetroLayout(stageCount: 6, width: 1400).scale, 1);
  });

  test('rounds corners and keeps endpoints', () {
    final d = MetroLayout.roundedPath([(0, 0), (100, 0), (100, 100)]);
    expect(d, startsWith('M0 0'));
    expect(d, contains('Q100 0'));
    expect(d, endsWith('L100 100'));
  });

  test('marks interchanges and heads along the line', () {
    final m = MetroLayout(stageCount: 8, width: 1200);
    expect(m.isInterchange(m.stop(3)), isTrue);
    expect(m.isInterchange(m.stop(4)), isTrue);
    expect(m.isInterchange(m.stop(1)), isFalse);
    expect(m.heading(0), 0, reason: 'heading toward the next stop on a left-to-right line');
  });
}
