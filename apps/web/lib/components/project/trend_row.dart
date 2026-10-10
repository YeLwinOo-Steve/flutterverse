import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/view.dart';
import '../../styles/css.dart';
import '../ui/badges.dart';
import '../ui/project_logo.dart';
import '../ui/sparkline.dart';

/// A row in the home page's Trending list.
class TrendRow extends StatelessComponent {
  const TrendRow({
    required this.row,
    required this.rank,
    required this.categories,
    required this.growth,
    required this.growthLabel,
    super.key,
  });

  final ProjectRow row;
  final int rank;
  final Map<String, String> categories;

  /// Stars gained in the selected window.
  final int? growth;

  /// `today`, `this week` or `this month`.
  final String growthLabel;

  @override
  Component build(BuildContext context) {
    final r = row;
    return a(href: r.path, classes: 'trend-row hover-row', [
      span(classes: 'trend-rank', [.text('$rank')]),
      ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl),
      div(classes: 'trend-main', [
        div(classes: 'trend-title', [
          span(classes: 'trend-name', [.text(r.name)]),
          if (r.owner != null) span(classes: 'trend-owner', [.text('by ${r.owner}')]),
        ]),
        if (r.description != null) span(classes: 'trend-desc', [.text(r.description!)]),
        div(classes: 'trend-tags', [
          for (final c in r.categories.take(2)) categoryPill(categoryLabel(categories, c)),
          healthPill(r),
        ]),
      ]),
      div(classes: 'trend-stats', [
        div(classes: 'trend-stars', [
          span(classes: 'trend-stars-label', [.text(r.repoWideStars ? 'Repo stars' : 'GitHub stars')]),
          span(classes: 'trend-stars-value', [.text(compactNumber(r.shownStars))]),
          growthChip('${signedNumber(growth)} $growthLabel'),
        ]),
        Sparkline(r.spark),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.trend-row', {
      'display': 'grid',
      'grid-template-columns': '26px 40px minmax(0,1fr) auto',
      'gap': '16px',
      'align-items': 'center',
      'padding': '20px 24px',
      'border-bottom': '1px solid var(--line)',
      'color': 'var(--ink)',
    }),
    rule('.trend-row:hover', {'color': 'var(--ink)'}),
    rule('.trend-rank', {'font': mono(13), 'color': 'var(--muted)', 'padding-top': '8px'}),
    rule('.trend-main', {'display': 'flex', 'flex-direction': 'column', 'gap': '8px', 'min-width': '0'}),
    rule('.trend-title', {'display': 'flex', 'align-items': 'center', 'gap': '10px', 'flex-wrap': 'wrap'}),
    rule('.trend-name', {'font-size': '16px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.trend-owner', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.trend-desc', {
      'font-size': '14px',
      'color': 'var(--muted)',
      'line-height': '1.5',
      'display': '-webkit-box',
      '-webkit-line-clamp': '2',
      '-webkit-box-orient': 'vertical',
      'overflow': 'hidden',
    }),
    rule('.trend-tags', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '6px',
      'align-items': 'center',
      'margin-top': '2px',
    }),
    rule('.trend-stats', {'display': 'flex', 'gap': '24px', 'align-items': 'center'}),
    rule('.trend-stars', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '4px',
      'align-items': 'flex-end',
      'min-width': '96px',
    }),
    rule('.trend-stars-label', {'font-size': '12px', 'color': 'var(--muted)'}),
    rule('.trend-stars-value', {
      'font-size': '20px',
      'font-weight': '600',
      'letter-spacing': '-0.02em',
      'font-variant-numeric': 'tabular-nums',
    }),
    below(640, [
      rule('.trend-row', {'grid-template-columns': '20px 40px minmax(0,1fr)', 'padding': '16px'}),
      rule('.trend-stats', {'grid-column': '3'}),
    ]),
  ];
}
