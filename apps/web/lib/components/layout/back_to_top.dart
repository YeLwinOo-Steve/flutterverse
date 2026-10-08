import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../ui/icon.dart';
import '../ui/icons.dart';

/// Smoothly scrolls to the top. A button rather than `href="#"`, because the
/// document's `<base href="/">` would turn that into a link to the home page.
@client
class BackToTop extends StatelessComponent {
  const BackToTop({super.key});

  @override
  Component build(BuildContext context) {
    return button(
      classes: 'to-top',
      type: ButtonType.button,
      onClick: () => web.window.scrollTo(web.ScrollToOptions(top: 0, behavior: 'smooth')),
      [.text('Back to top '), const Icon(Icons.arrowUp, size: 14, strokeWidth: 1.6)],
    );
  }
}
