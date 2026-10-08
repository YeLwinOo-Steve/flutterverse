import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A 16×16-viewBox icon drawn with one path, in `currentColor`.
class Icon extends StatelessComponent {
  const Icon(this.shape, {this.size = 16, this.strokeWidth = 1.5, this.filled = false, this.classes, super.key});

  final String shape;
  final double size;
  final double strokeWidth;

  /// Fill the path instead of stroking it (e.g. the GitHub mark).
  final bool filled;
  final String? classes;

  @override
  Component build(BuildContext context) {
    return svg(
      classes: ['icon', ?classes].join(' '),
      viewBox: '0 0 16 16',
      width: size.px,
      height: size.px,
      attributes: {'aria-hidden': 'true'},
      [
        path(
          d: shape,
          attributes: filled
              ? {'style': 'fill:currentColor'}
              : {
                  'style':
                      'fill:none;stroke:currentColor;stroke-width:$strokeWidth;stroke-linecap:round;stroke-linejoin:round',
                },
          [],
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('svg.icon').styles(raw: {'display': 'block', 'flex-shrink': '0'}),
  ];
}
