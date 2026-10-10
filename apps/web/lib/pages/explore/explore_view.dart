import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/seg_control.dart';
import '../../data/ranking.dart';
import '../../styles/css.dart';
import 'category_card.dart';

/// `/categories`: every category as a card, filterable by group.
@client
class ExploreView extends StatefulComponent {
  const ExploreView({required this.index, required this.counts, required this.growth, super.key});

  /// Only each category's leaders (see [summarize]).
  final IndexFile index;

  /// Category slug → how many projects it has.
  final Map<String, int> counts;

  /// Category slug → stars gained over 30 days; missing without history.
  final Map<String, int> growth;

  @override
  State<ExploreView> createState() => _ExploreViewState();

  /// The cards' data out of the full [index]: each category's leaders (as an
  /// index preview), counts and 30-day growth.
  static ExploreView summarize(IndexFile index) {
    final leaders = <ProjectRow>{};
    final counts = <String, int>{};
    final growth = <String, int>{};
    for (final slug in index.categories.keys) {
      final rows = [
        for (final r in index.projects)
          if (r.categories.contains(slug)) r,
      ];
      counts[slug] = rows.length;
      leaders.addAll(sortedBy(rows, (r) => r.stars).take(CategoryCard.shownLeaders));
      if (rows.any((r) => r.stars30d != null)) growth[slug] = rows.fold(0, (sum, r) => sum + (r.stars30d ?? 0));
    }
    return ExploreView(
      index: IndexFile(categories: index.categories, categoryGroups: index.categoryGroups, projects: leaders.toList()),
      counts: counts,
      growth: growth,
    );
  }

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
    final counts = component.counts;
    List<ProjectRow> leaders(String slug) => sortedBy(
      index.projects.where((r) => r.categories.contains(slug)),
      (r) => r.stars,
    ).take(CategoryCard.shownLeaders).toList();
    final cards = slugs.toList()..sort((x, y) => ((counts[y] ?? 0) > 0 ? 1 : 0) - ((counts[x] ?? 0) > 0 ? 1 : 0));

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
        for (final slug in cards)
          CategoryCard(
            slug: slug,
            label: index.categories[slug] ?? slug,
            count: counts[slug] ?? 0,
            leaders: leaders(slug),
            growth: component.growth[slug],
          ),
      ]),
    ]);
  }
}
