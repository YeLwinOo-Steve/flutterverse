import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/view.dart';
import '../../styles/css.dart';
import 'jobs_filter.dart';

/// Roles first seen within this many days get a "New" tag.
const newForDays = 3;

/// One open role as a card. The title's link stretches over the whole card,
/// so anywhere on it opens the company's posting; the company name and the
/// report flag sit above that layer as links of their own.
class JobCard extends StatelessComponent {
  const JobCard({required this.job, required this.now, this.onOpen, super.key});

  final Job job;
  final DateTime now;

  /// Called when the posting link is followed (for analytics).
  final void Function()? onOpen;

  static const _rel = {'rel': 'noopener nofollow'};

  @override
  Component build(BuildContext context) {
    final j = job;
    final seen = DateTime.tryParse(j.firstSeen);
    final days = seen == null ? null : now.difference(seen).inDays;
    final fresh = days != null && days < newForDays;
    return article(classes: fresh ? 'job-card fresh' : 'job-card', [
      if (fresh) span(classes: 'job-card-new', [.text('New')]),
      div(classes: 'job-card-head', [
        _tile(j),
        div(classes: 'job-card-heading', [
          h3(classes: 'job-card-title', [
            a(
              href: j.url,
              target: Target.blank,
              attributes: _rel,
              events: {'click': (_) => onOpen?.call()},
              [.text(j.title)],
            ),
          ]),
          div(classes: 'job-card-sub', [
            if (j.companyUrl case final url?)
              a(href: url, classes: 'job-card-company', target: Target.blank, attributes: _rel, [.text(j.company)])
            else
              span(classes: 'job-card-company', [.text(j.company)]),
            span(classes: 'job-card-dot', [.text('·')]),
            span(classes: 'job-card-where', [.text(j.location ?? 'Location not listed')]),
          ]),
        ]),
        a(
          href: jobReportUrl(j),
          classes: 'job-card-report',
          target: Target.blank,
          attributes: {
            'rel': 'noopener',
            'aria-label': 'Report ${j.title} at ${j.company}',
            'title': 'Report this job',
          },
          [const Icon(Icons.flag, size: 14)],
        ),
      ]),
      div(classes: 'job-card-tags', [
        if (j.remote == true) span(classes: 'job-tag remote', [const Icon(Icons.globe, size: 12), .text('Remote')]),
        if (j.match == JobMatch.mentions) span(classes: 'job-tag', [.text('Uses Flutter')]),
      ]),
      div(classes: 'job-card-foot', [
        span(classes: 'job-card-meta', [
          .text([j.source.label, if (days != null) days < 1 ? 'today' : ago(seen, now: now)].join(' · ')),
        ]),
        span(classes: 'job-card-go', [
          .text(j.source == JobSource.hn ? 'Read the post' : 'Apply on ${j.source.label}'),
          const Icon(Icons.external, size: 13),
        ]),
      ]),
    ]);
  }

  /// A soft initials tile: the company's color as a tint, its letters in the
  /// full color.
  Component _tile(Job j) {
    final color = logoColorOf(j.companyId);
    return div(
      classes: 'job-card-tile',
      attributes: {'aria-hidden': 'true'},
      styles: Styles(raw: {'--tile': color}),
      [.text(jobInitials(j.company))],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.job-card', {
      'position': 'relative',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '16px',
      'padding': '22px 22px 18px',
      'background': 'var(--surface)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'transition': 'border-color .15s ease, transform .15s ease, box-shadow .15s ease',
    }),
    rule('.job-card:hover', {
      'border-color': 'color-mix(in srgb, var(--accent) 55%, var(--line))',
      'transform': 'translateY(-2px)',
      'box-shadow': '0 14px 32px rgba(4,43,89,0.16)',
    }),
    rule('.job-card:focus-within', {'border-color': 'var(--accent)'}),
    // A diagonal ribbon across the top-left corner, like a price tag, cut
    // off by the card's edges (overflow: hidden). Its band runs 22–50px from
    // the corner along the diagonal; the extra top padding keeps the logo
    // tile's corner (22px, 30px) clear of it.
    rule('.job-card.fresh', {'overflow': 'hidden', 'padding-top': '30px'}),
    rule('.job-card-new', {
      'position': 'absolute',
      'top': '8px',
      'left': '-37px',
      'width': '110px',
      'height': '20px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'transform': 'rotate(-45deg)',
      'font': mono(10, weight: 700),
      'letter-spacing': '0.14em',
      'text-transform': 'uppercase',
      'color': 'var(--accent-ink)',
      'background': 'var(--accent)',
      'box-shadow': '0 2px 8px rgba(4,43,89,0.3)',
      'pointer-events': 'none',
      'z-index': '2',
    }),
    rule('.job-card-head', {'display': 'flex', 'align-items': 'flex-start', 'gap': '14px', 'min-width': '0'}),
    rule('.job-card-tile', {
      'width': '44px',
      'height': '44px',
      'flex-shrink': '0',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'border-radius': '2px',
      'font': mono(15, weight: 600),
      'letter-spacing': '0.02em',
      'color': 'color-mix(in srgb, var(--tile) 40%, var(--ink))',
      'background': 'color-mix(in srgb, var(--tile) 28%, var(--surface2))',
      'box-shadow': 'inset 0 0 0 1px color-mix(in srgb, var(--tile) 45%, var(--line))',
    }),
    rule('.job-card-heading', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '6px',
      'min-width': '0',
      'flex': '1',
    }),
    rule('.job-card-title', {
      'margin': '0',
      'font-size': '17px',
      'font-weight': '600',
      'line-height': '1.35',
      'letter-spacing': '-0.01em',
      'display': '-webkit-box',
      '-webkit-line-clamp': '2',
      '-webkit-box-orient': 'vertical',
      'overflow': 'hidden',
    }),
    rule('.job-card-title a', {'color': 'var(--ink)', 'outline': 'none'}),
    // Stretches the posting link over the whole card.
    rule('.job-card-title a::after', {'content': "''", 'position': 'absolute', 'inset': '0'}),
    rule('.job-card-sub', {
      'display': 'flex',
      'align-items': 'baseline',
      'gap': '6px',
      'min-width': '0',
      'font-size': '14px',
      'color': 'var(--muted)',
    }),
    rule('.job-card-company', {
      'position': 'relative',
      'z-index': '1',
      'flex-shrink': '0',
      'max-width': '60%',
      'font-weight': '500',
      'color': 'var(--ink)',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('a.job-card-company:hover', {'color': 'var(--accent)', 'text-decoration': 'underline'}),
    rule('.job-card-where', {'white-space': 'nowrap', 'overflow': 'hidden', 'text-overflow': 'ellipsis'}),
    rule('.job-card-report', {
      'position': 'relative',
      'z-index': '1',
      'flex-shrink': '0',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'width': '30px',
      'height': '30px',
      'margin': '-4px -6px 0 0',
      'border-radius': '2px',
      'color': 'var(--muted)',
      'opacity': '.55',
      'transition': 'opacity .15s ease, color .15s ease, background .15s ease',
    }),
    rule('.job-card:hover .job-card-report, .job-card-report:focus-visible', {'opacity': '1'}),
    rule('.job-card-report:hover', {'color': 'var(--neg)', 'background': 'var(--surface2)'}),
    // Touch screens have no hover, so the flag stays fully visible.
    css.media(MediaQuery.raw('(hover: none)'), [
      rule('.job-card-report', {'opacity': '1'}),
    ]),
    rule('.job-card-tags', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '6px', 'min-height': '24px'}),
    rule('.job-card-tags:empty', {'display': 'none'}),
    rule('.job-tag', {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '5px',
      'height': '24px',
      'padding': '0 9px',
      'border-radius': '999px',
      'font-size': '12px',
      'font-weight': '500',
      'background': 'var(--surface2)',
      'color': 'var(--muted)',
    }),
    rule('.job-tag.remote', {'background': 'var(--accent-soft)', 'color': 'var(--pos)'}),
    rule('.job-card-foot', {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'space-between',
      'gap': '12px',
      'margin-top': 'auto',
      'font-size': '13px',
    }),
    rule('.job-card-meta', {'font': mono(12, weight: 400), 'color': 'var(--muted)', 'white-space': 'nowrap'}),
    rule('.job-card-go', {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '6px',
      'font-weight': '600',
      'color': 'var(--accent)',
      'white-space': 'nowrap',
    }),
    rule('.job-card-go .icon', {'flex-shrink': '0', 'transition': 'transform .15s ease'}),
    rule('.job-card:hover .job-card-go .icon', {'transform': 'translate(2px,-2px)'}),
    css.media(MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      rule('.job-card, .job-card-go .icon, .job-card-report', {'transition': 'none'}),
      rule('.job-card:hover', {'transform': 'none'}),
    ]),
  ];
}

/// Up to two letters for a company's tile: the first letters of its first
/// two words, or the first two of a one-word name.
String jobInitials(String company) {
  final words = company.split(RegExp(r'[\s.&-]+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  final s = words.length == 1
      ? words.first.substring(0, words.first.length.clamp(0, 2))
      : '${words[0][0]}${words[1][0]}';
  return s.toUpperCase();
}
