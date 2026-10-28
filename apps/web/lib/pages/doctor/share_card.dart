import 'package:fv_core/fv_core.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'doctor_data.dart';

/// The share card's size: the same as `og.png`, so it previews well where
/// people post it.
const _w = 1200, _h = 630, _pad = 64;

/// The card always uses the dark palette: it's an image, not a themed page.
const _bg = '#042B59', _ink = '#E8F4FF', _muted = '#9AB3CF', _accent = '#54C5F8', _line = '#1C3B5E';

String _color(DoctorStatus s) => switch (s) {
  DoctorStatus.replaceNow => '#FF8A7A',
  DoctorStatus.atRisk => '#F2B84B',
  DoctorStatus.watch => _muted,
  DoctorStatus.healthy => _accent,
  DoctorStatus.stable => '#5FE0CF',
  _ => '#3A5A7E',
};

/// Draws the report's score and counts, and downloads it as a PNG. Only
/// counts and the pubspec's name are drawn, never the package names.
void downloadShareCard(DoctorReport report, {required String dataDate}) {
  final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement
    ..width = _w
    ..height = _h;
  final c = canvas.getContext('2d') as web.CanvasRenderingContext2D;

  void text(String s, num x, num y, {required String font, String color = _ink, String align = 'left'}) {
    c
      ..font = font
      ..fillStyle = color.toJS
      ..textAlign = align
      ..fillText(s, x, y);
  }

  c
    ..fillStyle = _bg.toJS
    ..fillRect(0, 0, _w, _h)
    ..strokeStyle = _line.toJS
    ..lineWidth = 2
    ..strokeRect(24, 24, _w - 48, _h - 48);

  text('PUBSPEC DOCTOR', _pad, 108, font: "500 22px 'Geist Mono',monospace", color: _accent);
  text(
    _fit(c, report.project ?? 'My project', "600 52px 'Geist',sans-serif", 640),
    _pad,
    172,
    font: "600 52px 'Geist',sans-serif",
  );

  final score = report.score;
  text(score == null ? notAvailable : '$score%', _pad - 6, 400, font: "600 200px 'Geist',sans-serif");
  text('of direct dependencies are', _pad, 450, font: "400 26px 'Geist',sans-serif", color: _muted);
  text('Healthy or Stable', _pad, 486, font: "400 26px 'Geist',sans-serif", color: _muted);

  // One row per status on the right.
  final counts = statusCounts(report);
  const left = 780, right = _w - _pad;
  for (final (i, (s, n)) in counts.indexed) {
    final y = 140 + i * 50;
    c
      ..fillStyle = _color(s).toJS
      ..beginPath()
      ..arc(left + 8, y - 9, 8, 0, 6.2832)
      ..fill();
    text(s.label, left + 30, y, font: "500 26px 'Geist',sans-serif");
    text('$n', right, y, font: "600 26px 'Geist Mono',monospace", align: 'right');
  }

  // The same split as a bar.
  final total = counts.fold<int>(0, (sum, e) => sum + e.$2);
  var x = _pad.toDouble();
  const barW = _w - 2 * _pad, gap = 4;
  for (final (s, n) in counts) {
    final w = (barW - gap * (counts.length - 1)) * n / total;
    c
      ..fillStyle = _color(s).toJS
      ..fillRect(x, 520, w, 14);
    x += w + gap;
  }

  text('flutterverse.org/doctor', _pad, 584, font: "500 22px 'Geist Mono',monospace", color: _accent);
  text('Data from $dataDate', right, 584, font: "400 20px 'Geist',sans-serif", color: _muted, align: 'right');

  web.HTMLAnchorElement()
    ..href = canvas.toDataURL('image/png')
    ..download = '${report.project ?? 'pubspec'}-doctor.png'
    ..click();
}

/// [s], cut with an ellipsis to fit [maxWidth] pixels in [font].
String _fit(web.CanvasRenderingContext2D c, String s, String font, num maxWidth) {
  c.font = font;
  if (c.measureText(s).width <= maxWidth) return s;
  var out = s;
  while (out.isNotEmpty && c.measureText('$out…').width > maxWidth) {
    out = out.substring(0, out.length - 1);
  }
  return '$out…';
}
