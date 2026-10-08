import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The Flutterverse mark: the Flutter logo inside an orbit with a sun.
/// [ink] colors the orbit; [dark] swaps to the footer's lighter blues.
class BrandMark extends StatelessComponent {
  const BrandMark({this.size = 26, this.ink = 'var(--ink)', this.dark = false, super.key});

  final int size;
  final String ink;
  final bool dark;

  @override
  Component build(BuildContext context) {
    final (a, b) = dark ? ('#54C5F8', '#1F8FE0') : ('#47C5FB', '#00569E');
    return RawText(
      '<svg width="$size" height="$size" viewBox="0 0 32 32" aria-hidden="true" '
      'style="display:block;flex-shrink:0;overflow:visible">'
      '<ellipse cx="16" cy="16.5" rx="15.5" ry="5.4" transform="rotate(-24 16 16.5)" '
      'style="fill:none;stroke:$ink;stroke-width:1.8;opacity:0.4"/>'
      '<g transform="translate(6.3 4.5) scale(0.0646)">'
      '<path d="M300 171.43H185.72L85.73 271.44l57.12 57.13z" style="fill:$a"/>'
      '<path d="M57.15 242.87L0 185.72 185.72 0H300z" style="fill:$a"/>'
      '<path d="M142.85 328.57L185.72 371.44H300L200.01 271.44z" style="fill:$b"/>'
      '<path d="M85.71 271.44L142.85 214.3 200 271.44 142.85 328.57z" style="fill:#00B5F8"/></g>'
      '<path d="M.5 16.5A15.5 5.4 0 0 0 31.5 16.5" transform="rotate(-24 16 16.5)" '
      'style="fill:none;stroke:$ink;stroke-width:1.8;stroke-linecap:round"/>'
      '<circle cx="28.4" cy="8.9" r="2.3" style="fill:#FFC83D"/></svg>',
    );
  }
}
