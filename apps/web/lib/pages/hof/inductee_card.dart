import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/project_logo.dart';
import '../../data/view.dart';
import '../../styles/css.dart';
import 'hof_search.dart';

/// A Hall of Fame project with its award and the editors' reasoning.
class InducteeCard extends StatelessComponent {
  const InducteeCard({required this.entry, required this.row, super.key});

  final HallOfFameProject entry;
  final ProjectRow row;

  @override
  Component build(BuildContext context) {
    final r = row;
    final stat = r.stars != null
        ? '${compactNumber(r.stars)} stars'
        : (r.isPublished ? '${compactNumber(r.downloads)} dl/30d' : '');
    return div(
      classes: 'inductee',
      attributes: {
        'data-hof': hofSearchText([r.name, r.id, r.repo, r.owner, entry.category]),
      },
      [
        div(classes: 'inductee-top', [
          span(classes: 'eyebrow warn', styles: Styles(raw: {'font-size': '12px'}), [.text(entry.category)]),
          span(classes: 'inductee-kind', [.text(r.kind == ProjectKind.package ? 'Package' : 'Project')]),
        ]),
        div(classes: 'inductee-id', [
          ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl),
          div(classes: 'inductee-name', [
            span([.text(r.name)]),
            span(classes: 'muted', [.text(r.owner ?? '')]),
          ]),
        ]),
        p(classes: 'inductee-reason', [.text('“${entry.reason}”')]),
        div(classes: 'inductee-foot', [
          span(classes: 'inductee-stat', [.text(stat)]),
          a(href: r.path, classes: 'link-more', [.text('View →')]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.inductee', {'padding': '24px', 'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.inductee-top', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'center',
      'gap': '8px',
    }),
    rule('.inductee-kind', {'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
    rule('.inductee-id', {'display': 'flex', 'gap': '12px', 'align-items': 'center'}),
    rule('.inductee-name', {'display': 'flex', 'flex-direction': 'column'}),
    rule('.inductee-name > span:first-child', {'font-size': '18px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.inductee-name .muted', {'font-size': '13px'}),
    rule('.inductee-reason', {'font-size': '15px', 'line-height': '1.55', 'text-wrap': 'pretty'}),
    rule('.inductee-foot', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'center',
      'margin-top': 'auto',
      'padding-top': '6px',
    }),
    rule('.inductee-stat', {'font': mono(13, weight: 400), 'color': 'var(--muted)'}),
  ];
}
