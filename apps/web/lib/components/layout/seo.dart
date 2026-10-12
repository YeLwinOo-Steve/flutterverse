import 'dart:convert';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Where the site is served. Canonical links, share cards and structured data
/// are built from it; `web/robots.txt` and `deploy-web.yml`'s
/// `--sitemap-domain` name it too (a test keeps the three in step).
const siteUrl = 'https://flutterverse.org';

const siteName = 'Flutterverse';

/// A page's search and share metadata: description, canonical URL, Open Graph
/// and Twitter cards, and optional JSON-LD. The `<title>` comes from the
/// route, so pass the same [title] here for the share cards.
class Seo extends StatelessComponent {
  const Seo({
    required this.title,
    required this.description,
    required this.path,
    this.jsonLd = const [],
    this.noindex = false,
    super.key,
  });

  final String title;
  final String description;

  /// The page's path, such as `/rankings`.
  final String path;

  /// Schema.org objects, each rendered as its own `ld+json` script.
  final List<Map<String, Object?>> jsonLd;
  final bool noindex;

  @override
  Component build(BuildContext context) {
    final url = pageUrl(path);
    final desc = clip(description, 160);
    return Document.head(
      meta: {
        'description': desc,
        'robots': noindex ? 'noindex' : 'index, follow, max-image-preview:large',
        'twitter:card': 'summary_large_image',
        'twitter:title': title,
        'twitter:description': desc,
        'twitter:image': '$siteUrl/og.png',
      },
      children: [
        link(rel: 'canonical', href: url),
        for (final (property, content) in [
          ('og:type', 'website'),
          ('og:site_name', siteName),
          ('og:locale', 'en_US'),
          ('og:title', title),
          ('og:description', desc),
          ('og:url', url),
          ('og:image', '$siteUrl/og.png'),
          ('og:image:width', '1200'),
          ('og:image:height', '630'),
          ('og:image:alt', 'Flutterverse: Flutter and Dart package rankings and trends'),
        ])
          meta(attributes: {'property': property, 'content': content}),
        for (final data in jsonLd)
          script(attributes: {'type': 'application/ld+json'}, content: ldJson(data)),
      ],
    );
  }
}

/// The absolute URL of [path] on [siteUrl], with the trailing slash Cloudflare
/// Pages serves pages at (`/rankings` redirects to `/rankings/`), so canonical
/// links never point at a redirect.
String pageUrl(String path) => path.endsWith('/') ? '$siteUrl$path' : '$siteUrl$path/';

/// JSON for an inline `<script>`: `</` is escaped so the data can't end it.
String ldJson(Map<String, Object?> data) => jsonEncode({'@context': 'https://schema.org', ...data}).replaceAll('</', r'<\/');

/// [text] cut at a word boundary to at most [max] characters.
String clip(String text, int max) {
  final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.length <= max) return t;
  final cut = t.substring(0, max - 1);
  final space = cut.lastIndexOf(' ');
  return '${(space > max ~/ 2 ? cut.substring(0, space) : cut).replaceAll(RegExp(r'[\s,.;:–-]+$'), '')}…';
}

/// A BreadcrumbList for [crumbs], each a (name, path) pair.
Map<String, Object?> breadcrumbs(List<(String, String)> crumbs) => {
  '@type': 'BreadcrumbList',
  'itemListElement': [
    for (final (i, (name, path)) in crumbs.indexed)
      {'@type': 'ListItem', 'position': i + 1, 'name': name, 'item': pageUrl(path)},
  ],
};
