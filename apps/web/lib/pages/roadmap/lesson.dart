import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';

/// The selected topic: description, key concepts, resources and actions.
class Lesson extends StatelessComponent {
  const Lesson({
    required this.topic,
    required this.position,
    required this.learned,
    required this.projectLink,
    required this.nextLabel,
    required this.onToggle,
    required this.onNext,
    super.key,
  });

  final RoadmapTopic topic;

  /// `B of 5`.
  final String position;
  final bool learned;

  /// The tracked project to link to, if any.
  final String? projectLink;
  final String nextLabel;
  final void Function() onToggle;
  final void Function() onNext;

  @override
  Component build(BuildContext context) {
    final t = topic;
    final concepts = t.concepts;
    final h = concepts.length * 44 - 10 < 34 ? 34 : concepts.length * 44 - 10;
    final mid = h / 2;
    final short = t.title.length > 18 ? t.title.split(RegExp('[ &,]')).first : t.title;
    final tree = [
      for (final (i, _) in concepts.indexed) 'M0 ${mid}C32 $mid 32 ${i * 44 + 17} 64 ${i * 44 + 17}',
    ].join();

    return div(classes: 'lesson', [
      div(classes: 'lesson-intro', [
        div(classes: 'lesson-badges', [
          span(classes: 'eyebrow', styles: Styles(raw: {'font-size': '12px'}), [.text('Topic $position')]),
          if (t.optional) span(classes: 'lesson-optional', [.text('Optional')]),
          if (learned) span(classes: 'lesson-learned', [.text('Learned')]),
        ]),
        h3([.text(t.title)]),
        if (t.description != null) p([.text(t.description!)]),
      ]),
      if (concepts.isNotEmpty)
        div(classes: 'lesson-block', [
          span(classes: 'eyebrow wide', [.text('Key concepts')]),
          div(classes: 'concepts', [
            span(classes: 'concept-root', [.text(short)]),
            RawText(
              '<svg width="64" height="$h" viewBox="0 0 64 $h" class="concept-tree"><path d="$tree"/></svg>',
            ),
            div(classes: 'concept-list', [
              for (final c in concepts) span([.text(c)]),
            ]),
          ]),
        ]),
      if (t.resources.isNotEmpty || projectLink != null)
        div(classes: 'lesson-block', [
          span(classes: 'eyebrow wide', [.text('Learn from')]),
          div(classes: 'resources', [
            for (final (label, url) in t.resources)
              a(
                href: url,
                classes: 'resource hover-border',
                target: Target.blank,
                attributes: {'rel': 'noopener'},
                [
                  span(classes: 'resource-text', [
                    span(classes: 'resource-host', [.text(_host(url))]),
                    span(classes: 'resource-label', [.text(label)]),
                  ]),
                  span(classes: 'resource-arrow', [.text('↗')]),
                ],
              ),
            if (projectLink != null)
              a(href: '/p/$projectLink', classes: 'resource project hover-border', [
                span(classes: 'resource-text', [
                  span(classes: 'resource-host', [.text('flutterverse')]),
                  span(classes: 'resource-label', [.text('$projectLink stats')]),
                ]),
                span(classes: 'resource-arrow', [.text('→')]),
              ]),
          ]),
        ]),
      div(classes: 'lesson-actions', [
        button(
          classes: learned ? 'lesson-toggle done' : 'lesson-toggle',
          type: ButtonType.button,
          attributes: {'aria-pressed': '$learned'},
          onClick: onToggle,
          [const Icon(Icons.tick, size: 14, strokeWidth: 2), .text(learned ? 'Learned' : 'Mark as learned')],
        ),
        span(classes: 'spacer', []),
        button(classes: 'lesson-next', type: ButtonType.button, onClick: onNext, [.text('$nextLabel →')]),
      ]),
    ]);
  }

  static String _host(String url) => (Uri.tryParse(url)?.host ?? '').replaceFirst('www.', '');

  @css
  static List<StyleRule> get styles => [
    rule('.lesson', {
      'grid-column': 'span 2',
      'min-width': '0',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '28px',
      'padding': '32px',
    }),
    rule('.lesson-intro', {'display': 'flex', 'flex-direction': 'column', 'gap': '10px'}),
    rule('.lesson-badges', {'display': 'flex', 'gap': '10px', 'align-items': 'center', 'flex-wrap': 'wrap'}),
    rule('.lesson-optional', {
      'font': mono(11),
      'letter-spacing': '0.06em',
      'text-transform': 'uppercase',
      'color': 'var(--muted)',
      'border': '1px dashed var(--muted)',
      'padding': '2px 6px',
      'border-radius': '2px',
    }),
    rule('.lesson-learned', {
      'font': mono(11),
      'letter-spacing': '0.06em',
      'text-transform': 'uppercase',
      'padding': '3px 8px',
      'border-radius': '999px',
      'background': 'var(--accent)',
      'color': 'var(--accent-ink)',
    }),
    rule('.lesson h3', {
      'margin': '0',
      'font-size': 'clamp(28px,3.4vw,40px)',
      'line-height': '1.05',
      'letter-spacing': '-0.03em',
      'font-weight': '600',
      'text-wrap': 'balance',
    }),
    rule('.lesson-intro p', {
      'font-size': '17px',
      'line-height': '1.55',
      'color': 'var(--muted)',
      'max-width': '620px',
      'text-wrap': 'pretty',
    }),
    rule('.lesson-block', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.concepts', {'display': 'flex', 'align-items': 'center'}),
    rule('.concept-root', {
      'font': mono(13, weight: 600),
      'padding': '9px 12px',
      'background': 'var(--accent)',
      'color': 'var(--accent-ink)',
      'border-radius': '2px',
      'white-space': 'nowrap',
      'flex-shrink': '0',
    }),
    rule('.concept-tree', {'display': 'block', 'flex-shrink': '0', 'overflow': 'visible'}),
    rule('.concept-tree path', {'fill': 'none', 'stroke': 'var(--accent)', 'stroke-width': '1.5'}),
    rule('.concept-list', {'display': 'flex', 'flex-direction': 'column', 'gap': '10px', 'min-width': '0'}),
    rule('.concept-list span', {
      'height': '34px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'padding': '0 12px',
      'border': '1px solid var(--line)',
      'background': 'var(--bg)',
      'border-radius': '2px',
      'font': mono(14, weight: 400),
      'white-space': 'nowrap',
      'width': 'fit-content',
    }),
    rule('.resources', {
      'display': 'grid',
      'grid-template-columns': 'repeat(auto-fill,minmax(220px,1fr))',
      'gap': '10px',
    }),
    rule('.resource', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'flex-start',
      'gap': '12px',
      'padding': '16px',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'color': 'var(--ink)',
    }),
    rule('.resource:hover', {'color': 'var(--ink)'}),
    rule('.resource.project', {'background': 'var(--accent-soft)'}),
    rule('.resource-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '4px'}),
    rule('.resource-host', {'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
    rule('.resource-label', {'font-size': '15px', 'font-weight': '600'}),
    rule('.resource-arrow', {'font-size': '16px', 'color': 'var(--accent)'}),
    rule('.lesson-actions', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '10px',
      'align-items': 'center',
      'padding-top': '20px',
      'border-top': '1px solid var(--line)',
      'margin-top': 'auto',
    }),
    rule('.lesson-actions .spacer', {'flex': '1'}),
    rule('.lesson-toggle', {
      'height': '44px',
      'padding': '0 18px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'border-radius': '2px',
      'font': sans(15, weight: 500),
      'cursor': 'pointer',
      'background': 'var(--ink)',
      'color': 'var(--bg)',
      'border': '1px solid var(--ink)',
    }),
    rule('.lesson-toggle.done', {
      'background': 'var(--accent-soft)',
      'color': 'var(--accent)',
      'border-color': 'var(--accent)',
    }),
    rule('.lesson-next', {
      'height': '44px',
      'padding': '0 4px',
      'border': '0',
      'background': 'transparent',
      'color': 'var(--ink)',
      'font': sans(15, weight: 500),
      'cursor': 'pointer',
    }),
    below(640, [
      rule('.lesson', {'padding': '24px 16px', 'grid-column': 'auto'}),
    ]),
  ];
}
