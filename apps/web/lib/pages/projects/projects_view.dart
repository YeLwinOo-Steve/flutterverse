import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/project_table.dart';
import '../../components/project/table_extras.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/listing.dart';
import '../../styles/css.dart';
import 'filter_bar.dart';

/// `/projects`: every tracked project with filters. `?cat=`, `?owner=`,
/// `?sort=` and `?q=` deep-link into it.
@client
class ProjectsView extends StatefulComponent {
  const ProjectsView({required this.index, required this.now, super.key});

  final IndexFile index;

  /// ISO timestamp of the data snapshot.
  final String now;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();

  @css
  static List<StyleRule> get styles => [
    rule('.list-head', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px', 'margin-bottom': '16px'}),
    rule('.list-title-row', {'display': 'flex', 'align-items': 'center', 'gap': '16px', 'flex-wrap': 'wrap'}),
    rule('.list-title', {
      'display': 'flex',
      'align-items': 'baseline',
      'gap': '12px',
      'flex-wrap': 'wrap',
      'flex': '1',
      'min-width': '240px',
    }),
    rule('.list-count', {'font': mono(13), 'color': 'var(--muted)'}),
    rule('.owner-filter', {'display': 'flex', 'gap': '8px', 'align-items': 'center', 'font-size': '14px'}),
    rule('.owner-filter button', {
      'font': mono(13),
      'padding': '4px 8px',
      'background': 'var(--ink)',
      'color': 'var(--bg)',
      'border-radius': '2px',
      'cursor': 'pointer',
      'border': '0',
    }),
    rule('.list-foot', {'display': 'flex', 'justify-content': 'center', 'padding': '20px 0 4px'}),
    rule('.list-foot span', {'font-size': '13px', 'color': 'var(--muted)'}),
  ];
}

class _ProjectsViewState extends State<ProjectsView> {
  ListFilters _filters = const ListFilters();
  String _sort = listSorts.first.label;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    final q = Uri.base.queryParameters;
    _filters = ListFilters(category: q['cat'] ?? 'All', owner: q['owner'], query: q['q'] ?? '');
    _sort = listSortNamed(q['sort'] ?? _sort).label;
  }

  @override
  Component build(BuildContext context) {
    final index = component.index;
    final now = DateTime.parse(component.now);
    final sort = listSortNamed(_sort);
    final rows = [
      for (final r in index.projects)
        if (_filters.matches(r, index.categories)) r,
    ]..sort((x, y) => (sort.score(y, now) ?? -1 << 40).compareTo(sort.score(x, now) ?? -1 << 40));
    final used = {for (final r in index.projects) ...r.categories};

    return div([
      div(classes: 'list-head', [
        div(classes: 'list-title-row', [
          div(classes: 'list-title', [
            h1(classes: 'page-title', [.text('Flutter & Dart projects')]),
            span(classes: 'list-count', [.text('${rows.length} results')]),
          ]),
          a(href: '/categories', classes: 'btn', [
            const Icon(Icons.grid, strokeWidth: 1.4),
            .text('Browse by category'),
          ]),
        ]),
        FilterBar(
          filters: _filters,
          sort: _sort,
          categories: {
            for (final e in index.categories.entries)
              if (used.contains(e.key)) e.key: e.value,
          },
          onFilters: (f) => setState(() => _filters = f),
          onSort: (value) => setState(() => _sort = value),
        ),
        if (_filters.owner != null)
          div(classes: 'owner-filter', [
            .text('Author: '),
            button(
              type: ButtonType.button,
              onClick: () => setState(() => _filters = _filters.copyWith(owner: () => null)),
              [.text('${_filters.owner} ×')],
            ),
          ]),
      ]),
      if (rows.isEmpty)
        div(classes: 'empty', [
          b([.text('No projects match these filters')]),
          span([.text('Try widening the category, platform or minimum stars.')]),
          button(
            classes: 'btn small',
            type: ButtonType.button,
            styles: Styles(raw: {'margin-top': '8px'}),
            onClick: () => setState(() => _filters = const ListFilters()),
            [.text('Reset filters')],
          ),
        ])
      else
        ProjectTable(
          rows: [for (final r in rows) (row: r, signal: sort.signal(r, now))],
          categories: index.categories,
          signalHead: sort.signalHead(),
        ),
      div(classes: 'list-foot', [
        span([.text('Showing ${rows.length} of ${index.projects.length} projects')]),
      ]),
      const TableLegend(),
    ]);
  }
}
