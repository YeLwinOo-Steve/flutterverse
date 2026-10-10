import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/table_extras.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../components/ui/pager.dart';
import '../../components/ui/seg_control.dart';
import '../../data/full_index.dart';
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

const _pageSize = 25;

/// `/pub`: every published package by pub.dev metrics, a page at a time.
@client
class PubView extends StatefulComponent {
  const PubView({required this.index, required this.total, required this.now, super.key});

  /// A preview: the first page of the default tab. The full index loads in
  /// the browser.
  final IndexFile index;

  /// How many published packages there are in all.
  final int total;

  /// ISO timestamp of the data snapshot.
  final String now;

  @override
  State<PubView> createState() => _PubViewState();

  /// The rows [index]'s preview needs.
  static List<ProjectRow> previewRows(IndexFile index, DateTime now) =>
      _rows(index, 'All', _Tab.downloads, now).take(_pageSize).toList();

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
    // Flutter Favorites is special, so it wears Flutter's blue.
    rule('.pub-tabs > button.ff', {'background': '#0175C2', 'color': '#FFFFFF'}),
    rule('.pub-tabs > button.ff:hover', {'background': '#0168AE'}),
    rule('.pub-tabs > button.ff.on', {'box-shadow': 'inset 0 -2px 0 #FFFFFF'}),
    rule('.pub-tabs > button.ff .pub-tab-desc', {'color': 'rgba(255,255,255,.82)'}),
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
    below(860, [
      rule('.pub-tabs', {'grid-template-columns': '1fr'}),
    ]),
  ];
}

List<ProjectRow> _rows(IndexFile index, String sdk, _Tab tab, DateTime now) {
  final published = index.projects.where(
    (r) => r.isPublished && (sdk == 'All' || r.sdk == sdk) && (tab != _Tab.favorites || r.flutterFavorite),
  );
  return switch (tab) {
    _Tab.downloads => sortedBy(published, (r) => r.downloads),
    _Tab.likes => sortedBy(published, (r) => r.likes),
    _Tab.points => sortedBy(published, (r) => (r.points ?? 0) * 1e6 + (r.likes ?? 0)),
    _Tab.recent => sortedBy(published, (r) => -(daysSince(r.released, now) ?? 1 << 30)),
    _Tab.favorites => sortedBy(published, (r) => r.likes),
  };
}

class _PubViewState extends State<PubView> with FullIndex {
  String _sdk = 'All';
  _Tab _tab = _Tab.downloads;
  int _page = 0;

  @override
  IndexFile get preview => component.index;

  @override
  Component build(BuildContext context) {
    final now = DateTime.parse(component.now);
    final ready = loaded || (_sdk == 'All' && _tab == _Tab.downloads && _page == 0);
    final rows = _rows(index, _sdk, _tab, now);
    final count = loaded ? rows.length : component.total;
    final first = _page * _pageSize;
    final page = rows.skip(first).take(_pageSize).toList();
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
            _page = 0;
          }),
        ),
      ]),
      div(
        classes: 'cell-grid pub-tabs',
        attributes: {'role': 'tablist'},
        [
          for (final t in _Tab.values)
            button(
              classes: [if (t == _tab) 'on', if (t == _Tab.favorites) 'ff'].join(' '),
              type: ButtonType.button,
              attributes: {'role': 'tab', 'aria-selected': '${t == _tab}'},
              onClick: () => setState(() {
                _tab = t;
                _page = 0;
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
      if (!ready)
        const TableEmpty(title: 'Loading every package…', message: 'This takes a moment on the first visit.')
      else
        div(classes: 'panel', [
          for (final (i, r) in page.indexed) PubRow(row: r, rank: first + i + 1, now: now),
        ]),
      if (ready) Pager(page: _page, pages: (count / _pageSize).ceil(), onPage: (n) => setState(() => _page = n)),
      div(classes: 'pub-more', [
        span([
          .text(
            count == 0 ? 'No packages' : 'Showing ${first + 1}–${first + page.length} of ${groupedNumber(count)} packages',
          ),
        ]),
      ]),
    ]);
  }
}
