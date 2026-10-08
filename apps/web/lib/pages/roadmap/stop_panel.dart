import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';
import 'lesson.dart';
import 'roadmap_progress.dart';

/// The selected stop: its topics on the left, the open lesson on the right,
/// and the milestone to build.
class StopPanel extends StatelessComponent {
  const StopPanel({
    required this.progress,
    required this.stage,
    required this.topic,
    required this.knownProjects,
    required this.onStage,
    required this.onTopic,
    required this.onToggle,
    super.key,
  });

  final TrackProgress progress;
  final int stage;
  final int topic;
  final Set<String> knownProjects;
  final void Function(int) onStage;
  final void Function(int) onTopic;
  final void Function(String key) onToggle;

  @override
  Component build(BuildContext context) {
    final p = progress, s = p.track.stages[stage], n = p.track.stages.length;
    final num = (stage + 1).toString().padLeft(2, '0');
    final lesson = s.topics[topic];
    final nextLabel = topic < s.topics.length - 1 ? 'Next topic' : (stage < n - 1 ? 'Next stop' : 'Back to start');

    return div(classes: 'stop panel', [
      div(classes: 'stop-head', [
        div(classes: 'stop-id', [
          span(classes: 'stop-chip', [.text('STOP $num')]),
          div(classes: 'stop-title', [
            span([.text(s.title)]),
            span(classes: 'muted', [.text(s.blurb)]),
          ]),
        ]),
        div(classes: 'stop-nav', [
          span(classes: 'stop-count', [.text('${s.time} · ${p.learnedIn(stage)}/${s.topics.length} learned')]),
          div([
            _navButton(Icons.chevronLeft, 'Previous stop', stage > 0 ? () => onStage(stage - 1) : null),
            _navButton(Icons.chevronRight, 'Next stop', stage < n - 1 ? () => onStage(stage + 1) : null),
          ]),
        ]),
      ]),
      div(classes: 'stop-body', [
        div(classes: 'topics', [
          for (final (j, t) in s.topics.indexed) _topicTab(j, t),
        ]),
        Lesson(
          topic: lesson,
          position: '${String.fromCharCode(65 + topic)} of ${s.topics.length}',
          learned: p.isLearned(stage, lesson),
          projectLink: lesson.project != null && knownProjects.contains(lesson.project) ? lesson.project : null,
          nextLabel: nextLabel,
          onToggle: () => onToggle(p.key(stage, lesson)),
          onNext: () => topic < s.topics.length - 1 ? onTopic(topic + 1) : onStage(stage < n - 1 ? stage + 1 : 0),
        ),
      ]),
      div(classes: 'milestone', [
        span(classes: 'notch left', []),
        span(classes: 'notch right', []),
        div(classes: 'milestone-stub', [
          span(classes: 'eyebrow wide', [.text('Milestone')]),
          span(classes: 'milestone-num', [.text('STOP $num')]),
        ]),
        div(classes: 'milestone-build', [
          span([.text('Build: ${s.build}')]),
        ]),
      ]),
    ]);
  }

  Component _navButton(String icon, String label, void Function()? onTap) => button(
    classes: onTap == null ? 'stop-arrow off' : 'stop-arrow',
    type: ButtonType.button,
    attributes: {'aria-label': label, if (onTap == null) 'disabled': ''},
    onClick: onTap,
    [Icon(icon, strokeWidth: 1.6)],
  );

  Component _topicTab(int j, RoadmapTopic t) {
    final on = j == topic, learned = progress.isLearned(stage, t);
    return button(
      classes: on ? 'topic on' : 'topic',
      type: ButtonType.button,
      onClick: () => onTopic(j),
      [
        span(classes: ['topic-badge', if (learned) 'done', if (t.optional) 'optional'].join(' '), [
          .text(learned ? '✓' : String.fromCharCode(65 + j)),
        ]),
        div(classes: 'topic-text', [
          span(classes: 'topic-title', [.text(t.title)]),
          span(classes: 'topic-meta', [.text('${t.concepts.length} concepts${t.optional ? ' · optional' : ''}')]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.stop', {'display': 'flex', 'flex-direction': 'column'}),
    rule('.stop-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '16px 32px',
      'align-items': 'center',
      'justify-content': 'space-between',
      'padding': '20px 24px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.stop-id', {'display': 'flex', 'gap': '16px', 'align-items': 'center', 'min-width': '0'}),
    rule('.stop-chip', {
      'font': mono(13, weight: 600),
      'padding': '6px 10px',
      'background': 'var(--ink)',
      'color': 'var(--bg)',
      'border-radius': '2px',
      'flex-shrink': '0',
    }),
    rule('.stop-title', {'display': 'flex', 'flex-direction': 'column', 'gap': '2px', 'min-width': '0'}),
    rule('.stop-title > span:first-child', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.stop-title .muted', {'font-size': '14px', 'text-wrap': 'pretty'}),
    rule('.stop-nav', {'display': 'flex', 'gap': '16px', 'align-items': 'center'}),
    rule('.stop-nav > div', {'display': 'flex'}),
    rule('.stop-count', {'font': mono(13), 'color': 'var(--muted)', 'white-space': 'nowrap'}),
    rule('.stop-arrow', {
      'width': '40px',
      'height': '40px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'background': 'transparent',
      'color': 'var(--ink)',
      'border': '1px solid var(--line)',
      'margin-left': '-1px',
      'cursor': 'pointer',
    }),
    rule('.stop-arrow.off', {'cursor': 'default', 'opacity': '0.35'}),
    rule('.stop-body', {'display': 'grid', 'grid-template-columns': 'repeat(auto-fit,minmax(min(100%,280px),1fr))'}),
    rule('.topics', {
      'display': 'flex',
      'flex-direction': 'column',
      'padding': '12px',
      'gap': '2px',
      'border-right': '1px solid var(--line)',
      'background': 'var(--bg)',
    }),
    rule('.topic', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'padding': '12px',
      'border-radius': '2px',
      'cursor': 'pointer',
      'background': 'transparent',
      'color': 'var(--ink)',
      'border': '0',
      'text-align': 'left',
      'font': 'inherit',
      'transition': 'background .15s',
    }),
    rule('.topic.on', {'background': 'var(--ink)', 'color': 'var(--bg)'}),
    rule('.topic-badge', {
      'width': '28px',
      'height': '28px',
      'flex-shrink': '0',
      'border-radius': '50%',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'font': mono(12, weight: 600),
      'border': '1.5px solid var(--muted)',
    }),
    rule('.topic.on .topic-badge', {'border-color': 'var(--bg)'}),
    rule('.topic-badge.optional', {'border-style': 'dashed'}),
    rule('.topic-badge.done', {
      'background': 'var(--accent)',
      'color': 'var(--accent-ink)',
      'border': '1.5px solid var(--accent)',
    }),
    rule('.topic-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '2px', 'min-width': '0', 'flex': '1'}),
    rule('.topic-title', {'font-size': '15px', 'font-weight': '600', 'line-height': '1.25'}),
    rule('.topic-meta', {'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
    rule('.topic.on .topic-meta', {'color': 'var(--bg)', 'opacity': '0.7'}),
    rule('.milestone', {
      'display': 'flex',
      'align-items': 'stretch',
      'border-top': '1px dashed var(--line)',
      'position': 'relative',
    }),
    rule('.notch', {
      'position': 'absolute',
      'top': '-9px',
      'width': '16px',
      'height': '16px',
      'border-radius': '50%',
      'background': 'var(--bg)',
      'border': '1px solid var(--line)',
    }),
    rule('.notch.left', {'left': '-9px', 'clip-path': 'inset(0 0 0 50%)'}),
    rule('.notch.right', {'right': '-9px', 'clip-path': 'inset(0 50% 0 0)'}),
    rule('.milestone-stub', {
      'display': 'flex',
      'flex-direction': 'column',
      'justify-content': 'center',
      'gap': '2px',
      'padding': '18px 24px',
      'border-right': '1px dashed var(--line)',
      'flex-shrink': '0',
    }),
    rule('.milestone-num', {'font': mono(15, weight: 600)}),
    rule('.milestone-build', {
      'flex': '1',
      'min-width': '0',
      'display': 'flex',
      'align-items': 'center',
      'padding': '18px 24px',
    }),
    rule('.milestone-build span', {
      'font-size': '16px',
      'font-weight': '500',
      'line-height': '1.4',
      'text-wrap': 'pretty',
    }),
  ];
}
