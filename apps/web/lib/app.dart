import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/layout/command_palette.dart';
import 'components/layout/intro_splash.dart';
import 'components/layout/site_footer.dart';
import 'components/layout/site_header.dart';
import 'components/nominate/nominations.dart';
import 'data/site_data.dart';
import 'routes.dart';

/// The root component. With multi-page routing this only runs on the server
/// during pre-rendering; only `@client` components ship to the browser.
class App extends StatelessComponent {
  const App(this.data, {super.key});

  final SiteData data;

  @override
  Component build(BuildContext context) {
    final edition = data.hallOfFame.edition;
    return div([
      const IntroSplash(),
      const SiteHeader(),
      main_(classes: 'page', [Router(routes: siteRoutes(data), errorBuilder: (_, _) => const NotFound())]),
      SiteFooter(stats: _footerStats()),
      const CommandPalette(),
      Nominations(categories: [for (final p in edition?.projects ?? const <HallOfFameProject>[]) p.category]),
    ]);
  }

  List<FooterStat> _footerStats() {
    final rows = data.index.projects;
    return [
      (value: '${rows.where((r) => r.kind == ProjectKind.package).length}', label: 'packages tracked'),
      (value: '${rows.where((r) => r.kind == ProjectKind.project).length}', label: 'projects'),
      (value: '${data.hallOfFame.edition?.developers.length ?? 0}', label: 'Hall of Fame developers'),
      (value: compactNumber(rows.fold<int>(0, (sum, r) => sum + (r.stars ?? 0))), label: 'GitHub stars indexed'),
    ];
  }
}

class NotFound extends StatelessComponent {
  const NotFound({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'empty', [
      b([.text('Page not found')]),
      span([.text('That page doesn’t exist, or it moved.')]),
      a(href: '/', classes: 'btn small', [.text('Back home')]),
    ]);
  }
}
