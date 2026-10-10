import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/project_table.dart';
import '../../components/project/table_extras.dart';
import '../../components/ui/seg_control.dart';
import '../../components/ui/pager.dart';
import '../../data/full_index.dart';
import '../../data/listing.dart';
import '../../data/ranking.dart';
import '../../styles/css.dart';

/// `/rankings`: one table per ranking, switched by chips, a page at a time.
/// `?tab=` deep-links.
@client
class RankingsView extends StatefulComponent {
  const RankingsView({required this.index, super.key});

  /// A preview: the first page of the first ranking. The full index loads
  /// in the browser.
  final IndexFile index;

  @override
  State<RankingsView> createState() => _RankingsViewState();

  /// The rows [index]'s preview needs.
  static List<ProjectRow> previewRows(IndexFile index) => ranks.first.apply(index.projects).take(listPageSize).toList();

  @css
  static List<StyleRule> get styles => [
    rule('.rankings-head', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px', 'margin-bottom': '16px'}),
    rule('.rankings-desc', {'font-size': '14px', 'color': 'var(--muted)', 'text-wrap': 'pretty'}),
  ];
}

class _RankingsViewState extends State<RankingsView> with FullIndex {
  Rank _rank = ranks.first;
  int _page = 0;

  @override
  IndexFile get preview => component.index;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final tab = Uri.base.queryParameters['tab'];
      _rank = ranks.firstWhere((r) => r.key == tab, orElse: () => ranks.first);
    }
  }

  @override
  Component build(BuildContext context) {
    final ready = loaded || (_rank == ranks.first && _page == 0);
    final rows = _rank.apply(index.projects);
    final page = rows.skip(_page * listPageSize).take(listPageSize).toList();
    // Growth rankings stay empty until enough daily snapshots exist.
    final waiting = _rank.calculated && rows.every((r) => _rank.score(r) == null);
    return div([
      div(classes: 'rankings-head', [
        h1(classes: 'page-title', [.text('Rankings')]),
        ChipTabs<Rank>(
          options: [for (final r in ranks) (r, r.label)],
          selected: _rank,
          onSelect: (r) => setState(() {
            _rank = r;
            _page = 0;
          }),
        ),
        span(classes: 'rankings-desc', [.text(_rank.description)]),
      ]),
      if (!ready)
        const TableEmpty(title: 'Loading every project…', message: 'This takes a moment on the first visit.')
      else if (rows.isEmpty || waiting)
        const TableEmpty(
          title: 'Not enough history yet',
          message: 'This ranking needs daily snapshots to build up. Check back in a few days.',
        )
      else
        ProjectTable(
          rows: [for (final r in page) (row: r, signal: _rank.signal(r))],
          categories: index.categories,
          signalHead: _rank.head,
          rankFrom: _page * listPageSize + 1,
        ),
      if (ready && loaded && !waiting)
        Pager(page: _page, pages: (rows.length / listPageSize).ceil(), onPage: (n) => setState(() => _page = n)),
      const TableLegend(),
    ]);
  }
}
