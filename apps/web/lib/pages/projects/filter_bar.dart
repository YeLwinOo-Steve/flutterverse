import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/listing.dart';
import '../../styles/css.dart';

const _platforms = ['iOS', 'Android', 'Web', 'WASM', 'macOS', 'Windows', 'Linux'];
const _starOptions = [
  (0, 'Any stars'),
  (-1000, '< 1k stars'),
  (1000, '1k+ stars'),
  (5000, '5k+ stars'),
  (10000, '10k+ stars'),
  (50000, '50k+ stars'),
];
const _pointOptions = [(0, 'Any pub points'), (140, '140+ points'), (160, '160 points')];

/// The listing's filter and sort controls.
class FilterBar extends StatelessComponent {
  const FilterBar({
    required this.filters,
    required this.sort,
    required this.categories,
    required this.onFilters,
    required this.onSort,
    super.key,
  });

  final ListFilters filters;
  final String sort;

  /// Slug → label of categories that have projects.
  final Map<String, String> categories;
  final void Function(ListFilters) onFilters;
  final void Function(String) onSort;

  Component _select<T>(String label, T value, List<(T, String)> options, void Function(T) onPick) => select(
    classes: 'select',
    attributes: {'aria-label': label},
    onChange: (v) => onPick(options.firstWhere((o) => '${o.$1}' == v.first).$1),
    [
      for (final (v, text) in options) option(value: '$v', selected: v == value, [.text(text)]),
    ],
  );

  @override
  Component build(BuildContext context) {
    final f = filters;
    return div(classes: 'filter-bar', [
      _select('SDK', f.sdk, const [
        ('Any', 'Dart + Flutter'),
        ('Dart', 'Dart'),
        ('Flutter', 'Flutter'),
      ], (v) => onFilters(f.copyWith(sdk: v))),
      _select('Category', f.category, [
        ('All', 'All categories'),
        for (final e in categories.entries) (e.key, e.value),
      ], (v) => onFilters(f.copyWith(category: v))),
      _select('Platform', f.platform, [
        ('All', 'All platforms'),
        for (final p in _platforms) (p, p),
      ], (v) => onFilters(f.copyWith(platform: v))),
      _select('Minimum stars', f.minStars, _starOptions, (v) => onFilters(f.copyWith(minStars: v))),
      _select('Minimum pub points', f.minPoints, _pointOptions, (v) => onFilters(f.copyWith(minPoints: v))),
      button(
        classes: f.activeOnly ? 'chip on active-chip' : 'chip active-chip',
        type: ButtonType.button,
        attributes: {'aria-pressed': '${f.activeOnly}'},
        onClick: () => onFilters(f.copyWith(activeOnly: !f.activeOnly)),
        [.text('Actively maintained')],
      ),
      label(classes: 'filter-sort', [
        .text('Sort'),
        _select('Sort', sort, [for (final s in listSorts) (s.label, s.label)], onSort),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.filter-bar', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '8px',
      'align-items': 'center',
      'padding': '12px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
    }),
    rule('.active-chip', {
      'height': '38px',
      'padding': '0 14px',
      'font-size': '14px',
      'display': 'flex',
      'align-items': 'center',
    }),
    rule('.filter-sort', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'font-size': '13px',
      'color': 'var(--muted)',
    }),
  ];
}
