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
import 'package:fv_web/components/layout/intro_splash.dart' as _intro_splash;
import 'package:fv_web/components/layout/lamp.dart' as _lamp;
import 'package:fv_web/components/layout/palette_row.dart' as _palette_row;
import 'package:fv_web/components/layout/site_footer.dart' as _site_footer;
import 'package:fv_web/components/layout/site_header.dart' as _site_header;
import 'package:fv_web/components/layout/site_nav.dart' as _site_nav;
import 'package:fv_web/components/nominate/category_combo.dart'
    as _category_combo;
import 'package:fv_web/components/nominate/modal_shell.dart' as _modal_shell;
import 'package:fv_web/components/nominate/nominations.dart' as _nominations;
import 'package:fv_web/components/project/mini_row.dart' as _mini_row;
import 'package:fv_web/components/project/project_card.dart' as _project_card;
import 'package:fv_web/components/project/project_table.dart' as _project_table;
import 'package:fv_web/components/project/table_extras.dart' as _table_extras;
import 'package:fv_web/components/project/tier_pips.dart' as _tier_pips;
import 'package:fv_web/components/project/trend_row.dart' as _trend_row;
import 'package:fv_web/components/ui/icon.dart' as _icon;
import 'package:fv_web/components/ui/project_logo.dart' as _project_logo;
import 'package:fv_web/components/ui/seg_control.dart' as _seg_control;
import 'package:fv_web/components/ui/sparkline.dart' as _sparkline;
import 'package:fv_web/data/codecs.dart' as _codecs;
import 'package:fv_web/pages/about/about_page.dart' as _about_page;
import 'package:fv_web/pages/detail/chart_plot.dart' as _chart_plot;
import 'package:fv_web/pages/detail/detail_header.dart' as _detail_header;
import 'package:fv_web/pages/detail/detail_page.dart' as _detail_page;
import 'package:fv_web/pages/detail/history_timeline.dart' as _history_timeline;
import 'package:fv_web/pages/detail/kpi_cells.dart' as _kpi_cells;
import 'package:fv_web/pages/detail/related_grid.dart' as _related_grid;
import 'package:fv_web/pages/detail/source_panel.dart' as _source_panel;
import 'package:fv_web/pages/detail/trend_chart.dart' as _trend_chart;
import 'package:fv_web/pages/explore/category_card.dart' as _category_card;
import 'package:fv_web/pages/explore/category_page.dart' as _category_page;
import 'package:fv_web/pages/explore/category_tabs.dart' as _category_tabs;
import 'package:fv_web/pages/explore/explore_view.dart' as _explore_view;
import 'package:fv_web/pages/hof/developer_card.dart' as _developer_card;
import 'package:fv_web/pages/hof/hof_page.dart' as _hof_page;
import 'package:fv_web/pages/hof/inductee_card.dart' as _inductee_card;
import 'package:fv_web/pages/home/hof_preview.dart' as _hof_preview;
import 'package:fv_web/pages/home/home_hero.dart' as _home_hero;
import 'package:fv_web/pages/home/home_page.dart' as _home_page;
import 'package:fv_web/pages/home/side_list.dart' as _side_list;
import 'package:fv_web/pages/home/trending_card.dart' as _trending_card;
import 'package:fv_web/pages/projects/filter_bar.dart' as _filter_bar;
import 'package:fv_web/pages/projects/projects_view.dart' as _projects_view;
import 'package:fv_web/pages/pub/pub_row.dart' as _pub_row;
import 'package:fv_web/pages/pub/pub_view.dart' as _pub_view;
import 'package:fv_web/pages/rankings/rankings_view.dart' as _rankings_view;
import 'package:fv_web/pages/roadmap/helicopter.dart' as _helicopter;
import 'package:fv_web/pages/roadmap/lesson.dart' as _lesson;
import 'package:fv_web/pages/roadmap/metro_map.dart' as _metro_map;
import 'package:fv_web/pages/roadmap/metro_station.dart' as _metro_station;
import 'package:fv_web/pages/roadmap/roadmap_view.dart' as _roadmap_view;
import 'package:fv_web/pages/roadmap/stop_panel.dart' as _stop_panel;

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
    _intro_splash.IntroSplash: ClientTarget<_intro_splash.IntroSplash>(
      'intro_splash',
    ),
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
  styles: () => [
    ..._command_palette.CommandPalette.styles,
    ..._footer_watermark.FooterWatermark.styles,
    ..._intro_splash.IntroSplash.styles,
    ..._lamp.Lamp.styles,
    ..._palette_row.PaletteRow.styles,
    ..._palette_row.PaletteSuggestions.styles,
    ..._site_footer.SiteFooter.styles,
    ..._site_header.SiteHeader.styles,
    ..._site_nav.SiteNav.styles,
    ..._category_combo.CategoryCombo.styles,
    ..._modal_shell.ModalShell.styles,
    ..._mini_row.MiniRow.styles,
    ..._project_card.ProjectCard.styles,
    ..._project_table.ProjectTable.styles,
    ..._table_extras.TableLegend.styles,
    ..._tier_pips.MomentumMeter.styles,
    ..._tier_pips.StarPips.styles,
    ..._trend_row.TrendRow.styles,
    ..._icon.Icon.styles,
    ..._project_logo.ProjectLogo.styles,
    ..._seg_control.ChipTabs.styles,
    ..._sparkline.Sparkline.styles,
    ..._about_page.AboutPage.styles,
    ..._chart_plot.ChartPlot.styles,
    ..._detail_header.DetailHeader.styles,
    ..._detail_page.DetailPage.styles,
    ..._history_timeline.HistoryTimeline.styles,
    ..._kpi_cells.KpiGrid.styles,
    ..._related_grid.RelatedGrid.styles,
    ..._source_panel.SourcePanel.styles,
    ..._trend_chart.TrendChart.styles,
    ..._category_card.CategoryCard.styles,
    ..._category_page.CategoryPage.styles,
    ..._category_tabs.CategoryTabs.styles,
    ..._explore_view.ExploreView.styles,
    ..._developer_card.DeveloperCard.styles,
    ..._hof_page.HofPage.styles,
    ..._inductee_card.InducteeCard.styles,
    ..._hof_preview.HofPreview.styles,
    ..._home_hero.HomeHero.styles,
    ..._home_page.HomePage.styles,
    ..._side_list.SideList.styles,
    ..._trending_card.TrendingCard.styles,
    ..._filter_bar.FilterBar.styles,
    ..._projects_view.ProjectsView.styles,
    ..._pub_row.PubRow.styles,
    ..._pub_view.PubView.styles,
    ..._rankings_view.RankingsView.styles,
    ..._helicopter.Helicopter.styles,
    ..._lesson.Lesson.styles,
    ..._metro_map.MetroMap.styles,
    ..._metro_station.MetroLineTag.styles,
    ..._metro_station.MetroStation.styles,
    ..._roadmap_view.RoadmapView.styles,
    ..._stop_panel.StopPanel.styles,
  ],
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
};
Map<String, Object?> __trending_cardTrendingCard(
  _trending_card.TrendingCard c,
) => {'index': _codecs.IndexData(c.index).encode(), 'now': c.now};
Map<String, Object?> __projects_viewProjectsView(
  _projects_view.ProjectsView c,
) => {'index': _codecs.IndexData(c.index).encode(), 'now': c.now};
Map<String, Object?> __pub_viewPubView(_pub_view.PubView c) => {
  'index': _codecs.IndexData(c.index).encode(),
  'now': c.now,
};
Map<String, Object?> __rankings_viewRankingsView(
  _rankings_view.RankingsView c,
) => {'index': _codecs.IndexData(c.index).encode()};
Map<String, Object?> __roadmap_viewRoadmapView(_roadmap_view.RoadmapView c) => {
  'roadmap': _codecs.RoadmapData(c.roadmap).encode(),
  'knownProjects': c.knownProjects,
};
