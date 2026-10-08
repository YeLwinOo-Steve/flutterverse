import 'dart:math' as math;

import 'package:fv_web/components/layout/lamp_rope.dart';
import 'package:test/test.dart';

void main() {
  test('a tug swings the bead and it settles back at rest', () {
    final rope = LampRope()..tug(math.Random(1));
    var frames = 0;
    while (!rope.step() && frames < 1000) {
      frames++;
    }
    expect(frames, inInclusiveRange(10, 999));
    expect((rope.x, rope.y), (LampRope.restX, LampRope.restY));
  });

  test('dragging follows the pointer but stays within reach', () {
    final rope = LampRope();
    for (var i = 0; i < 200; i++) {
      rope.step(target: (41, 500), dragging: true);
    }
    final reach = rope.y - 6 - LampRope.anchorY;
    expect(reach, closeTo(80, 0.5));
  });

  test('the cord path starts at the anchor and ends at the bead', () {
    final d = LampRope().path();
    expect(d, startsWith('M41.0,32.0 Q'));
    expect(d, endsWith('41.00,65.00'));
  });
}
