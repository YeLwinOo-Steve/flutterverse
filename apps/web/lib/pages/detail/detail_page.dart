import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import 'detail_header.dart';
import 'history_timeline.dart';
import 'kpi_cells.dart';
import 'related_grid.dart';
import 'source_panels.dart';
import 'trend_chart.dart';

/// `/p/<id>`, pre-rendered from `p/<id>.json`.
class DetailPage extends StatelessComponent {
  const DetailPage({
    required this.detail,
    required this.related,
    required this.categories,
    required this.now,
    super.key,
  });

  final ProjectDetail detail;
  final List<ProjectRow> related;
  final Map<String, String> categories;
  final DateTime now;

  @override
  Component build(BuildContext context) {
    final r = detail.row;
    return div(classes: 'detail', [
      DetailHeader(row: r, categories: categories),
      KpiGrid(detail: detail, now: now),
      div(classes: 'detail-cols', [
        div(classes: 'detail-main', [
          TrendChart(detail: detail),
          HistoryTimeline(events: timelineOf(detail)),
          if (related.isNotEmpty) RelatedGrid(rows: related),
        ]),
        aside(classes: 'detail-aside', [
          ?pubPanel(detail, now),
          ?githubPanel(detail, now),
          if (r.platforms.isNotEmpty)
            section(classes: 'panel platforms', [
              span([.text('Platforms')]),
              div([
                for (final p in r.platforms) span(classes: 'pill', [.text(p)]),
              ]),
            ]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.detail', {'display': 'flex', 'flex-direction': 'column', 'gap': '24px'}),
    rule('.detail-cols', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '24px', 'align-items': 'flex-start'}),
    rule('.detail-main', {
      'flex': '1 1 600px',
      'min-width': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '24px',
    }),
    rule('.detail-aside', {
      'flex': '1 1 300px',
      'min-width': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '16px',
    }),
    rule('.platforms', {'padding': '16px', 'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.platforms > span', {'font-size': '15px', 'font-weight': '600'}),
    rule('.platforms > div', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '6px'}),
    rule('.platforms .pill', {'padding': '4px 10px'}),
  ];
}
