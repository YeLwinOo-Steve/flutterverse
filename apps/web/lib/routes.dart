import 'package:fv_core/fv_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'app.dart';
import 'components/layout/seo.dart';
import 'data/full_index.dart';
import 'data/site_data.dart';
import 'pages/about/about_page.dart';
import 'pages/detail/detail_page.dart';
import 'pages/explore/category_page.dart';
import 'pages/explore/explore_view.dart';
import 'pages/hof/hof_page.dart';
import 'pages/home/home_page.dart';
import 'pages/projects/projects_view.dart';
import 'pages/pub/pub_view.dart';
import 'pages/rankings/rankings_view.dart';
import 'pages/roadmap/roadmap_view.dart';

String _title(String page) => '$page · $siteName';

/// A pre-rendered route with its search metadata. A [noindex] page should
/// also match `--sitemap-exclude` in `deploy-web.yml`.
Route _page(
  String path, {
  required String title,
  required String description,
  required Component Function() builder,
  List<Map<String, Object?>> jsonLd = const [],
  RouteSettings? settings,
  bool noindex = false,
}) => Route(
  path: path,
  title: title,
  settings: noindex ? null : settings ?? const RouteSettings(changeFreq: ChangeFreq.daily),
  builder: (_, _) => Component.fragment([
    Seo(title: title, description: description, path: path, jsonLd: jsonLd, noindex: noindex),
    builder(),
  ]),
);

/// Every pre-rendered route. Static generation can't use path params, so
/// detail and category pages get one route each.
List<RouteBase> siteRoutes(SiteData data) {
  final index = data.index;
  final now = data.now.toIso8601String();
  final edition = data.hallOfFame.edition;
  final count = index.projects.length;
  return [
    _page(
      '/',
      title: '$siteName: Flutter & Dart package rankings and trends',
      description:
          'Daily rankings of $count Flutter and Dart packages, apps and tools by GitHub stars, '
          'pub.dev likes, downloads and momentum. See what is trending in Flutter.',
      jsonLd: [
        {
          '@type': 'WebSite',
          'name': siteName,
          'alternateName': ['Flutter Verse', 'flutterverse'],
          'url': '$siteUrl/',
          'description': 'Daily rankings and trends for Flutter and Dart packages and projects.',
        },
      ],
      builder: () => HomePage(data),
    ),
    _page(
      '/rankings',
      title: _title('Flutter package rankings by stars and momentum'),
      description:
          'The top Flutter and Dart packages and projects, ranked by GitHub stars, star growth, '
          'momentum, pub.dev likes and downloads. Refreshed every day.',
      builder: () => RankingsView(index: previewOf(index, RankingsView.previewRows(index))),
    ),
    _page(
      '/projects',
      title: _title('All Flutter & Dart projects and packages'),
      description:
          'Browse $count Flutter and Dart packages, open source apps and tools. Filter by category, '
          'SDK and platform, and sort by stars, pub points or momentum.',
      builder: () => ProjectsView(
        index: previewOf(index, ProjectsView.previewRows(index, data.now)),
        total: index.projects.length,
        now: now,
      ),
    ),
    _page(
      '/pub',
      title: _title('pub.dev packages: likes, points and downloads'),
      description:
          'Likes, pub points and downloads for every tracked Dart and Flutter package on pub.dev, '
          'including every Flutter Favorite.',
      builder: () => PubView(
        index: previewOf(index, PubView.previewRows(index, data.now)),
        total: index.projects.where((r) => r.isPublished).length,
        now: now,
      ),
    ),
    _page(
      '/hall-of-fame',
      title: _title('Flutter Hall of Fame${edition == null ? '' : ' ${edition.year}'}'),
      description:
          'The Flutterverse Hall of Fame: standout Flutter and Dart developers and open source '
          'projects, curated every year by the community.',
      jsonLd: [
        breadcrumbs([('Flutterverse', '/'), ('Hall of Fame', '/hall-of-fame')]),
      ],
      builder: () => HofPage(data),
    ),
    _page(
      '/roadmap',
      title: _title('Flutter & Dart learning roadmap'),
      description:
          'A step-by-step roadmap for learning Dart and Flutter, from the language basics to '
          'state management, testing and shipping, with the packages to learn at each stop.',
      builder: () => data.roadmap.tracks.isEmpty
          ? const Component.text('The roadmap is not available yet.')
          : RoadmapView(roadmap: data.roadmap, knownProjects: [for (final r in index.projects) r.id]),
    ),
    _page(
      '/about',
      title: _title('About: how Flutter packages are measured'),
      description:
          'How Flutterverse collects GitHub and pub.dev data every day and scores Flutter and Dart '
          'packages for momentum and maintenance.',
      settings: const RouteSettings(changeFreq: ChangeFreq.monthly),
      builder: () => const AboutPage(),
    ),
    _page(
      '/categories',
      title: _title('Flutter packages by category'),
      description:
          'Find the best Flutter and Dart packages for state management, navigation, networking, '
          'databases, UI, animation, testing and more.',
      builder: () => ExploreView.summarize(index),
    ),
    for (final MapEntry(key: slug, value: label) in index.categories.entries)
      _category(data, slug, label),
    for (final MapEntry(key: id, value: detail) in data.details.entries)
      _detail(data, id, detail),
    _page(
      '/404.html',
      title: _title('Page not found'),
      description: 'That page doesn’t exist, or it moved.',
      noindex: true,
      builder: () => const NotFound(),
    ),
  ];
}

Route _category(SiteData data, String slug, String label) {
  final path = '/categories/$slug';
  final rows = [
    for (final r in data.index.projects)
      if (r.categories.contains(slug)) r,
  ]..sort((a, b) => (b.stars ?? 0).compareTo(a.stars ?? 0));
  final topic = switch (slug) {
    'open-source-app' => 'open source Flutter apps',
    'games' => 'Flutter game engines and packages',
    _ => 'Flutter ${_lowerLabel(label)} packages',
  };
  final top = rows.take(3).map((r) => r.name).join(', ');
  return _page(
    path,
    title: _title('Best $topic'),
    description:
        'Compare the best $topic by GitHub stars, pub.dev likes, downloads and momentum'
        '${top.isEmpty ? '.' : ': $top and more.'}',
    jsonLd: [
      breadcrumbs([('Flutterverse', '/'), ('Categories', '/categories'), (label, path)]),
      {
        '@type': 'ItemList',
        'name': 'Best $topic',
        'itemListElement': [
          for (final (i, r) in rows.take(20).indexed)
            {'@type': 'ListItem', 'position': i + 1, 'name': r.name, 'url': pageUrl('/p/${r.id}')},
        ],
      },
    ],
    builder: () => CategoryPage(data: data, slug: slug),
  );
}

Route _detail(SiteData data, String id, ProjectDetail detail) {
  final r = detail.row;
  final path = '/p/$id';
  final sdk = r.sdk ?? 'Flutter';
  final what = r.kind == ProjectKind.package ? '$sdk package' : '$sdk project';
  final facts = [
    if (r.stars case final s?) '${compactNumber(s)} GitHub stars',
    if (r.likes case final l?) '${compactNumber(l)} pub.dev likes',
    if (r.downloads case final d?) '${compactNumber(d)} downloads',
  ];
  return _page(
    path,
    title: _title('${r.name}: $what stats and trends'),
    // Numbers first: the description is clipped to 160 characters.
    description: [
      '${r.name}, a $what${facts.isEmpty ? '' : ': ${facts.join(', ')}'}.',
      ?r.description,
      'Star history, momentum and maintenance, updated daily.',
    ].join(' '),
    settings: RouteSettings(changeFreq: ChangeFreq.daily, lastMod: data.now),
    jsonLd: [
      breadcrumbs([
        ('Flutterverse', '/'),
        if (r.categories.firstOrNull case final c?) (data.index.categories[c] ?? c, '/categories/$c'),
        (r.name, path),
      ]),
      {
        '@type': 'SoftwareSourceCode',
        'name': r.name,
        'description': ?r.description,
        'url': pageUrl(path),
        'programmingLanguage': 'Dart',
        'runtimePlatform': sdk,
        'codeRepository': ?(r.repo == null ? null : 'https://github.com/${r.repo}'),
        'version': ?r.version,
        'sameAs': [
          if (r.pub case final p?) 'https://pub.dev/packages/$p',
          if (r.repo case final repo?) 'https://github.com/$repo',
        ],
      },
    ],
    builder: () => DetailPage(
      detail: detail,
      related: [for (final rel in detail.related) ?data.row(rel)],
      categories: data.index.categories,
      now: data.now,
    ),
  );
}

/// "State management" → "state management"; acronyms such as "UI" stay.
String _lowerLabel(String label) =>
    label.split(' ').map((w) => w == w.toUpperCase() ? w : w.toLowerCase()).join(' ');
