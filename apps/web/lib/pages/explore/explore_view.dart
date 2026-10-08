import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/seg_control.dart';
import '../../styles/css.dart';
import 'category_card.dart';

/// `/categories`: every category as a card, filterable by group.
@client
class ExploreView extends StatefulComponent {
  const ExploreView({required this.index, super.key});

  final IndexFile index;

  @override
  State<ExploreView> createState() => _ExploreViewState();

  @css
  static List<StyleRule> get styles => [
    rule('.explore', {'display': 'flex', 'flex-direction': 'column', 'gap': '32px'}),
    rule('.explore-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '24px',
      'align-items': 'flex-end',
      'justify-content': 'space-between',
      'padding-bottom': '28px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.explore-head > div', {'display': 'flex', 'flex-direction': 'column', 'gap': '10px', 'max-width': '640px'}),
    rule('.explore-grid', {
      'display': 'grid',
      'grid-template-columns': 'repeat(auto-fill,minmax(300px,1fr))',
      'gap': '16px',
    }),
  ];
}

class _ExploreViewState extends State<ExploreView> {
  String _group = 'All';

  @override
  Component build(BuildContext context) {
    final index = component.index;
    final groups = {'All': index.categories.keys.toList(), ...index.categoryGroups};
    final slugs = groups[_group] ?? groups['All']!;
    List<ProjectRow> inCat(String slug) => [
      for (final r in index.projects)
        if (r.categories.contains(slug)) r,
    ];
    final cards = [for (final s in slugs) (s, inCat(s))]
      ..sort((x, y) => (y.$2.isNotEmpty ? 1 : 0) - (x.$2.isNotEmpty ? 1 : 0));

    return div(classes: 'explore', [
      div(classes: 'explore-head', [
        div([
          h1(classes: 'page-title', [.text('Explore by category')]),
          p(classes: 'lede', [.text("See who leads, who's climbing and what's new in every corner of the ecosystem.")]),
        ]),
        a(href: '/projects', classes: 'btn', [.text('View all packages & projects')]),
      ]),
      ChipTabs<String>(
        options: [for (final g in groups.keys) (g, g)],
        selected: _group,
        onSelect: (g) => setState(() => _group = g),
        trailing: (g) => '${groups[g]!.length}',
      ),
      div(classes: 'explore-grid', [
        for (final (slug, rows) in cards) CategoryCard(slug: slug, label: index.categories[slug] ?? slug, rows: rows),
      ]),
    ]);
  }
}
