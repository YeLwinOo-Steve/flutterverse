// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:fv_web/components/layout/back_to_top.dart' as _back_to_top;
import 'package:fv_web/components/layout/command_palette.dart'
    as _command_palette;
import 'package:fv_web/components/layout/footer_watermark.dart'
    as _footer_watermark;
import 'package:fv_web/components/layout/intro_controller.dart'
    as _intro_controller;
import 'package:fv_web/components/layout/lamp.dart' as _lamp;
import 'package:fv_web/components/nominate/nominations.dart' as _nominations;
import 'package:fv_web/data/codecs.dart' as _codecs;
import 'package:fv_web/pages/detail/trend_chart.dart' as _trend_chart;
import 'package:fv_web/pages/explore/category_tabs.dart' as _category_tabs;
import 'package:fv_web/pages/explore/explore_view.dart' as _explore_view;
import 'package:fv_web/pages/hof/hof_search.dart' as _hof_search;
import 'package:fv_web/pages/home/trending_card.dart' as _trending_card;
import 'package:fv_web/pages/projects/projects_view.dart' as _projects_view;
import 'package:fv_web/pages/pub/pub_view.dart' as _pub_view;
import 'package:fv_web/pages/rankings/rankings_view.dart' as _rankings_view;
import 'package:fv_web/pages/roadmap/roadmap_view.dart' as _roadmap_view;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _back_to_top.BackToTop: ClientTarget<_back_to_top.BackToTop>('back_to_top'),
    _command_palette.CommandPalette:
        ClientTarget<_command_palette.CommandPalette>('command_palette'),
    _footer_watermark.FooterWatermark:
        ClientTarget<_footer_watermark.FooterWatermark>('footer_watermark'),
    _intro_controller.IntroController:
        ClientTarget<_intro_controller.IntroController>('intro_controller'),
    _lamp.Lamp: ClientTarget<_lamp.Lamp>('lamp'),
    _nominations.Nominations: ClientTarget<_nominations.Nominations>(
      'nominations',
      params: __nominationsNominations,
    ),
    _trend_chart.TrendChart: ClientTarget<_trend_chart.TrendChart>(
      'trend_chart',
      params: __trend_chartTrendChart,
    ),
    _category_tabs.CategoryTabs: ClientTarget<_category_tabs.CategoryTabs>(
      'category_tabs',
      params: __category_tabsCategoryTabs,
    ),
    _explore_view.ExploreView: ClientTarget<_explore_view.ExploreView>(
      'explore_view',
      params: __explore_viewExploreView,
    ),
    _hof_search.HofSearch: ClientTarget<_hof_search.HofSearch>('hof_search'),
    _trending_card.TrendingCard: ClientTarget<_trending_card.TrendingCard>(
      'trending_card',
      params: __trending_cardTrendingCard,
    ),
    _projects_view.ProjectsView: ClientTarget<_projects_view.ProjectsView>(
      'projects_view',
      params: __projects_viewProjectsView,
    ),
    _pub_view.PubView: ClientTarget<_pub_view.PubView>(
      'pub_view',
      params: __pub_viewPubView,
    ),
    _rankings_view.RankingsView: ClientTarget<_rankings_view.RankingsView>(
      'rankings_view',
      params: __rankings_viewRankingsView,
    ),
    _roadmap_view.RoadmapView: ClientTarget<_roadmap_view.RoadmapView>(
      'roadmap_view',
      params: __roadmap_viewRoadmapView,
    ),
  },
  stylesId: 'main.css',
);

Map<String, Object?> __nominationsNominations(_nominations.Nominations c) => {
  'categories': c.categories,
};
Map<String, Object?> __trend_chartTrendChart(_trend_chart.TrendChart c) => {
  'detail': _codecs.DetailData(c.detail).encode(),
};
Map<String, Object?> __category_tabsCategoryTabs(
  _category_tabs.CategoryTabs c,
) => {'index': _codecs.IndexData(c.index).encode()};
Map<String, Object?> __explore_viewExploreView(_explore_view.ExploreView c) => {
  'index': _codecs.IndexData(c.index).encode(),
  'counts': c.counts,
  'growth': c.growth,
};
Map<String, Object?> __trending_cardTrendingCard(
  _trending_card.TrendingCard c,
) => {'index': _codecs.IndexData(c.index).encode(), 'now': c.now};
Map<String, Object?> __projects_viewProjectsView(
  _projects_view.ProjectsView c,
) => {
  'index': _codecs.IndexData(c.index).encode(),
  'total': c.total,
  'now': c.now,
};
Map<String, Object?> __pub_viewPubView(_pub_view.PubView c) => {
  'index': _codecs.IndexData(c.index).encode(),
  'total': c.total,
  'now': c.now,
};
Map<String, Object?> __rankings_viewRankingsView(
  _rankings_view.RankingsView c,
) => {'index': _codecs.IndexData(c.index).encode()};
Map<String, Object?> __roadmap_viewRoadmapView(_roadmap_view.RoadmapView c) => {
  'roadmap': _codecs.RoadmapData(c.roadmap).encode(),
  'knownProjects': c.knownProjects,
};
