import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

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

String _title(String page) => '$page · Flutterverse';

/// Every pre-rendered route. Static generation can't use path params, so
/// detail and category pages get one route each.
List<RouteBase> siteRoutes(SiteData data) {
  final index = data.index;
  final now = data.now.toIso8601String();
  return [
    Route(path: '/', title: _title('Explore the Dart & Flutter ecosystem'), builder: (_, _) => HomePage(data)),
    Route(
      path: '/rankings',
      title: _title('Rankings'),
      builder: (_, _) => RankingsView(index: index),
    ),
    Route(
      path: '/projects',
      title: _title('Projects'),
      builder: (_, _) => ProjectsView(index: index, now: now),
    ),
    Route(
      path: '/pub',
      title: _title('pub.dev packages'),
      builder: (_, _) => PubView(index: index, now: now),
    ),
    Route(path: '/hall-of-fame', title: _title('Hall of Fame'), builder: (_, _) => HofPage(data)),
    Route(
      path: '/roadmap',
      title: _title('Roadmap'),
      builder: (_, _) => data.roadmap.tracks.isEmpty
          ? const Component.text('The roadmap is not available yet.')
          : RoadmapView(roadmap: data.roadmap, knownProjects: [for (final r in index.projects) r.id]),
    ),
    Route(path: '/about', title: _title('About'), builder: (_, _) => const AboutPage()),
    Route(
      path: '/categories',
      title: _title('Explore by category'),
      builder: (_, _) => ExploreView(index: index),
    ),
    for (final MapEntry(key: slug, value: label) in index.categories.entries)
      Route(
        path: '/categories/$slug',
        title: _title(label),
        builder: (_, _) => CategoryPage(data: data, slug: slug),
      ),
    for (final MapEntry(key: id, value: detail) in data.details.entries)
      Route(
        path: '/p/$id',
        title: _title(detail.row.name),
        builder: (_, _) => DetailPage(
          detail: detail,
          related: [for (final r in detail.related) ?data.row(r)],
          categories: index.categories,
          now: data.now,
        ),
      ),
  ];
}
