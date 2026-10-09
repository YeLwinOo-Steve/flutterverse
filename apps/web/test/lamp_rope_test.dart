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

  test('a slack cord pushed straight up keeps bowing to one side', () {
    final rope = LampRope();
    final bows = <bool>{};
    for (var i = 0; i < 120; i++) {
      // Pointer jitter of half a pixel either side, as with a real mouse.
      rope.step(target: (LampRope.restX + (i.isEven ? 0.5 : -0.5), LampRope.restY - 10), dragging: true);
      if (i < 20) continue;
      // `M ax,ay Qcx,cy ex,ey`: which side of the chord the control point sits.
      final parts = rope.path().split(' ');
      final cx = double.parse(parts[1].substring(1).split(',')[0]);
      final ex = double.parse(parts[2].split(',')[0]);
      bows.add(cx > (LampRope.anchorX + ex) / 2);
    }
    expect(bows, hasLength(1));
  });
}
