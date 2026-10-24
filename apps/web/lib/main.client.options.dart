// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:fv_web/components/layout/back_to_top.dart'
    deferred as _back_to_top;
import 'package:fv_web/components/layout/command_palette.dart'
    deferred as _command_palette;
import 'package:fv_web/components/layout/footer_watermark.dart'
    deferred as _footer_watermark;
import 'package:fv_web/components/layout/intro_controller.dart'
    deferred as _intro_controller;
import 'package:fv_web/components/layout/lamp.dart' deferred as _lamp;
import 'package:fv_web/components/nominate/nominations.dart'
    deferred as _nominations;
import 'package:fv_web/data/codecs.dart' as _codecs;
import 'package:fv_web/pages/detail/trend_chart.dart' deferred as _trend_chart;
import 'package:fv_web/pages/explore/category_tabs.dart'
    deferred as _category_tabs;
import 'package:fv_web/pages/explore/explore_view.dart'
    deferred as _explore_view;
import 'package:fv_web/pages/hof/hof_search.dart' deferred as _hof_search;
import 'package:fv_web/pages/home/trending_card.dart'
    deferred as _trending_card;
import 'package:fv_web/pages/projects/projects_view.dart'
    deferred as _projects_view;
import 'package:fv_web/pages/pub/pub_view.dart' deferred as _pub_view;
import 'package:fv_web/pages/rankings/rankings_view.dart'
    deferred as _rankings_view;
import 'package:fv_web/pages/roadmap/roadmap_view.dart'
    deferred as _roadmap_view;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'back_to_top': ClientLoader(
      (p) => _back_to_top.BackToTop(),
      loader: _back_to_top.loadLibrary,
    ),
    'command_palette': ClientLoader(
      (p) => _command_palette.CommandPalette(),
      loader: _command_palette.loadLibrary,
    ),
    'footer_watermark': ClientLoader(
      (p) => _footer_watermark.FooterWatermark(),
      loader: _footer_watermark.loadLibrary,
    ),
    'intro_controller': ClientLoader(
      (p) => _intro_controller.IntroController(),
      loader: _intro_controller.loadLibrary,
    ),
    'lamp': ClientLoader((p) => _lamp.Lamp(), loader: _lamp.loadLibrary),
    'nominations': ClientLoader(
      (p) => _nominations.Nominations(
        categories: (p['categories'] as List<Object?>).cast<String>(),
      ),
      loader: _nominations.loadLibrary,
    ),
    'trend_chart': ClientLoader(
      (p) => _trend_chart.TrendChart(
        detail: _codecs.DetailData.decode(p['detail'] as Map<String, Object?>),
      ),
      loader: _trend_chart.loadLibrary,
    ),
    'category_tabs': ClientLoader(
      (p) => _category_tabs.CategoryTabs(
        index: _codecs.IndexData.decode(p['index'] as Map<String, Object?>),
      ),
      loader: _category_tabs.loadLibrary,
    ),
    'explore_view': ClientLoader(
      (p) => _explore_view.ExploreView(
        index: _codecs.IndexData.decode(p['index'] as Map<String, Object?>),
        counts: (p['counts'] as Map<String, Object?>).cast<String, int>(),
        growth: (p['growth'] as Map<String, Object?>).cast<String, int>(),
      ),
      loader: _explore_view.loadLibrary,
    ),
    'hof_search': ClientLoader(
      (p) => _hof_search.HofSearch(),
      loader: _hof_search.loadLibrary,
    ),
    'trending_card': ClientLoader(
      (p) => _trending_card.TrendingCard(
        index: _codecs.IndexData.decode(p['index'] as Map<String, Object?>),
        now: p['now'] as String,
      ),
      loader: _trending_card.loadLibrary,
    ),
    'projects_view': ClientLoader(
      (p) => _projects_view.ProjectsView(
        index: _codecs.IndexData.decode(p['index'] as Map<String, Object?>),
        total: p['total'] as int,
        now: p['now'] as String,
      ),
      loader: _projects_view.loadLibrary,
    ),
    'pub_view': ClientLoader(
      (p) => _pub_view.PubView(
        index: _codecs.IndexData.decode(p['index'] as Map<String, Object?>),
        total: p['total'] as int,
        now: p['now'] as String,
      ),
      loader: _pub_view.loadLibrary,
    ),
    'rankings_view': ClientLoader(
      (p) => _rankings_view.RankingsView(
        index: _codecs.IndexData.decode(p['index'] as Map<String, Object?>),
      ),
      loader: _rankings_view.loadLibrary,
    ),
    'roadmap_view': ClientLoader(
      (p) => _roadmap_view.RoadmapView(
        roadmap: _codecs.RoadmapData.decode(
          p['roadmap'] as Map<String, Object?>,
        ),
        knownProjects: (p['knownProjects'] as List<Object?>).cast<String>(),
      ),
      loader: _roadmap_view.loadLibrary,
    ),
  },
);
