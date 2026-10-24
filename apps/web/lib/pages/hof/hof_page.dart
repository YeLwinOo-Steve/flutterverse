import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/site_data.dart';
import '../../styles/css.dart';
import 'developer_card.dart';
import 'hof_search.dart';
import 'inductee_card.dart';

/// `/hall-of-fame`. The propose buttons open dialogs hosted by
/// `Nominations`.
class HofPage extends StatelessComponent {
  const HofPage(this.data, {super.key});

  final SiteData data;

  @override
  Component build(BuildContext context) {
    final edition = data.hallOfFame.edition;
    // Those honored in memory come first.
    final developers = [
      for (final d in edition?.developers ?? const <HallOfFameDeveloper>[])
        if (d.memorial) d,
      for (final d in edition?.developers ?? const <HallOfFameDeveloper>[])
        if (!d.memorial) d,
    ];
    return div(classes: 'hof', [
      div(classes: 'hof-head', [
        div(classes: 'hof-intro', [
          span(classes: 'eyebrow wide warn', styles: Styles(raw: {'font-size': '12px'}), [.text('Editorial')]),
          h1(classes: 'page-title', [.text('Flutterverse Hall of Fame')]),
          p(classes: 'lede', [
            .text(
              'Not a leaderboard. Developers and projects chosen for lasting influence on how Dart & Flutter software '
              'is built — with the reasoning on record.',
            ),
          ]),
        ]),
        const HofSearch(),
      ]),
      _sectionHead(
        'Developers',
        'People whose work the ecosystem is built on.',
        button(
          classes: 'btn primary',
          type: ButtonType.button,
          attributes: {'data-open-modal': 'propose-developer'},
          [const Icon(Icons.personAdd), .text('Propose a developer')],
        ),
      ),
      _grid('dev-grid', [
        for (final d in developers) DeveloperCard(developer: d, projects: [for (final id in d.projects) ?data.row(id)]),
      ]),
      _sectionHead(
        'Projects',
        'Work with lasting influence on how Flutter software is built.',
        button(
          classes: 'btn',
          type: ButtonType.button,
          attributes: {'data-open-modal': 'propose-project'},
          [const Icon(Icons.folderAdd), .text('Propose a project')],
        ),
      ),
      _grid('cell-grid inductees', [
        for (final e in edition?.projects ?? const <HallOfFameProject>[])
          if (data.row(e.id) case final row?) InducteeCard(entry: e, row: row),
      ]),
    ]);
  }

  /// A card grid plus the empty state [HofSearch] shows when nothing in it
  /// matches.
  Component _grid(String classes, List<Component> cards) => div([
    div(classes: classes, attributes: {'data-hof-grid': ''}, cards),
    div(
      classes: 'empty',
      attributes: {'data-hof-empty': '', 'hidden': ''},
      [
        b([.text('No matches')]),
        span([.text('Try a different name or handle.')]),
      ],
    ),
  ]);

  Component _sectionHead(String title, String subtitle, Component action) => div(classes: 'hof-section-head', [
    div([
      h2(classes: 'section-title', [.text(title)]),
      span(classes: 'muted', [.text(subtitle)]),
    ]),
    action,
  ]);

  @css
  static List<StyleRule> get styles => [
    rule('.hof', {'display': 'flex', 'flex-direction': 'column', 'gap': '24px'}),
    rule('.hof-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '16px',
      'align-items': 'flex-end',
      'justify-content': 'space-between',
      'padding-bottom': '24px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.hof-intro', {'display': 'flex', 'flex-direction': 'column', 'gap': '8px', 'max-width': '640px'}),
    rule('.hof-section-head', {'display': 'flex', 'align-items': 'center', 'gap': '16px', 'flex-wrap': 'wrap'}),
    rule('.hof-section-head > div', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '4px',
      'flex': '1',
      'min-width': '240px',
    }),
    rule('.hof-section-head .muted', {'font-size': '14px'}),
    rule('.dev-grid', {
      'display': 'grid',
      'grid-template-columns': 'repeat(auto-fill,minmax(340px,1fr))',
      'gap': '16px',
    }),
    rule('.inductees', {'grid-template-columns': 'repeat(auto-fill,minmax(408px,1fr))'}),
    below(640, [
      rule('.dev-grid, .inductees', {'grid-template-columns': 'minmax(0,1fr)'}),
    ]),
  ];
}
