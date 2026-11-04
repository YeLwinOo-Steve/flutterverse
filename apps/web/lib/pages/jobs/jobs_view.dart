import 'dart:async';

import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/track.dart';
import '../../styles/css.dart';
import 'job_card.dart';
import 'jobs_filter.dart';

/// The filterable list on `/jobs`. The whole file is passed in: it is capped
/// at 500 short rows, so there is nothing to fetch later.
///
/// Cards render [pageSize] at a time. The first page is pre-rendered; the
/// next one appears as the sentinel under the grid nears the viewport.
@client
class JobsView extends StatefulComponent {
  const JobsView({required this.jobs, required this.now, super.key});

  final JobsFile jobs;

  /// ISO timestamp of the data snapshot, for "seen 3 days ago".
  final String now;

  static const pageSize = 20;

  @override
  State<JobsView> createState() => _JobsViewState();

  @css
  static List<StyleRule> get styles => [
    rule('.jobs-tools', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '12px', 'align-items': 'center'}),
    rule('.jobs-search', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'height': '40px',
      'padding': '0 14px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'color': 'var(--muted)',
      'flex': '1 1 320px',
      'max-width': '420px',
    }),
    // The toggles share the search box's height, so the toolbar is one line.
    rule('.jobs-tools .chip', {'height': '40px', 'display': 'inline-flex', 'align-items': 'center'}),
    rule('.jobs-search:focus-within', {'border-color': 'var(--ink)'}),
    rule('.jobs-search input', {
      'flex': '1',
      'min-width': '0',
      'border': '0',
      'outline': '0',
      'background': 'transparent',
      'color': 'var(--ink)',
      'font-size': '15px',
    }),
    rule('.jobs-search input::placeholder', {'color': 'var(--muted)', 'opacity': '1'}),
    rule('.jobs-count', {'font': mono(12, weight: 400), 'color': 'var(--muted)', 'margin-left': 'auto'}),
    rule('.jobs-grid', {
      'list-style': 'none',
      'margin': '0',
      'padding': '0',
      'display': 'grid',
      'grid-template-columns': 'repeat(2,minmax(0,1fr))',
      'gap': '16px',
    }),
    rule('.jobs-grid > li', {'display': 'flex'}),
    rule('.jobs-grid > li > .job-card', {'flex': '1'}),
    rule('.jobs-sentinel', {
      'display': 'flex',
      'justify-content': 'center',
      'padding': '8px 0 4px',
      'font': mono(12, weight: 400),
      'color': 'var(--muted)',
    }),
    rule('.jobs-end', {'text-align': 'center', 'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
    below(860, [
      rule('.jobs-grid', {'grid-template-columns': '1fr'}),
    ]),
  ];
}

class _JobsViewState extends State<JobsView> {
  JobsQuery _q = emptyJobsQuery;
  int _shown = JobsView.pageSize;
  JSFunction? _onScroll;
  bool _queued = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _onScroll = ((web.Event _) => _check()).toJS;
    web.window.addEventListener('scroll', _onScroll, web.AddEventListenerOptions(passive: true));
    web.window.addEventListener('resize', _onScroll);
    _check();
  }

  @override
  void dispose() {
    if (_onScroll != null) {
      web.window.removeEventListener('scroll', _onScroll);
      web.window.removeEventListener('resize', _onScroll);
    }
    super.dispose();
  }

  void _set(JobsQuery q) {
    setState(() {
      _q = q;
      _shown = JobsView.pageSize;
    });
    _check();
  }

  /// Shows the next page when the sentinel under the grid is within
  /// [_lead] pixels of the viewport's bottom, or already above it (End or a
  /// scrollbar drag jumps straight past). At most once per frame, and again
  /// after each page renders, since a tall screen may still need more.
  ///
  /// A scroll check rather than an IntersectionObserver: an observer only
  /// fires when the sentinel crosses into view, so a jump past it is missed.
  void _check() {
    if (_queued) return;
    _queued = true;
    web.window.requestAnimationFrame(
      ((num _) {
        _queued = false;
        final sentinel = web.document.querySelector('.jobs-sentinel');
        if (sentinel == null || !mounted) return;
        if (sentinel.getBoundingClientRect().top < web.window.innerHeight + _lead) {
          setState(() => _shown += JobsView.pageSize);
          Timer.run(_check);
        }
      }).toJS,
    );
  }

  static const _lead = 600;

  @override
  Component build(BuildContext context) {
    final now = DateTime.parse(component.now);
    final rows = filterJobs(component.jobs.jobs, _q);
    final shown = rows.take(_shown).toList();
    return div(classes: 'jobs-body', [
      _tools(rows.length),
      if (rows.isEmpty)
        div(classes: 'empty', [
          b([.text('No roles match')]),
          span([.text('Try fewer words, or turn a filter off.')]),
        ])
      else ...[
        ul(classes: 'jobs-grid', [
          for (final (i, j) in shown.indexed)
            li(key: ValueKey(j.id), [JobCard(job: j, now: now, onOpen: () => _opened(j, i + 1))]),
        ]),
        if (shown.length < rows.length)
          div(
            classes: 'jobs-sentinel',
            attributes: {'aria-hidden': 'true'},
            [
              .text('Loading more roles…'),
            ],
          )
        else if (rows.length > JobsView.pageSize)
          p(classes: 'jobs-end', [.text("That's all ${rows.length} roles.")]),
      ],
    ]);
  }

  Component _tools(int count) => div(classes: 'jobs-tools', [
    label(classes: 'jobs-search', [
      const Icon(Icons.search, size: 16),
      input<String>(
        type: InputType.search,
        value: _q.text,
        attributes: {
          'placeholder': 'Search title, company or location',
          'aria-label': 'Search jobs',
          'autocomplete': 'off',
        },
        onInput: (t) => _set((remoteOnly: _q.remoteOnly, titleOnly: _q.titleOnly, text: t)),
      ),
    ]),
    _toggle(
      'Remote only',
      _q.remoteOnly,
      () => _set((remoteOnly: !_q.remoteOnly, titleOnly: _q.titleOnly, text: _q.text)),
    ),
    _toggle(
      'Flutter in title',
      _q.titleOnly,
      () => _set((remoteOnly: _q.remoteOnly, titleOnly: !_q.titleOnly, text: _q.text)),
    ),
    span(
      classes: 'jobs-count',
      attributes: {'aria-live': 'polite'},
      [
        .text('$count ${count == 1 ? 'role' : 'roles'}'),
      ],
    ),
  ]);

  Component _toggle(String text, bool on, void Function() onTap) => button(
    type: ButtonType.button,
    classes: on ? 'chip on' : 'chip',
    attributes: {'aria-pressed': '$on'},
    onClick: onTap,
    [.text(text)],
  );

  // Counts and ids only: no titles or search text.
  void _opened(Job j, int rank) => track('job_click', {
    'source': j.source.name,
    'match': j.match.name,
    'remote': j.remote == true,
    'rank': rank,
    'company': j.companyId,
  });
}
