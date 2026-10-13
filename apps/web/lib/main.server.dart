/// The entrypoint for the **server** environment, which only runs at build
/// time to pre-render every route.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'components/layout/nav_menu.dart';
import 'data/site_data.dart';
import 'main.server.options.dart';
import 'styles/shared.dart';
import 'styles/theme.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  // `deploy-web.yml` places the data branch's JSON here; locally fv_ingest
  // writes here by default.
  final data = SiteData.load('web/data');

  runApp(
    Document(
      title: 'Flutterverse',
      lang: 'en',
      meta: {
        'description': "Discover what's trending, what's growing, and what people are building with Flutter.",
        'theme-color': '#042B59',
      },
      head: [
        script(content: themeBootScript),
        script(content: navBootScript),
        link(rel: 'preconnect', href: 'https://fonts.googleapis.com'),
        link(rel: 'icon', href: '/favicon.svg', type: 'image/svg+xml'),
        // Google's search results need a raster icon at a multiple of 48px.
        link(rel: 'icon', href: '/favicon-192.png', type: 'image/png', attributes: {'sizes': '192x192'}),
        link(rel: 'icon', href: '/favicon.ico', attributes: {'sizes': '48x48'}),
        link(rel: 'apple-touch-icon', href: '/apple-touch-icon.png'),
      ],
      styles: [...globalStyles, ...sharedStyles],
      body: App(data),
    ),
  );
}
