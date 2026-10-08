import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../components/ui/seg_control.dart';
import '../../data/ranking.dart';
import '../../styles/css.dart';
import 'pub_row.dart';

enum _Tab {
  downloads('Most downloaded', 'Last 30 days', Icons.download),
  likes('Most liked', 'By pub.dev likes', Icons.heart),
  points('Top pub points', 'Quality score out of 160', Icons.check),
  recent('Recently updated', 'Latest releases', Icons.clock),
  favorites('Flutter Favorites', 'Picked by the Flutter team', Icons.star);

  const _Tab(this.label, this.description, this.icon);
  final String label;
  final String description;
  final String icon;
}

const _pageSize = 20;

/// `/pub`: every published package by pub.dev metrics.
@client
class PubView extends StatefulComponent {
  const PubView({required this.index, required this.now, super.key});

  final IndexFile index;

  /// ISO timestamp of the data snapshot.
  final String now;

  @override
  State<PubView> createState() => _PubViewState();

  @css
  static List<StyleRule> get styles => [
    rule('.pub', {'display': 'flex', 'flex-direction': 'column', 'gap': '24px'}),
    rule('.pub-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '16px',
      'align-items': 'flex-end',
      'justify-content': 'space-between',
    }),
    rule('.pub-head > div:first-child', {'display': 'flex', 'flex-direction': 'column', 'gap': '8px'}),
    rule('.pub-heading', {'display': 'flex', 'align-items': 'center', 'gap': '12px'}),
    rule('.pub-logo', {
      'width': '36px',
      'height': '36px',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'background': '#fff url(https://pub.dev/favicon.ico) center/22px no-repeat',
      'flex-shrink': '0',
    }),
    rule('.pub-tabs', {'grid-template-columns': 'repeat(5,minmax(0,1fr))'}),
    rule('.pub-tabs > button', {
      'padding': '18px 20px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '4px',
      'cursor': 'pointer',
      'background': 'var(--bg)',
      'color': 'var(--ink)',
      'border-top': '0',
      'border-left': '0',
      'text-align': 'left',
      'font': 'inherit',
    }),
    rule('.pub-tabs > button.on', {
      'background': 'var(--surface)',
      'color': 'var(--accent)',
      'box-shadow': 'inset 0 -2px 0 var(--accent)',
    }),
    rule('.pub-tab-title', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'font-size': '14px',
      'font-weight': '600',
    }),
    rule('.pub-tab-desc', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.pub-more', {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': '12px',
      'padding': '8px 0 16px',
    }),
    rule('.pub-more > span', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.pub-progress', {
      'width': '200px',
      'height': '3px',
      'background': 'var(--surface2)',
      'border-radius': '999px',
      'overflow': 'hidden',
    }),
    rule('.pub-progress > div', {
      'height': '100%',
      'background': 'var(--accent)',
      'border-radius': '999px',
      'transition': 'width .3s ease',
    }),
    below(860, [
      rule('.pub-tabs', {'grid-template-columns': '1fr'}),
    ]),
  ];
}

class _PubViewState extends State<PubView> {
  String _sdk = 'All';
  _Tab _tab = _Tab.downloads;
  int _shown = _pageSize;

  List<ProjectRow> _rows(DateTime now) {
    final published = component.index.projects.where(
      (r) => r.isPublished && (_sdk == 'All' || r.sdk == _sdk) && (_tab != _Tab.favorites || r.flutterFavorite),
    );
    return switch (_tab) {
      _Tab.downloads => sortedBy(published, (r) => r.downloads),
      _Tab.likes => sortedBy(published, (r) => r.likes),
      _Tab.points => sortedBy(published, (r) => (r.points ?? 0) * 1e6 + (r.likes ?? 0)),
      _Tab.recent => sortedBy(published, (r) => -(daysSince(r.released, now) ?? 1 << 30)),
      _Tab.favorites => sortedBy(published, (r) => r.likes),
    };
  }

  @override
  Component build(BuildContext context) {
    final now = DateTime.parse(component.now);
    final rows = _rows(now);
    final shown = rows.length < _shown ? rows.length : _shown;
    return div(classes: 'pub', [
      div(classes: 'pub-head', [
        div([
          div(classes: 'pub-heading', [
            span(classes: 'pub-logo', []),
            h1(classes: 'page-title', [.text('pub.dev packages')]),
          ]),
          p(classes: 'lede', [.text('Likes, pub points and downloads for every published Dart & Flutter package.')]),
        ]),
        SegControl<String>(
          label: 'SDK',
          options: const [('All', 'All'), ('Flutter', 'Flutter'), ('Dart', 'Dart')],
          selected: _sdk,
          onSelect: (value) => setState(() {
            _sdk = value;
            _shown = _pageSize;
          }),
        ),
      ]),
      div(
        classes: 'cell-grid pub-tabs',
        attributes: {'role': 'tablist'},
        [
          for (final t in _Tab.values)
            button(
              classes: t == _tab ? 'on' : null,
              type: ButtonType.button,
              attributes: {'role': 'tab', 'aria-selected': '${t == _tab}'},
              onClick: () => setState(() {
                _tab = t;
                _shown = _pageSize;
              }),
              [
                div(classes: 'pub-tab-title', [
                  Icon(t.icon, size: 15),
                  span([.text(t.label)]),
                ]),
                span(classes: 'pub-tab-desc', [.text(t.description)]),
              ],
            ),
        ],
      ),
      div(classes: 'panel', [
        for (final (i, r) in rows.take(shown).indexed) PubRow(row: r, rank: i + 1, now: now),
      ]),
      div(classes: 'pub-more', [
        span([.text('Showing $shown of ${rows.length} packages')]),
        div(classes: 'pub-progress', [
          div(styles: Styles(raw: {'width': '${rows.isEmpty ? 0 : shown / rows.length * 100}%'}), []),
        ]),
        if (shown < rows.length)
          button(
            classes: 'btn',
            type: ButtonType.button,
            styles: Styles(raw: {'margin-top': '4px', 'padding': '0 24px'}),
            onClick: () => setState(() => _shown += _pageSize),
            [.text('Load more'), const Icon(Icons.chevronDown, size: 14, strokeWidth: 1.6)],
          ),
      ]),
    ]);
  }
}
