import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/project_table.dart';
import '../../components/project/table_extras.dart';
import '../../components/ui/seg_control.dart';
import '../../data/ranking.dart';
import '../../styles/css.dart';

/// `/rankings`: one table per ranking, switched by chips. `?tab=` deep-links.
@client
class RankingsView extends StatefulComponent {
  const RankingsView({required this.index, super.key});

  final IndexFile index;

  @override
  State<RankingsView> createState() => _RankingsViewState();

  @css
  static List<StyleRule> get styles => [
    rule('.rankings-head', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px', 'margin-bottom': '16px'}),
    rule('.rankings-desc', {'font-size': '14px', 'color': 'var(--muted)', 'text-wrap': 'pretty'}),
  ];
}

class _RankingsViewState extends State<RankingsView> {
  Rank _rank = ranks.first;

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
    final rows = _rank.apply(component.index.projects);
    // Growth rankings stay empty until enough daily snapshots exist.
    final waiting = _rank.calculated && rows.every((r) => _rank.score(r) == null);
    return div([
      div(classes: 'rankings-head', [
        h1(classes: 'page-title', [.text('Rankings')]),
        ChipTabs<Rank>(
          options: [for (final r in ranks) (r, r.label)],
          selected: _rank,
          onSelect: (r) => setState(() => _rank = r),
        ),
        span(classes: 'rankings-desc', [.text(_rank.description)]),
      ]),
      if (rows.isEmpty || waiting)
        const TableEmpty(
          title: 'Not enough history yet',
          message: 'This ranking needs daily snapshots to build up. Check back in a few days.',
        )
      else
        ProjectTable(
          rows: [for (final r in rows) (row: r, signal: _rank.signal(r))],
          categories: component.index.categories,
          signalHead: _rank.head,
        ),
      const TableLegend(),
    ]);
  }
}
