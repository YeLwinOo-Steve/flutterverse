import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import 'metro_layout.dart';
import 'metro_map.dart';

/// A line's name badge at the start of its row.
class MetroLineTag extends StatelessComponent {
  const MetroLineTag({
    required this.row,
    required this.code,
    required this.name,
    required this.done,
    required this.vertical,
    super.key,
  });

  final MetroRow row;

  /// `F` or `D`, prefixed to the line number.
  final String code;
  final String name;

  /// Completed stops on this line.
  final int done;
  final bool vertical;

  @override
  Component build(BuildContext context) {
    final color = lineColor(row.index);
    return div(
      classes: vertical ? 'line-tag vertical' : 'line-tag',
      styles: Styles(raw: {'top': vertical ? '${row.y - 74}px' : '${row.y + MetroLayout.jog / 2}px'}),
      [
        span(
          classes: 'line-chip',
          styles: Styles(raw: {'background': color, 'box-shadow': '0 0 0 3px var(--surface), 0 0 0 5px $color'}),
          [.text('$code${row.index + 1}')],
        ),
        div(classes: 'line-text', [
          span(classes: 'eyebrow wide', [.text('Line ${row.index + 1}')]),
          span(classes: 'line-name', [.text(name)]),
          span(classes: 'line-prog', [.text('$done/${row.stops.length} stops')]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.line-tag', {
      'position': 'absolute',
      'left': '24px',
      'transform': 'translateY(-50%)',
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'width': '200px',
    }),
    rule('.line-tag.vertical', {'transform': 'none', 'gap': '10px', 'width': 'auto'}),
    rule('.line-chip', {
      'width': '40px',
      'height': '40px',
      'flex-shrink': '0',
      'border-radius': '50%',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'color': 'var(--metro-ink)',
      'font': mono(13, weight: 600),
    }),
    rule('.line-tag.vertical .line-chip', {'width': '32px', 'height': '32px'}),
    rule('.line-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '2px', 'min-width': '0'}),
    rule('.line-tag.vertical .line-text', {
      'flex-direction': 'row',
      'align-items': 'baseline',
      'gap': '10px',
      'flex-wrap': 'wrap',
    }),
    rule('.line-name', {'font-size': '16px', 'font-weight': '600', 'letter-spacing': '-0.01em', 'line-height': '1.15'}),
    rule('.line-prog', {'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
  ];
}

/// One stop on the metro map: a ring (filled when done), its rotated label
/// and progress.
class MetroStation extends StatelessComponent {
  const MetroStation({
    required this.stop,
    required this.stage,
    required this.done,
    required this.current,
    required this.selected,
    required this.interchange,
    required this.showMeta,
    required this.learned,
    required this.vertical,
    required this.onTap,
    super.key,
  });

  final MetroStop stop;
  final RoadmapStage stage;
  final bool done, current, selected, interchange, showMeta, vertical;

  /// Learned topics at this stop.
  final int learned;
  final void Function() onTap;

  @override
  Component build(BuildContext context) {
    final c = lineColor(stop.row);
    final size = current ? 30 : (interchange ? 26 : 20);
    final emphasis = interchange || current;
    return div(
      classes: 'station',
      attributes: {
        'title': stage.title,
        'role': 'button',
        'tabindex': '0',
        'aria-label': 'Stop ${stop.index + 1}: ${stage.title}',
      },
      styles: Styles(
        raw: {
          'left': '${stop.x}px',
          'top': '${stop.y}px',
          'width': '${size}px',
          'height': '${size}px',
          'z-index': selected ? '3' : '2',
        },
      ),
      events: {'click': (_) => onTap()},
      [
        span(
          classes: 'station-dot',
          styles: Styles(
            raw: {
              'background': done ? c : 'var(--surface)',
              'border': '${emphasis ? 5 : 4}px solid ${emphasis ? 'var(--ink)' : c}',
              'box-shadow': selected
                  ? '0 0 0 4px var(--surface), 0 0 0 6px var(--ink)'
                  : (current ? '0 0 0 7px color-mix(in srgb, $c 22%, transparent)' : '0 0 0 3px var(--surface)'),
            },
          ),
          [
            if (done)
              const RawText(
                '<svg width="10" height="10" viewBox="0 0 16 16" class="station-tick"><path d="M3 8.5 6.5 12 13 4.5"/></svg>',
              ),
          ],
        ),
        span(
          classes: vertical ? 'station-label vertical' : 'station-label',
          styles: Styles(
            raw: vertical
                ? {'left': '${size / 2 + (current ? 40 : 26)}px'}
                : {'left': '${size / 2 + 2}px', 'bottom': '${size / 2 + (current ? 16 : 12)}px'},
          ),
          [
            span(classes: 'station-num', [.text((stop.index + 1).toString().padLeft(2, '0'))]),
            span(classes: selected ? 'station-name on' : 'station-name', [.text(stage.title)]),
          ],
        ),
        if (showMeta)
          span(classes: 'station-meta', styles: Styles(raw: {'top': '${size + 8}px'}), [
            .text('$learned/${stage.topics.length}'),
          ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.station', {
      'position': 'absolute',
      'transform': 'translate(-50%,-50%)',
      'cursor': 'pointer',
      'outline': 'none',
    }),
    rule('.station-dot', {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '100%',
      'height': '100%',
      'border-radius': '50%',
      'box-sizing': 'border-box',
      'transition': 'box-shadow .15s',
    }),
    rule('.station-tick', {'display': 'block'}),
    rule('.station-tick path', {
      'fill': 'none',
      'stroke': 'var(--metro-ink)',
      'stroke-width': '2.6',
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round',
    }),
    rule('.station-label', {
      'position': 'absolute',
      'transform-origin': '0 100%',
      'transform': 'rotate(-30deg)',
      'display': 'flex',
      'align-items': 'baseline',
      'gap': '6px',
      'white-space': 'nowrap',
      'font-size': '16px',
      'letter-spacing': '-0.01em',
      'pointer-events': 'none',
    }),
    rule('.station-label.vertical', {'top': '50%', 'transform': 'translateY(-50%)', 'gap': '8px'}),
    rule('.station-num', {'font': mono(12), 'color': 'var(--muted)'}),
    rule('.station-name', {'font-weight': '600', 'color': 'var(--ink)'}),
    rule('.station-name.on', {'font-weight': '700', 'color': 'var(--accent)'}),
    rule('.station-meta', {
      'position': 'absolute',
      'left': '50%',
      'transform': 'translateX(-50%)',
      'font': mono(13),
      'color': 'var(--muted)',
      'white-space': 'nowrap',
    }),
  ];
}
