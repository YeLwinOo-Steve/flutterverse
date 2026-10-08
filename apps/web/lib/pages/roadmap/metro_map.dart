import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';
import 'helicopter.dart';
import 'metro_layout.dart';
import 'metro_station.dart';
import 'roadmap_progress.dart';

const _lineNames = {
  'flutter': ['Foundations', 'Interface', 'Data & logic', 'Production'],
  'dart': ['Basics', 'Language', 'Craft', 'Beyond'],
};

/// The CSS color of metro line [row].
String lineColor(int row) => 'var(--metro-${row % 4 + 1})';

/// The roadmap as a metro map: one line per group of stops, a helicopter at
/// the current stop, and controls to complete or step back a stop.
class MetroMap extends StatelessComponent {
  const MetroMap({
    required this.progress,
    required this.layout,
    required this.selected,
    required this.flying,
    required this.onSelect,
    required this.onSetStage,
    super.key,
  });

  final TrackProgress progress;
  final MetroLayout layout;
  final int selected;
  final bool flying;
  final void Function(int) onSelect;

  /// Marks a whole stop learned (true) or not (false).
  final void Function(int stage, bool learned) onSetStage;

  @override
  Component build(BuildContext context) {
    final m = layout, p = progress;
    final reach = p.reach, current = p.current, allDone = current < 0;
    final here = m.stop(reach);
    final names = _lineNames[p.trackId] ?? const ['Line 1', 'Line 2', 'Line 3', 'Line 4'];
    final code = p.trackId == 'dart' ? 'D' : 'F';
    final back = allDone ? -1 : reach - 1;
    final viewBox = '0 0 ${m.viewWidth} ${m.viewHeight}';

    return div(classes: 'metro-box panel', [
      div(classes: 'metro-outer', styles: Styles(raw: {'height': '${(m.viewHeight * m.scale).ceil()}px'}), [
        div(
          classes: 'metro-inner',
          styles: Styles(
            raw: {'width': '${m.viewWidth}px', 'height': '${m.viewHeight}px', 'transform': 'scale(${m.scale})'},
          ),
          [
            if (!m.vertical)
              for (final row in m.rows)
                div(
                  classes: row.index.isOdd ? 'metro-band alt' : 'metro-band',
                  styles: Styles(
                    raw: {
                      'top': '${row.y - MetroLayout.bandHeight / 2 + MetroLayout.jog / 2}px',
                      'height': '${MetroLayout.bandHeight}px',
                    },
                  ),
                  [],
                ),
            for (final t in m.transfers)
              _svg(viewBox, '<path d="$t" class="transfer-out"/><path d="$t" class="transfer-in"/>'),
            for (final row in m.rows) _svg(viewBox, _rails(row, reach)),
            for (final row in m.rows)
              MetroLineTag(
                row: row,
                code: code,
                name: names[row.index % names.length],
                done: row.stops.where((stop) => p.isDone(stop.index)).length,
                vertical: m.vertical,
              ),
            for (final s in m.stops)
              MetroStation(
                stop: s,
                stage: p.track.stages[s.index],
                done: p.isDone(s.index),
                current: s.index == current,
                selected: s.index == selected,
                interchange: m.isInterchange(s),
                showMeta: !m.vertical && s.index != reach,
                learned: p.learnedIn(s.index),
                vertical: m.vertical,
                onTap: () => onSelect(s.index),
              ),
            Helicopter(
              x: here.x,
              y: here.y,
              heading: m.heading(reach),
              color: lineColor(here.row),
              flying: flying,
              vertical: m.vertical,
              title: allDone ? 'Landed — journey complete' : 'You are here: ${p.track.stages[reach].title}',
            ),
            div(
              classes: 'metro-ctrl',
              styles: Styles(
                raw: m.vertical
                    ? {'left': '${here.x + 52}px', 'top': '${here.y + 16}px'}
                    : {'left': '${here.x}px', 'top': '${here.y + 24}px', 'transform': 'translateX(-50%)'},
              ),
              [
                if (back >= 0)
                  button(
                    classes: 'metro-back',
                    type: ButtonType.button,
                    attributes: {'title': 'Back to ${p.track.stages[back].title}', 'aria-label': 'Back one stop'},
                    onClick: () => onSetStage(back, false),
                    [const Icon(Icons.undo, size: 14, strokeWidth: 1.6)],
                  ),
                button(
                  classes: allDone ? 'metro-primary undo' : 'metro-primary',
                  type: ButtonType.button,
                  onClick: () => allDone ? onSetStage(p.track.stages.length - 1, false) : onSetStage(reach, true),
                  [
                    Icon(allDone ? Icons.undo : Icons.tick, size: 13, strokeWidth: 2),
                    .text(allDone ? 'Uncomplete' : 'Complete stop'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ]),
    ]);
  }

  /// The muted track, the completed part in the line's color, and the
  /// center gap that makes it read as rails.
  String _rails(MetroRow row, int reach) {
    final line = layout.linePath(row);
    final done = layout.donePath(row, reach);
    final gapClass = !layout.vertical && row.index.isOdd ? 'rail-gap alt' : 'rail-gap';
    return '<path d="$line" class="rail"/>'
        '${done == null ? '' : '<path d="$done" class="rail-done" style="stroke:${lineColor(row.index)}"/>'}'
        '<path d="$line" class="$gapClass"/>';
  }

  Component _svg(String viewBox, String paths) => RawText(
    '<svg viewBox="$viewBox" class="metro-svg" aria-hidden="true">$paths</svg>',
  );

  @css
  static List<StyleRule> get styles => [
    rule('.metro-box', {'overflow': 'hidden'}),
    rule('.metro-outer', {'position': 'relative'}),
    rule('.metro-inner', {'position': 'absolute', 'left': '0', 'top': '0', 'transform-origin': '0 0'}),
    rule('.metro-band', {'position': 'absolute', 'left': '0', 'right': '0', 'background': 'var(--surface)'}),
    rule('.metro-band.alt', {'background': 'var(--bg)', 'border-top': '1px dashed var(--line)'}),
    rule('.metro-svg', {
      'position': 'absolute',
      'left': '0',
      'top': '0',
      'width': '100%',
      'height': '100%',
      'display': 'block',
      'pointer-events': 'none',
      'overflow': 'visible',
    }),
    rule('.metro-svg path', {'fill': 'none', 'stroke-linejoin': 'round', 'stroke-linecap': 'round'}),
    rule('.transfer-out', {'stroke': 'var(--ink)', 'stroke-width': '14'}),
    rule('.transfer-in', {'stroke': 'var(--surface)', 'stroke-width': '7'}),
    rule('.rail', {'stroke': 'var(--muted)', 'stroke-width': '12', 'opacity': '0.32'}),
    rule('.rail-done', {'stroke-width': '12'}),
    rule('.rail-gap', {'stroke': 'var(--surface)', 'stroke-width': '6'}),
    rule('.rail-gap.alt', {'stroke': 'var(--bg)'}),
    rule('.metro-ctrl', {
      'position': 'absolute',
      'display': 'flex',
      'gap': '4px',
      'z-index': '5',
      'transition': 'left .9s cubic-bezier(.45,0,.2,1), top .9s cubic-bezier(.45,0,.2,1)',
    }),
    rule('.metro-back', {
      'width': '32px',
      'height': '32px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'padding': '0',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'color': 'var(--ink)',
      'border-radius': '2px',
      'cursor': 'pointer',
    }),
    rule('.metro-back:hover', {'border-color': 'var(--ink)'}),
    rule('.metro-primary', {
      'height': '32px',
      'padding': '0 12px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'border-radius': '2px',
      'cursor': 'pointer',
      'font': sans(13, weight: 500),
      'white-space': 'nowrap',
      'background': 'var(--ink)',
      'color': 'var(--bg)',
      'border': '1px solid var(--ink)',
    }),
    rule('.metro-primary.undo', {'background': 'var(--surface)', 'color': 'var(--ink)'}),
  ];
}
