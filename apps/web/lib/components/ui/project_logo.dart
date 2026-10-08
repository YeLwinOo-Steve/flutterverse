import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// A square project logo: the owner's avatar over a brand-colored tile with
/// initials, which show through if the avatar fails to load.
class ProjectLogo extends StatelessComponent {
  const ProjectLogo({
    required this.initials,
    required this.color,
    this.imageUrl,
    this.size = 40,
    this.ring,
    this.offset = false,
    super.key,
  });

  final String initials;
  final String color;
  final String? imageUrl;
  final int size;

  /// A border color to separate overlapping logos (Explore cards).
  final String? ring;

  /// Overlap the previous logo by 8px.
  final bool offset;

  @override
  Component build(BuildContext context) {
    final img = imageUrl;
    return div(
      classes: 'logo',
      attributes: {'aria-hidden': 'true'},
      styles: Styles(
        raw: {
          'width': '${size}px',
          'height': '${size}px',
          'background': img == null ? color : '$color url($img) center/cover no-repeat',
          'color': img == null ? '#FFFFFF' : 'transparent',
          'font': mono((size * 0.36).round(), weight: 600),
          if (img != null) 'box-shadow': 'inset 0 0 0 1px var(--line)',
          if (ring != null) 'border': '2px solid $ring',
          if (offset) 'margin-left': '-8px',
        },
      ),
      [.text(initials)],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.logo', {
      'border-radius': '2px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'flex-shrink': '0',
      'overflow': 'hidden',
    }),
  ];
}
