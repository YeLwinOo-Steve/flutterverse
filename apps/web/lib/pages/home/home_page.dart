import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/ranking.dart';
import '../../data/site_data.dart';
import '../../data/view.dart';
import '../../styles/css.dart';
import 'hof_preview.dart';
import 'home_hero.dart';
import 'side_list.dart';
import 'trending_card.dart';

const _notEnoughHistory = 'Needs a few weeks of daily snapshots.';

/// `/`.
class HomePage extends StatelessComponent {
  const HomePage(this.data, {super.key});

  final SiteData data;

  @override
  Component build(BuildContext context) {
    final rows = data.index.projects;
    final edition = data.hallOfFame.edition;
    final now = data.now;

    final rising = sortedBy(
      rows.where((r) => r.stars != null && r.stars! < 3000 && r.growth30 != null),
      (r) => r.growth30,
    ).take(4);
    final gems = sortedBy(rows.where((r) => isHiddenGem(r) && r.momentum != null), (r) => r.momentum).take(4);
    final recent = sortedBy(rows.where((r) => r.released != null), (r) => -daysSince(r.released, now)!).take(4);

    return div(classes: 'home', [
      const HomeHero(),
      section(classes: 'home-main', [
        TrendingCard(index: data.index, now: now.toIso8601String()),
        div(classes: 'home-side', [
          SideList(
            title: 'Rising',
            items: [for (final r in rising) (r, '+${percent(r.growth30)}')],
            moreHref: '/rankings?tab=rising',
            emptyText: _notEnoughHistory,
          ),
          SideList(
            title: 'Hidden gems',
            items: [for (final r in gems) (r, r.momentumLabel)],
            moreHref: '/rankings?tab=gems',
            emptyText: _notEnoughHistory,
          ),
          SideList(
            title: 'Recently released',
            items: [for (final r in recent) (r, 'v${r.version}')],
            moreHref: '/projects?sort=Recently+released',
          ),
        ]),
      ]),
      if (edition != null) HofPreview(edition: edition, names: {for (final r in rows) r.id: r.name}),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.home', {'display': 'flex', 'flex-direction': 'column', 'gap': '72px'}),
    rule('.home-main', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '24px', 'align-items': 'flex-start'}),
    rule('.home-side', {
      'flex': '1 1 300px',
      'min-width': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '16px',
    }),
  ];
}
