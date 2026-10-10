import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/project_table.dart';
import '../../components/project/table_extras.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../components/ui/pager.dart';
import '../../data/full_index.dart';
import '../../data/listing.dart';
import '../../styles/css.dart';
import 'filter_bar.dart';

/// `/projects`: every tracked project with filters, a page at a time.
/// `?cat=`, `?owner=`, `?sort=` and `?q=` deep-link into it.
@client
class ProjectsView extends StatefulComponent {
  const ProjectsView({required this.index, required this.total, required this.now, super.key});

  /// A preview: the first page, unfiltered, in the default sort. The full
  /// index loads in the browser.
  final IndexFile index;

  /// How many projects there are in all.
  final int total;

  /// ISO timestamp of the data snapshot.
  final String now;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();

  /// The rows [index]'s preview needs.
  static List<ProjectRow> previewRows(IndexFile index, DateTime now) =>
      listRows(index, const ListFilters(), listSorts.first, now).take(listPageSize).toList();

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

class _ProjectsViewState extends State<ProjectsView> with FullIndex {
  ListFilters _filters = const ListFilters();
  String _sort = listSorts.first.label;
  int _page = 0;

  @override
  IndexFile get preview => component.index;

  /// The preview only covers the first page of the default view.
  bool get _initial => _filters.isDefault && _sort == listSorts.first.label && _page == 0;

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
    final now = DateTime.parse(component.now);
    final sort = listSortNamed(_sort);
    final ready = loaded || _initial;
    final rows = listRows(index, _filters, sort, now);
    final count = loaded ? rows.length : component.total;
    final pages = (count / listPageSize).ceil();
    final page = rows.skip(_page * listPageSize).take(listPageSize).toList();
    final used = loaded ? {for (final r in index.projects) ...r.categories} : index.categories.keys.toSet();

    return div([
      div(classes: 'list-head', [
        div(classes: 'list-title-row', [
          div(classes: 'list-title', [
            h1(classes: 'page-title', [.text('Flutter & Dart projects')]),
            span(classes: 'list-count', [.text('${groupedNumber(count)} results')]),
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
          onFilters: (f) => setState(() {
            _filters = f;
            _page = 0;
          }),
          onSort: (value) => setState(() {
            _sort = value;
            _page = 0;
          }),
        ),
        if (_filters.owner != null)
          div(classes: 'owner-filter', [
            .text('Author: '),
            button(
              type: ButtonType.button,
              onClick: () => setState(() {
                _filters = _filters.copyWith(owner: () => null);
                _page = 0;
              }),
              [.text('${_filters.owner} ×')],
            ),
          ]),
      ]),
      if (!ready)
        const TableEmpty(title: 'Loading every project…', message: 'This takes a moment on the first visit.')
      else if (rows.isEmpty)
        div(classes: 'empty', [
          b([.text('No projects match these filters')]),
          span([.text('Try widening the category, platform or minimum stars.')]),
          button(
            classes: 'btn small',
            type: ButtonType.button,
            styles: Styles(raw: {'margin-top': '8px'}),
            onClick: () => setState(() {
              _filters = const ListFilters();
              _page = 0;
            }),
            [.text('Reset filters')],
          ),
        ])
      else
        ProjectTable(
          rows: [for (final r in page) (row: r, signal: sort.signal(r, now))],
          categories: index.categories,
          signalHead: sort.signalHead(),
          rankFrom: _page * listPageSize + 1,
        ),
      if (ready) Pager(page: _page, pages: pages, onPage: (n) => setState(() => _page = n)),
      div(classes: 'list-foot', [
        span([
          .text(
            count == 0
                ? 'No projects'
                : 'Showing ${_page * listPageSize + 1}–${_page * listPageSize + page.length} of ${groupedNumber(count)} projects',
          ),
        ]),
      ]),
      const TableLegend(),
    ]);
  }
}
