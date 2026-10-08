import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The design's 30-day sparkline path in an 88×28 viewBox, or null without
/// data.
String? sparkPath(List<int>? values) {
  if (values == null || values.length < 2) return null;
  final mx = math.max(1, values.reduce(math.max));
  final n = values.length - 1;
  return [
    for (final (i, v) in values.indexed)
      '${i == 0 ? 'M' : 'L'}${(i * 88 / n).toStringAsFixed(1)},${(26 - v / mx * 24).toStringAsFixed(1)}',
  ].join();
}

/// A stretched sparkline of daily star gains. Renders an empty box of the
/// same size when there's no history yet, so rows stay aligned.
class Sparkline extends StatelessComponent {
  const Sparkline(this.values, {this.width = 96, this.height = 36, this.area = false, this.fill = false, super.key});

  final List<int>? values;
  final int width;
  final int height;

  /// Shade the area under the line.
  final bool area;

  /// Stretch to the container's width instead of [width].
  final bool fill;

  @override
  Component build(BuildContext context) {
    final d = sparkPath(values);
    return svg(
      classes: 'spark',
      viewBox: '0 0 88 28',
      width: fill ? null : width.px,
      height: height.px,
      attributes: {
        'preserveAspectRatio': 'none',
        'aria-hidden': 'true',
        if (fill) 'style': 'width:100%',
      },
      [
        if (d != null && area) path(d: '${d}L88,28L0,28Z', classes: 'spark-area', []),
        if (d != null) path(d: d, classes: 'spark-line', []),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('svg.spark').styles(raw: {'display': 'block', 'flex-shrink': '0'}),
    css('.spark-line').styles(
      raw: {'fill': 'none', 'stroke': 'var(--accent)', 'stroke-width': '1.5', 'vector-effect': 'non-scaling-stroke'},
    ),
    css('.spark-area').styles(raw: {'fill': 'var(--accent)', 'opacity': '0.1'}),
  ];
}
