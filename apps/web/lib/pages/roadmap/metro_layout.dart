import 'dart:math' as math;

/// A station position on the metro map.
class MetroStop {
  const MetroStop({
    required this.index,
    required this.x,
    required this.y,
    required this.row,
    required this.k,
    required this.rowLength,
  });

  /// Stage index.
  final int index;
  final double x, y;

  /// Which line (row) it's on, and its position along it.
  final int row, k, rowLength;
}

/// One metro line: a row of stops.
class MetroRow {
  const MetroRow({required this.index, required this.y, required this.leftToRight, required this.stops});

  final int index;
  final double y;
  final bool leftToRight;
  final List<MetroStop> stops;
}

/// The metro map's geometry, ported from the design. Stages split into 2–4
/// lines that snake left-to-right then right-to-left, joined by transfer
/// curves; below 860px wide it becomes a vertical list.
class MetroLayout {
  MetroLayout({required int stageCount, required this.width}) : vertical = width < 860 {
    final n = stageCount;
    final lines = n <= 8 ? 2 : (n <= 12 ? 3 : 4);
    final base = n ~/ lines, extra = n % lines;
    final groups = <List<int>>[];
    var idx = 0;
    for (var r = 0; r < lines; r++) {
      final m = base + (r < extra ? 1 : 0);
      groups.add([for (var k = 0; k < m; k++) idx + k]);
      idx += m;
    }

    if (!vertical) {
      const top = 170.0, gap = 225.0, x0 = 290.0, x1 = 970.0;
      viewWidth = 1200;
      viewHeight = top + (lines - 1) * gap + gap / 2 + jog / 2;
      rows = [
        for (final (r, ids) in groups.indexed) _horizontalRow(r, ids, top + r * gap, x0, x1),
      ];
    } else {
      viewWidth = width;
      var y = 96.0;
      rows = [];
      for (final (r, ids) in groups.indexed) {
        final y0 = y;
        final stops = <MetroStop>[];
        for (final (k, i) in ids.indexed) {
          stops.add(MetroStop(index: i, x: 40, y: y, row: r, k: k, rowLength: ids.length));
          y += 64;
        }
        y += 56;
        rows.add(MetroRow(index: r, y: y0, leftToRight: true, stops: stops));
      }
      viewHeight = y - 40;
    }
  }

  static const jog = 40.0;
  static const bandHeight = 225.0;

  final double width;
  final bool vertical;
  late final double viewWidth, viewHeight;
  late final List<MetroRow> rows;

  /// Horizontal layouts scale down to fit narrower containers.
  double get scale => vertical ? 1 : math.min(1, width / 1200);

  List<MetroStop> get stops => [for (final r in rows) ...r.stops];

  MetroStop stop(int stageIndex) => stops.firstWhere((s) => s.index == stageIndex);

  static MetroRow _horizontalRow(int r, List<int> ids, double y, double x0, double x1) {
    final ltr = r.isEven, m = ids.length, half = (m / 2).ceil();
    return MetroRow(
      index: r,
      y: y,
      leftToRight: ltr,
      stops: [
        for (final (k, i) in ids.indexed)
          () {
            final f = m > 1 ? k / (m - 1) : 0.5;
            return MetroStop(
              index: i,
              x: ltr ? x0 + f * (x1 - x0) : x1 - f * (x1 - x0),
              y: k >= half ? y + jog : y,
              row: r,
              k: k,
              rowLength: m,
            );
          }(),
      ],
    );
  }

  /// Vertices through [stops], inserting a 45° jog where the line steps down.
  static List<(double, double)> _vertices(List<MetroStop> stops, bool ltr) {
    final out = <(double, double)>[];
    for (final (k, p) in stops.indexed) {
      if (k > 0) {
        final q = stops[k - 1];
        if (q.y != p.y && q.x != p.x) {
          final mid = (q.x + p.x) / 2, d = ltr ? 1 : -1;
          out
            ..add((mid - d * jog / 2, q.y))
            ..add((mid + d * jog / 2, p.y));
        }
      }
      out.add((p.x, p.y));
    }
    return out;
  }

  /// A polyline with corners rounded to radius [radius].
  static String roundedPath(List<(double, double)> v, {double radius = 24}) {
    String r1(double x) {
      final s = ((x * 10).round() / 10).toString();
      return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    }

    final out = StringBuffer();
    for (var i = 0; i < v.length; i++) {
      final c = v[i];
      if (i == 0) {
        out.write('M${r1(c.$1)} ${r1(c.$2)}');
        continue;
      }
      if (i == v.length - 1) {
        out.write('L${r1(c.$1)} ${r1(c.$2)}');
        continue;
      }
      final a = v[i - 1], b = v[i + 1];
      final d1 = math.sqrt(math.pow(c.$1 - a.$1, 2) + math.pow(c.$2 - a.$2, 2));
      final d2 = math.sqrt(math.pow(b.$1 - c.$1, 2) + math.pow(b.$2 - c.$2, 2));
      if (d1 == 0 || d2 == 0) {
        out.write('L${r1(c.$1)} ${r1(c.$2)}');
        continue;
      }
      final rr = math.min(radius, math.min(d1 / 2, d2 / 2));
      final p1 = (c.$1 - (c.$1 - a.$1) / d1 * rr, c.$2 - (c.$2 - a.$2) / d1 * rr);
      final p2 = (c.$1 + (b.$1 - c.$1) / d2 * rr, c.$2 + (b.$2 - c.$2) / d2 * rr);
      out.write('L${r1(p1.$1)} ${r1(p1.$2)}Q${r1(c.$1)} ${r1(c.$2)} ${r1(p2.$1)} ${r1(p2.$2)}');
    }
    return out.toString();
  }

  /// The full track of a row.
  String linePath(MetroRow row) => roundedPath(_vertices(row.stops, row.leftToRight));

  /// The completed part of a row, up to and including stage [reach].
  String? donePath(MetroRow row, int reach) {
    final done = row.stops.where((s) => s.index <= reach).toList();
    return done.length > 1 ? roundedPath(_vertices(done, row.leftToRight)) : null;
  }

  /// Horizontal offset of the loop that carries a line down to the next.
  double _loopOffset(int row) => rows[row].leftToRight ? 70 : -56;

  /// Curves joining the end of each line to the start of the next.
  List<String> get transfers => [
    for (var j = 0; j < rows.length - 1; j++)
      () {
        final a = rows[j].stops.last, b = rows[j + 1].stops.first;
        if (vertical) return 'M${a.x} ${a.y}L${b.x} ${b.y}';
        final o = _loopOffset(j);
        return roundedPath([(a.x, a.y), (a.x + o, a.y), (a.x + o, b.y), (b.x, b.y)]);
      }(),
  ];

  /// Interchange stops (line ends that connect to another line).
  bool isInterchange(MetroStop s) => (s.k == 0 && s.row > 0) || (s.k == s.rowLength - 1 && s.row < rows.length - 1);

  /// The helicopter's heading in degrees at stage [reach].
  double heading(int reach) {
    final here = stop(reach);
    final prev = reach > 0 ? stop(reach - 1) : null;
    final next = stops.any((s) => s.index == reach + 1) ? stop(reach + 1) : null;
    final (from, to) = prev != null
        ? ((prev.x, prev.y), (here.x, here.y))
        : next != null
        ? ((here.x, here.y), (next.x, next.y))
        : ((here.x, here.y), (here.x + 1, here.y));
    return math.atan2(to.$2 - from.$2, to.$1 - from.$1) * 180 / math.pi;
  }
}
