import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import '../ui/icons.dart';

int _tier(num value, List<num> steps) => steps.where((step) => value >= step).length;

/// Five growing stars, filled up to the star-count tier.
class StarPips extends StatelessComponent {
  const StarPips(this.stars, {super.key});

  final int? stars;

  static const _steps = [100, 1000, 5000, 10000, 25000];
  static const _labels = ['<100', '100+', '1k+', '5k+', '10k+', '25k+'];

  @override
  Component build(BuildContext context) {
    final n = _tier(stars ?? 0, _steps);
    return div(
      classes: 'pips',
      attributes: {'title': '${_labels[n]} stars'},
      [
        for (final (k, size) in [10.0, 11.5, 13.0, 14.5, 16.0].indexed)
          svg(
            width: size.px,
            height: size.px,
            viewBox: '0 0 16 16',
            classes: k < n ? 'pip-star on' : 'pip-star',
            [path(d: Icons.star, [])],
          ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.pips', {'display': 'flex', 'align-items': 'flex-end', 'gap': '2px', 'height': '16px'}),
    rule('.pip-star', {'display': 'block'}),
    rule('.pip-star path', {
      'fill': 'none',
      'stroke': 'var(--line)',
      'stroke-width': '1.4',
      'stroke-linejoin': 'round',
    }),
    rule('.pip-star.on path', {'fill': 'var(--accent)', 'stroke': 'none'}),
    rule('.pip-bar', {'width': '4px', 'border-radius': '1px', 'background': 'var(--line)'}),
    rule('.pip-bar.on', {'background': 'var(--accent)'}),
  ];
}

/// Five rising bars, filled up to the download tier.
class DownloadPips extends StatelessComponent {
  const DownloadPips(this.downloads, {required this.published, super.key});

  final int? downloads;
  final bool published;

  static const _steps = [1000, 10000, 100000, 500000, 1000000];
  static const _labels = ['<1k', '1k+', '10k+', '100k+', '500k+', '1M+'];

  @override
  Component build(BuildContext context) {
    final n = published ? _tier(downloads ?? 0, _steps) : 0;
    return div(
      classes: 'pips',
      attributes: {'title': published ? '${_labels[n]} downloads' : 'Not on pub.dev'},
      [
        for (final (k, h) in [4, 7, 10, 13, 16].indexed)
          span(
            classes: k < n ? 'pip-bar on' : 'pip-bar',
            styles: Styles(raw: {'height': '${h}px'}),
            [],
          ),
      ],
    );
  }
}

/// A 0–100 score as ten segments.
class MomentumMeter extends StatelessComponent {
  const MomentumMeter(this.score, {this.cellHeight = 8, this.gap = 2, this.radius = 1, super.key});

  final int? score;
  final int cellHeight;
  final int gap;
  final int radius;

  @override
  Component build(BuildContext context) {
    final filled = ((score ?? 0) / 10).round();
    return div(
      classes: 'meter',
      styles: Styles(raw: {'gap': '${gap}px'}),
      attributes: {'role': 'img', 'aria-label': 'Momentum ${score ?? notAvailable} of 100'},
      [
        for (var k = 0; k < 10; k++)
          span(
            classes: k < filled ? 'on' : null,
            styles: Styles(raw: {'height': '${cellHeight}px', 'border-radius': '${radius}px'}),
            [],
          ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.meter', {'flex': '1', 'display': 'grid', 'grid-template-columns': 'repeat(10,minmax(0,1fr))'}),
    rule('.meter > span', {'background': 'var(--surface2)'}),
    rule('.meter > span.on', {'background': 'var(--accent)'}),
    rule('.mono-num', {'font': mono(13)}),
  ];
}
