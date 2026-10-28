import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icons.dart';
import '../../components/ui/seg_control.dart';
import '../../styles/css.dart';
import 'chart_data.dart';
import 'chart_plot.dart';

/// The detail page's interactive stars/downloads chart.
@client
class TrendChart extends StatefulComponent {
  const TrendChart({required this.detail, super.key});

  final ProjectDetail detail;

  @override
  State<TrendChart> createState() => _TrendChartState();

  @css
  static List<StyleRule> get styles => [
    rule('.chart-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '12px',
      'align-items': 'center',
      'padding': '12px 16px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.chart-head .chip-tabs', {'gap': '6px'}),
    rule('.chart-head .spacer', {'flex': '1'}),
    rule('.chart-body', {'padding': '24px 16px 12px'}),
    rule('.chart-empty', {
      'height': '220px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'flex-direction': 'column',
      'gap': '8px',
      'border': '1px dashed var(--line)',
      'text-align': 'center',
      'padding': '0 24px',
    }),
    rule('.chart-empty b', {'font-size': '15px', 'font-weight': '600'}),
    rule('.chart-empty span', {'font-size': '14px', 'color': 'var(--muted)'}),
  ];
}

class _TrendChartState extends State<TrendChart> {
  ChartMetric _metric = ChartMetric.stars;
  ChartRange _range = ChartRange.year;
  int? _hover;

  @override
  Component build(BuildContext context) {
    final d = component.detail;
    final series = chartSeries(d, _metric, _range);
    return section(classes: 'panel', [
      div(classes: 'chart-head', [
        ChipTabs<ChartMetric>(
          options: const [(ChartMetric.stars, 'Stars'), (ChartMetric.downloads, 'Downloads')],
          icon: (m) => switch (m) {
            ChartMetric.stars => Icons.star,
            ChartMetric.downloads => Icons.download,
          },
          selected: _metric,
          onSelect: (m) => setState(() {
            _metric = m;
            _hover = null;
          }),
        ),
        span(classes: 'spacer', []),
        SegControl<ChartRange>(
          label: 'Range',
          options: [for (final r in ChartRange.values) (r, r.label)],
          selected: _range,
          onSelect: (r) => setState(() {
            _range = r;
            _hover = null;
          }),
        ),
      ]),
      div(classes: 'chart-body', [
        if (series.empty != null)
          div(classes: 'chart-empty', [
            b([.text('No history for this metric')]),
            span([.text(series.empty!)]),
          ])
        else
          ChartPlot(
            detail: d,
            points: series.points,
            metric: _metric,
            range: _range,
            hover: _hover,
            onHover: (index) {
              if (index != _hover) setState(() => _hover = index);
            },
          ),
      ]),
    ]);
  }
}
