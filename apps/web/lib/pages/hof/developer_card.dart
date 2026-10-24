import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';
import 'hof_filter.dart';

/// A Hall of Fame developer with their GitHub stats and best-known repos.
class DeveloperCard extends StatelessComponent {
  const DeveloperCard({required this.developer, required this.projects, this.hidden = false, super.key});

  final HallOfFameDeveloper developer;

  /// Rows for [HallOfFameDeveloper.projects] that are tracked.
  final List<ProjectRow> projects;

  /// Pre-rendered off its first page; `HofPager` shows it.
  final bool hidden;

  @override
  Component build(BuildContext context) {
    final d = developer;
    final stars = projects.fold<int>(0, (sum, row) => sum + (row.stars ?? 0));
    final likes = projects.fold<int>(0, (sum, row) => sum + (row.likes ?? 0));
    return div(
      classes: d.memorial ? 'dev-card memorial hover-border' : 'dev-card hover-border',
      attributes: {
        if (hidden) 'hidden': '',
        'data-hof': hofSearchText([
          d.name,
          d.handle,
          d.category,
          for (final p in projects) ...[p.id, p.name],
        ]),
      },
      [
        div(classes: 'dev-body', [
          div(classes: 'dev-top', [
            div(
              classes: 'dev-avatar',
              attributes: {'role': 'img', 'aria-label': d.name},
              styles: Styles(
                raw: {
                  'background':
                      'var(--surface2) url(https://github.com/${d.handle}.png?size=160) center/cover no-repeat',
                },
              ),
              [],
            ),
            span(classes: 'dev-cat', [.text(d.category)]),
          ]),
          div(classes: 'dev-id', [
            div(classes: 'dev-name', [
              span([.text(d.name)]),
              span(classes: 'dev-handle', [.text('@${d.handle}')]),
            ]),
            span(classes: 'dev-tagline', [.text(d.tagline)]),
          ]),
          div(classes: 'dev-stats', [
            _stat(Icons.people, compactNumber(d.followers), 'followers'),
            _stat(Icons.book, compactNumber(d.repos), 'repos'),
            // Packages in shared monorepos have no stars of their own.
            if (stars == 0 && likes > 0)
              _stat(Icons.heart, compactNumber(likes), 'likes')
            else
              _stat(Icons.star, compactNumber(stars), 'stars'),
          ]),
        ]),
        div(classes: 'dev-pinned', [
          for (final p in projects.take(2))
            a(href: '/p/${p.id}', classes: 'dev-pin hover-row', [
              const Icon(Icons.book, strokeWidth: 1.4, classes: 'muted'),
              div(classes: 'dev-pin-text', [
                // The repo's name, as GitHub pins show it, unless the repo is
                // a shared monorepo (no stars of its own).
                span(classes: 'dev-pin-name', [
                  .text(p.stars == null ? p.name : p.repo?.split('/').last ?? p.name),
                ]),
                span(classes: 'dev-pin-desc', [.text(p.description ?? '')]),
              ]),
              span(classes: 'dev-pin-stars', [
                if (p.stars == null && p.likes != null) ...[
                  const Icon(Icons.heart, size: 14, strokeWidth: 1.4),
                  .text(compactNumber(p.likes)),
                ] else ...[
                  const Icon(Icons.star, size: 14, strokeWidth: 1.4),
                  .text(compactNumber(p.stars)),
                ],
              ]),
            ]),
        ]),
        div(classes: 'dev-cta', [
          a(
            href: 'https://github.com/${d.handle}',
            target: Target.blank,
            attributes: {'rel': 'noopener'},
            [const Icon(Icons.github, filled: true), .text('View on GitHub')],
          ),
        ]),
      ],
    );
  }

  Component _stat(String icon, String value, String label) => span(classes: 'dev-stat', [
    Icon(icon, size: 15, strokeWidth: 1.4),
    b([.text(value)]),
    .text(label),
  ]);

  @css
  static List<StyleRule> get styles => [
    rule('.dev-card', {
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'display': 'flex',
      'flex-direction': 'column',
      'cursor': 'default',
    }),
    rule('.dev-body', {'padding': '24px', 'display': 'flex', 'flex-direction': 'column', 'gap': '20px'}),
    rule('.dev-top', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'flex-start',
      'gap': '12px',
    }),
    rule('.dev-avatar', {
      'width': '64px',
      'height': '64px',
      'border-radius': '50%',
      'flex-shrink': '0',
      'box-shadow': '0 0 0 1px var(--line)',
    }),
    rule('.dev-cat', {
      'font': mono(11),
      'letter-spacing': '0.06em',
      'text-transform': 'uppercase',
      'padding': '5px 10px',
      'border-radius': '999px',
      'background': 'var(--accent-soft)',
      'color': 'var(--accent)',
      'white-space': 'nowrap',
    }),
    rule('.dev-id', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px'}),
    rule('.dev-name', {'display': 'flex', 'align-items': 'baseline', 'gap': '8px', 'flex-wrap': 'wrap'}),
    rule('.dev-name > span:first-child', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.dev-handle', {'font': mono(14, weight: 400), 'color': 'var(--muted)'}),
    rule('.dev-tagline', {'font-size': '15px', 'line-height': '1.5', 'color': 'var(--muted)'}),
    rule('.dev-stats', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px 20px'}),
    rule('.dev-stat', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'font-size': '14px',
      'color': 'var(--muted)',
      'white-space': 'nowrap',
    }),
    rule('.dev-stat b', {'color': 'var(--ink)', 'font-weight': '600'}),
    rule('.dev-pinned', {
      'margin': '0 24px',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'background': 'var(--bg)',
    }),
    rule('.dev-pin', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'padding': '12px 14px',
      'color': 'var(--ink)',
    }),
    rule('.dev-pin:hover', {'color': 'var(--ink)'}),
    rule('.dev-pin + .dev-pin', {'border-top': '1px solid var(--line)'}),
    rule('.dev-pin-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '2px', 'flex': '1', 'min-width': '0'}),
    rule('.dev-pin-name', {'font-size': '14px', 'font-weight': '600'}),
    rule('.dev-pin-desc', {
      'font-size': '13px',
      'color': 'var(--muted)',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('.dev-pin-stars', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '5px',
      'font': mono(12),
      'color': 'var(--muted)',
      'white-space': 'nowrap',
    }),
    rule('.dev-cta', {'padding': '20px 24px 24px', 'margin-top': 'auto'}),
    rule('.dev-cta a', {
      'height': '40px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': '8px',
      'border-radius': '2px',
      'border': '1px solid var(--line)',
      'color': 'var(--ink)',
      'font-size': '14px',
      'font-weight': '500',
    }),
    rule('.dev-cta a:hover', {'border-color': 'var(--ink)', 'color': 'var(--ink)'}),
    // In memoriam: a quieter card, with the portrait in black and white.
    rule('.dev-card.memorial', {'background': 'var(--surface2)'}),
    rule('.dev-card.memorial .dev-avatar', {'filter': 'grayscale(1)'}),
    rule('.dev-card.memorial .dev-cat', {
      'background': 'transparent',
      'color': 'var(--ink)',
      'box-shadow': 'inset 0 0 0 1px var(--line)',
    }),
    rule('.dev-card.memorial .dev-tagline', {'color': 'var(--ink)'}),
  ];
}
