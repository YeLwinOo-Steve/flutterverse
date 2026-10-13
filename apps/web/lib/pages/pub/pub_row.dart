import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/badges.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../components/ui/project_logo.dart';
import '../../data/view.dart';
import '../../styles/css.dart';

/// A package row on the pub.dev page.
class PubRow extends StatelessComponent {
  const PubRow({required this.row, required this.rank, required this.now, super.key});

  final ProjectRow row;
  final int rank;
  final DateTime now;

  @override
  Component build(BuildContext context) {
    final r = row;
    return a(href: r.path, classes: 'pub-row hover-row', [
      span(classes: 'pub-rank', [.text('$rank')]),
      ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl, size: 44),
      div(classes: 'pub-main', [
        div(classes: 'pub-title', [
          span(classes: 'pub-name', [.text(r.pub ?? r.name)]),
          if (r.version != null) span(classes: 'pub-version', [.text('v${r.version}')]),
          if (r.sdk != null) span(classes: 'pub-sdk', [.text(r.sdk!)]),
          if (r.flutterFavorite) favoriteBadge(),
        ]),
        span(classes: 'pub-desc', [.text(r.description ?? '')]),
        span(classes: 'pub-meta', [
          const Icon(Icons.shieldCheck, size: 13),
          .text('${r.publisher ?? r.owner ?? notAvailable} · updated ${ago(r.released, now: now)}'),
        ]),
      ]),
      div(classes: 'pub-stats', [
        _stat(Icons.heart, compactNumber(r.likes), 'Likes'),
        _stat(Icons.check, '${r.points ?? notAvailable}', 'Points'),
        _stat(Icons.download, compactNumber(r.downloads), 'Downloads'),
      ]),
    ]);
  }

  Component _stat(String icon, String value, String label) => div(classes: 'pub-stat', [
    span(classes: 'pub-stat-v', [
      span(classes: 'pub-stat-icon', [Icon(icon, size: 14, strokeWidth: 1.6)]),
      .text(value),
    ]),
    span(classes: 'pub-stat-k', [.text(label)]),
  ]);

  @css
  static List<StyleRule> get styles => [
    rule('.pub-row', {
      'display': 'grid',
      'grid-template-columns': '28px 44px minmax(0,1fr) auto',
      'gap': '16px',
      'align-items': 'center',
      'padding': '18px 24px',
      'border-bottom': '1px solid var(--line)',
      'color': 'var(--ink)',
    }),
    rule('.pub-row:hover', {'color': 'var(--ink)'}),
    rule('.pub-rank', {'font': mono(13), 'color': 'var(--muted)'}),
    rule('.pub-main', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px', 'min-width': '0'}),
    rule('.pub-title', {'display': 'flex', 'align-items': 'center', 'gap': '10px', 'flex-wrap': 'wrap'}),
    rule('.pub-name', {'font-size': '16px', 'font-weight': '600', 'color': 'var(--accent)'}),
    rule('.pub-version', {'font': mono(13, weight: 400), 'color': 'var(--muted)'}),
    rule('.pub-sdk', {
      'font': mono(11),
      'padding': '3px 8px',
      'border-radius': '999px',
      'background': 'var(--surface2)',
      'color': 'var(--ink)',
    }),
    rule('.pub-desc', {
      'font-size': '14px',
      'color': 'var(--muted)',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('.pub-meta', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'font-size': '13px',
      'color': 'var(--muted)',
    }),
    rule('.pub-meta .icon', {'color': 'var(--accent)'}),
    rule('.pub-stats', {'display': 'flex', 'gap': '24px', 'align-items': 'center'}),
    rule('.pub-stat', {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-end',
      'gap': '3px',
      'min-width': '84px',
    }),
    rule('.pub-stat-v', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'font-size': '18px',
      'font-weight': '600',
      'letter-spacing': '-0.01em',
    }),
    rule('.pub-stat-icon', {
      'width': '26px',
      'height': '26px',
      'border-radius': '50%',
      'background': 'var(--accent-soft)',
      'color': 'var(--accent)',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
    }),
    rule('.pub-stat-k', {
      'font': mono(11),
      'letter-spacing': '0.06em',
      'text-transform': 'uppercase',
      'color': 'var(--muted)',
    }),
    below(820, [
      rule('.pub-row', {'grid-template-columns': '28px 44px minmax(0,1fr)'}),
      rule('.pub-stats', {'grid-column': '3'}),
    ]),
    // Three stats don't fit beside the logo on a phone: give them the row.
    below(560, [
      rule('.pub-stats', {'grid-column': '1 / -1', 'justify-content': 'space-around', 'gap': '12px'}),
      rule('.pub-stat', {'min-width': '0', 'align-items': 'center'}),
    ]),
  ];
}
