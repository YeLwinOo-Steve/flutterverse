import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// Notable dates grouped by year, newest year first.
class HistoryTimeline extends StatelessComponent {
  const HistoryTimeline({required this.events, super.key});

  final List<TimelineEvent> events;

  @override
  Component build(BuildContext context) {
    final years = <int, List<TimelineEvent>>{};
    for (final e in events) {
      years.putIfAbsent(e.date.year, () => []).add(e);
    }
    return section(classes: 'detail-section', [
      h2([.text('History')]),
      div(classes: 'timeline', [
        for (final MapEntry(key: year, value: list) in years.entries.toList().reversed)
          div(classes: 'tl-year', [
            span(classes: 'tl-year-label', [.text('$year')]),
            div(classes: 'tl-events', [
              for (final e in list)
                div(classes: 'tl-event', [
                  span(classes: e.source == EventSource.calculated ? 'tl-dot calc' : 'tl-dot', []),
                  span(classes: 'tl-label', [.text(e.label)]),
                  span(classes: 'tl-date', [.text(monthYear(e.date))]),
                ]),
            ]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.detail-section', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.detail-section h2', {'font-size': '18px', 'font-weight': '600'}),
    rule('.detail-section-note', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.timeline', {'border-top': '1px solid var(--line)'}),
    rule('.tl-year', {
      'display': 'grid',
      'grid-template-columns': '88px minmax(0,1fr)',
      'gap': '16px',
      'padding': '12px 0',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.tl-year-label', {'font': mono(15, weight: 600)}),
    rule('.tl-events', {'display': 'flex', 'flex-direction': 'column', 'gap': '8px'}),
    rule('.tl-event', {'display': 'flex', 'gap': '12px', 'align-items': 'center', 'font-size': '15px'}),
    rule('.tl-dot', {
      'width': '8px',
      'height': '8px',
      'flex-shrink': '0',
      'background': 'transparent',
      'border': '1.5px solid var(--ink)',
      'border-radius': '50%',
    }),
    rule('.tl-dot.calc', {
      'background': 'var(--accent)',
      'border-color': 'var(--accent)',
      'transform': 'rotate(45deg)',
      'border-radius': '0',
    }),
    rule('.tl-label', {'flex': '1'}),
    rule('.tl-date', {'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
  ];
}
