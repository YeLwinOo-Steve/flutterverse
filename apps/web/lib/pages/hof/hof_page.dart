import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/site_data.dart';
import '../../styles/css.dart';
import 'developer_card.dart';
import 'hof_pager.dart';
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
    final inductees = [
      for (final e in edition?.projects ?? const <HallOfFameProject>[])
        if (data.row(e.id) case final row?) (e, row),
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
        'developers',
        'Developers',
        'People whose work the ecosystem is built on.',
        button(
          classes: 'btn primary',
          type: ButtonType.button,
          attributes: {'data-open-modal': 'propose-developer'},
          [const Icon(Icons.personAdd), .text('Propose a developer')],
        ),
      ),
      _grid('developers', 'dev-grid', _devsPerPage, [
        for (final (i, d) in developers.indexed)
          DeveloperCard(
            developer: d,
            projects: [for (final id in d.projects) ?data.row(id)],
            hidden: i >= _devsPerPage,
          ),
      ]),
      _sectionHead(
        'projects',
        'Projects',
        'Work with lasting influence on how Flutter software is built.',
        button(
          classes: 'btn',
          type: ButtonType.button,
          attributes: {'data-open-modal': 'propose-project'},
          [const Icon(Icons.folderAdd), .text('Propose a project')],
        ),
      ),
      _grid('projects', 'cell-grid inductees', _projectsPerPage, [
        for (final (i, (e, row)) in inductees.indexed) InducteeCard(entry: e, row: row, hidden: i >= _projectsPerPage),
      ]),
    ]);
  }

  /// Three rows of developer cards, five of project cards (on desktop).
  static const _devsPerPage = 9;
  static const _projectsPerPage = 10;

  /// A card grid of [section], [perPage] cards at a time, with its pager
  /// and the empty state [HofSearch] shows when nothing in it matches.
  /// Cards past the first page come pre-rendered but hidden.
  Component _grid(String section, String classes, int perPage, List<Component> cards) => div(classes: 'hof-section', [
    div(classes: classes, attributes: {'data-hof-grid': section, 'data-page-size': '$perPage'}, cards),
    div(
      classes: 'empty',
      attributes: {'data-hof-empty': '', 'hidden': ''},
      [
        b([.text('No matches')]),
        span([.text('Try a different name or handle.')]),
      ],
    ),
    HofPager(section: section, total: cards.length, pageSize: perPage),
  ]);

  /// [id] is where [HofPager] scrolls to on a new page.
  Component _sectionHead(String id, String title, String subtitle, Component action) =>
      div(id: 'hof-$id', classes: 'hof-section-head', [
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
    rule('.hof-section-head', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '16px',
      'flex-wrap': 'wrap',
      // Clear of the sticky header when a pager scrolls here.
      'scroll-margin-top': '88px',
    }),
    rule('.hof-section', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px'}),
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
