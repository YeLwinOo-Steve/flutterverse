import 'dart:math' as math;

/// The lamp cord's spring physics, in lamp-local pixels. The bead hangs
/// from [anchorX],[anchorY] and springs back to rest after a tug or drag.
class LampRope {
  static const anchorX = 41.0, anchorY = 32.0, restX = 41.0, restY = 71.0, length = 33.0;

  double x = restX, y = restY, vx = 0, vy = 0;

  /// A quick downward tug with a random sideways swing.
  void tug(math.Random random) {
    vy += 7;
    vx += (random.nextBool() ? -1 : 1) * (2 + random.nextDouble() * 2);
  }

  /// Advances one frame toward [target] (or rest). Returns true once settled.
  bool step({(double, double)? target, bool dragging = false}) {
    final (tx, ty) = dragging && target != null ? target : (restX, restY);
    final k = dragging ? 0.35 : 0.09, damp = dragging ? 0.55 : 0.86;
    vx = (vx + (tx - x) * k) * damp;
    vy = (vy + (ty - y) * k) * damp;
    x += vx;
    y += vy;

    // Keep the bead within the cord's reach.
    final ex = x, ey = y - 6;
    final d = math.sqrt(math.pow(ex - anchorX, 2) + math.pow(ey - anchorY, 2));
    final maxLen = dragging ? 80.0 : 46.0;
    if (d > maxLen) {
      final r = maxLen / d;
      x = anchorX + (ex - anchorX) * r;
      y = anchorY + (ey - anchorY) * r + 6;
    }

    final settled = !dragging && vx.abs() < 0.02 && vy.abs() < 0.02 && (x - restX).abs() + (y - restY).abs() < 0.7;
    if (settled) {
      x = restX;
      y = restY;
      vx = vy = 0;
    }
    return settled;
  }

  /// The cord as a quadratic curve that sags sideways when slack.
  String path() {
    final ex = x, ey = y - 6;
    final dx = ex - anchorX, dy = ey - anchorY;
    final d = math.max(1e-6, math.sqrt(dx * dx + dy * dy));
    final slack = d < length ? math.sqrt(length * length - d * d) * 0.6 : 0.0;
    final side = vx >= 0 ? -1 : 1;
    final cx = (anchorX + ex) / 2 + (-dy / d) * slack * side;
    final cy = (anchorY + ey) / 2 + (dx / d) * slack * side + slack * 0.3;
    return 'M$anchorX,$anchorY Q${cx.toStringAsFixed(2)},${cy.toStringAsFixed(2)} '
        '${ex.toStringAsFixed(2)},${ey.toStringAsFixed(2)}';
  }
}
