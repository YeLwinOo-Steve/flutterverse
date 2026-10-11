import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../styles/css.dart';
import 'chart_data.dart';

/// The chart itself: headline, smoothed line and area, event markers, end
/// label and the hover tooltip.
class ChartPlot extends StatelessComponent {
  const ChartPlot({
    required this.detail,
    required this.points,
    required this.metric,
    required this.range,
    required this.hover,
    required this.onHover,
    super.key,
  });

  final ProjectDetail detail;
  final List<ChartPoint> points;
  final ChartMetric metric;
  final ChartRange range;

  /// Index of the hovered point, if any.
  final int? hover;
  final void Function(int?) onHover;

  @override
  Component build(BuildContext context) {
    final d = detail, pts = points;
    final g = ChartGeometry(pts);
    final stars = metric == ChartMetric.stars;
    final repoWide = d.row.sharedRepo;
    final headline = stars
        ? '${compactNumber(d.row.shownStars)} ${repoWide ? 'repo stars' : 'stars'}'
        : '${compactNumber(d.row.downloads)} / 30d';
    final delta = pts.last.v - pts.first.v;
    final caption = stars
        ? '${signedNumber(delta)} over ${range == ChartRange.all ? 'all time' : range.label}'
              '${repoWide ? ' · whole ${d.row.repo} repo' : ''}'
        : 'Weekly downloads on pub.dev';
    final t0 = pts.first.t, t1 = pts.last.t, span_ = t1.difference(t0).inMinutes;
    final marks = span_ <= 0
        ? <TimelineEvent>[]
        : timelineOf(d).where((e) {
            final f = e.date.difference(t0).inMinutes / span_;
            return e.date.isAfter(t0) && e.date.isBefore(t1) && f < 0.9;
          }).toList();
    final shown = marks.length > 4 ? marks.sublist(marks.length - 4) : marks;
    final endY = g.y(pts.last.v) / 2;
    final hovered = hover != null && hover! < g.n ? hover : null;

    return div([
      div(classes: 'chart-headline', [
        b([.text(headline)]),
        span([.text(caption)]),
      ]),
      div(
        classes: 'chart-plot',
        events: {
          'mousemove': (e) {
            final me = e as web.MouseEvent;
            final rect = (me.currentTarget as web.Element).getBoundingClientRect();
            final f = ((me.x - rect.left) / rect.width).clamp(0.0, 1.0);
            onHover((f * (g.n - 1)).round());
          },
          'mouseleave': (_) => onHover(null),
        },
        [
          for (final (top, text) in g.gridLabels)
            span(classes: 'chart-grid-label', styles: Styles(raw: {'top': '${top * 100}%'}), [.text(text)]),
          for (final e in shown) ..._mark(e, t0, span_),
          svg(
            viewBox: '0 0 800 200',
            attributes: {'preserveAspectRatio': 'none', 'aria-hidden': 'true'},
            [
              const RawText(
                '<defs><linearGradient id="fvArea" x1="0" y1="0" x2="0" y2="1">'
                '<stop offset="0" style="stop-color:var(--accent);stop-opacity:0.26"/>'
                '<stop offset="1" style="stop-color:var(--accent);stop-opacity:0"/></linearGradient></defs>',
              ),
              path(d: ChartGeometry.gridPath, classes: 'chart-gridline', []),
              path(d: g.area, attributes: {'style': 'fill:url(#fvArea)'}, []),
              path(d: g.line, classes: 'chart-line', []),
            ],
          ),
          div(
            classes: 'chart-end-dot',
            styles: Styles(raw: {'top': '$endY%'}),
            [],
          ),
          span(classes: 'chart-end-label', styles: Styles(raw: {'top': '$endY%'}), [.text(g.label(pts.last.v))]),
          if (hovered != null) ..._hoverLayer(g, hovered),
        ],
      ),
      div(classes: 'chart-x', [
        for (final x in g.xLabels) span([.text(x)]),
      ]),
    ]);
  }

  List<Component> _mark(TimelineEvent e, DateTime t0, int spanMinutes) {
    final xp = e.date.difference(t0).inMinutes / spanMinutes * 100;
    final shift = xp > 85 ? 'translateX(-100%)' : (xp < 15 ? 'translateX(0)' : 'translateX(-50%)');
    return [
      div(
        classes: 'chart-mark-line',
        styles: Styles(raw: {'left': '$xp%'}),
        [],
      ),
      span(classes: 'chart-mark-label', styles: Styles(raw: {'left': '$xp%', 'transform': shift}), [
        .text(markerLabel(e.label)),
      ]),
    ];
  }

  List<Component> _hoverLayer(ChartGeometry g, int i) {
    final xp = g.x(i) / 8, yp = g.y(g.points[i].v) / 2;
    final unit = metric == ChartMetric.stars ? ' stars' : ' downloads';
    final p = g.points[i];
    return [
      div(
        classes: 'chart-cursor',
        styles: Styles(raw: {'left': '$xp%'}),
        [],
      ),
      div(
        classes: 'chart-dot',
        styles: Styles(raw: {'left': '$xp%', 'top': '$yp%'}),
        [],
      ),
      div(
        classes: 'chart-tip',
        styles: Styles(
          raw: {
            'top': '$yp%',
            'left': '$xp%',
            'transform': 'translate(${xp > 70 ? 'calc(-100% - 16px)' : '16px'}, -50%)',
          },
        ),
        [
          span([.text(metric == ChartMetric.downloads ? 'Week ending ${fullDate(p.t)}' : fullDate(p.t))]),
          b([.text('${withCommas(p.v)}$unit')]),
        ],
      ),
    ];
  }

  @css
  static List<StyleRule> get styles => [
    rule('.chart-headline', {'display': 'flex', 'flex-direction': 'column', 'gap': '2px', 'margin-bottom': '12px'}),
    rule('.chart-headline b', {'font': "500 28px 'Geist',sans-serif", 'letter-spacing': '-0.02em'}),
    rule('.chart-headline span', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.chart-plot', {'position': 'relative', 'height': '300px', 'margin': '28px 0 0 0'}),
    rule('.chart-plot svg', {
      'width': '100%',
      'height': '100%',
      'display': 'block',
      'overflow': 'visible',
      'animation': 'fvFade .4s ease both',
    }),
    rule('.chart-grid-label', {
      'position': 'absolute',
      'left': '0',
      'transform': 'translateY(-120%)',
      'font': mono(11, weight: 400),
      'color': 'var(--muted)',
      'pointer-events': 'none',
    }),
    rule('.chart-gridline', {
      'fill': 'none',
      'stroke': 'var(--line)',
      'stroke-width': '1',
      'stroke-dasharray': '3 5',
      'vector-effect': 'non-scaling-stroke',
    }),
    rule('.chart-line', {
      'fill': 'none',
      'stroke': 'var(--accent)',
      'stroke-width': '2.25',
      'stroke-linejoin': 'round',
      'stroke-linecap': 'round',
      'vector-effect': 'non-scaling-stroke',
    }),
    rule('.chart-mark-line', {
      'position': 'absolute',
      'top': '0',
      'bottom': '0',
      'border-left': '1px dashed var(--line)',
      'pointer-events': 'none',
    }),
    rule('.chart-mark-label', {
      'position': 'absolute',
      'top': '-24px',
      'font': mono(11),
      'padding': '2px 7px',
      'border-radius': '999px',
      'background': 'var(--surface2)',
      'color': 'var(--ink)',
      'white-space': 'nowrap',
      'pointer-events': 'none',
    }),
    rule('.chart-end-dot', {
      'position': 'absolute',
      'left': '100%',
      'width': '10px',
      'height': '10px',
      'margin': '-5px 0 0 -5px',
      'border-radius': '50%',
      'background': 'var(--accent)',
      'box-shadow': '0 0 0 4px var(--accent-soft), 0 0 16px 2px color-mix(in srgb, var(--accent) 33%, transparent)',
      'pointer-events': 'none',
    }),
    rule('.chart-end-label', {
      'position': 'absolute',
      'right': '0',
      'transform': 'translate(-12px, 70%)',
      'font': mono(12, weight: 600),
      'padding': '3px 8px',
      'border-radius': '2px',
      'background': 'var(--ink)',
      'color': 'var(--bg)',
      'pointer-events': 'none',
      'white-space': 'nowrap',
    }),
    rule('.chart-cursor', {
      'position': 'absolute',
      'top': '0',
      'bottom': '0',
      'width': '1px',
      'background': 'var(--accent)',
      'opacity': '0.5',
      'pointer-events': 'none',
    }),
    rule('.chart-dot', {
      'position': 'absolute',
      'width': '12px',
      'height': '12px',
      'margin': '-6px 0 0 -6px',
      'background': 'var(--surface)',
      'border': '3px solid var(--accent)',
      'border-radius': '50%',
      'pointer-events': 'none',
      'box-shadow': '0 0 0 4px var(--accent-soft)',
    }),
    rule('.chart-tip', {
      'position': 'absolute',
      'background': 'var(--surface)',
      'border': '1px solid var(--line)',
      'padding': '8px 12px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '2px',
      'white-space': 'nowrap',
      'pointer-events': 'none',
      'box-shadow': '0 8px 24px rgba(4,43,89,0.12)',
    }),
    rule('.chart-tip span', {'font-size': '12px', 'color': 'var(--muted)'}),
    rule('.chart-tip b', {'font-size': '16px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.chart-x', {
      'display': 'flex',
      'justify-content': 'space-between',
      'margin-top': '12px',
      'font': mono(12, weight: 400),
      'color': 'var(--muted)',
    }),
  ];
}
