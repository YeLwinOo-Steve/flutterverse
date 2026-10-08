import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../../components/ui/seg_control.dart';
import '../../styles/css.dart';
import 'metro_layout.dart';
import 'metro_map.dart';
import 'roadmap_progress.dart';
import 'stop_panel.dart';

const _storageKey = 'fv-roadmap';

/// `/roadmap`: learning tracks as metro maps, with progress kept in
/// localStorage.
@client
class RoadmapView extends StatefulComponent {
  const RoadmapView({required this.roadmap, required this.knownProjects, super.key});

  final RoadmapFile roadmap;

  /// Ids of tracked projects that topics may link to.
  final List<String> knownProjects;

  @override
  State<RoadmapView> createState() => _RoadmapViewState();

  @css
  static List<StyleRule> get styles => [
    rule('.roadmap', {'display': 'flex', 'flex-direction': 'column', 'gap': '28px', 'padding-top': '24px'}),
    rule('.roadmap-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '24px 40px',
      'align-items': 'flex-end',
      'justify-content': 'space-between',
    }),
    rule('.roadmap-intro', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px', 'max-width': '640px'}),
    rule('.roadmap-intro h1', {
      'font-size': 'clamp(36px,5vw,56px)',
      'line-height': '1.02',
      'letter-spacing': '-0.04em',
      'font-weight': '600',
      'text-wrap': 'balance',
    }),
    rule('.roadmap-intro p', {
      'font-size': '17px',
      'line-height': '1.55',
      'color': 'var(--muted)',
      'text-wrap': 'pretty',
    }),
    rule('.roadmap-tools', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '12px',
      'align-items': 'flex-end',
      'margin-left': 'auto',
    }),
    rule('.roadmap-progress', {
      'display': 'flex',
      'gap': '14px',
      'align-items': 'center',
      'font': mono(13),
      'color': 'var(--muted)',
      'white-space': 'nowrap',
    }),
    rule('.roadmap-reset', {
      'cursor': 'pointer',
      'color': 'var(--ink)',
      'text-decoration': 'underline',
      'text-underline-offset': '3px',
      'background': 'none',
      'border': '0',
      'padding': '0',
      'font': 'inherit',
    }),
  ];
}

class _RoadmapViewState extends State<RoadmapView> {
  late String _trackId = component.roadmap.tracks.containsKey('flutter')
      ? 'flutter'
      : component.roadmap.tracks.keys.first;
  Set<String> _learned = {};
  int? _selected;
  int? _topic;
  double _width = 1222;
  bool _flying = false;
  Timer? _flyTimer;
  JSFunction? _onResize;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    try {
      final raw = web.window.localStorage.getItem(_storageKey);
      if (raw != null) _learned = (jsonDecode(raw) as Map<String, Object?>).keys.toSet();
    } catch (_) {}
    _onResize = ((web.Event _) => _measure()).toJS;
    web.window.addEventListener('resize', _onResize);
    Future<void>.delayed(Duration.zero, _measure);
  }

  @override
  void dispose() {
    _flyTimer?.cancel();
    if (_onResize != null) web.window.removeEventListener('resize', _onResize);
    super.dispose();
  }

  void _measure() {
    final el = web.document.querySelector('.metro-box') as web.HTMLElement?;
    final w = (el?.clientWidth ?? 0).toDouble();
    if (w > 0 && (w - _width).abs() > 1) setState(() => _width = w);
  }

  void _save(Set<String> learned) {
    final reachBefore = TrackProgress(_trackId, _track, _learned).reach;
    setState(() => _learned = learned);
    try {
      web.window.localStorage.setItem(_storageKey, jsonEncode({for (final k in learned) k: 1}));
    } catch (_) {}
    if (TrackProgress(_trackId, _track, learned).reach != reachBefore) {
      setState(() => _flying = true);
      _flyTimer?.cancel();
      _flyTimer = Timer(const Duration(milliseconds: 1500), () => setState(() => _flying = false));
    }
  }

  RoadmapTrack get _track => component.roadmap.tracks[_trackId]!;

  @override
  Component build(BuildContext context) {
    final track = _track;
    final progress = TrackProgress(_trackId, track, _learned);
    final n = track.stages.length;
    final stage = math.min(_selected ?? progress.reach, n - 1);
    final topics = track.stages[stage].topics;
    final topic = _topic != null && _topic! < topics.length
        ? _topic!
        : math.max(0, topics.indexWhere((t) => !progress.isLearned(stage, t)));
    final learnedHere = progress.learnedCount;

    return div(classes: 'roadmap', [
      section(classes: 'roadmap-head', [
        div(classes: 'roadmap-intro', [
          span(classes: 'eyebrow wide accent', [.text('Learning roadmaps')]),
          h1([.text('Learn ${track.name}.')]),
          p([.text(track.intro)]),
        ]),
        div(classes: 'roadmap-tools', [
          SegControl<String>(
            label: 'Track',
            options: [for (final e in component.roadmap.tracks.entries) (e.key, e.value.name)],
            selected: _trackId,
            onSelect: (id) => setState(() {
              _trackId = id;
              _selected = null;
              _topic = null;
            }),
          ),
          div(classes: 'roadmap-progress', [
            span([.text('$learnedHere / ${progress.total} topics learned')]),
            if (learnedHere > 0)
              button(
                classes: 'roadmap-reset',
                type: ButtonType.button,
                onClick: () => _save({
                  for (final k in _learned)
                    if (!k.startsWith('$_trackId:')) k,
                }),
                [.text('Reset')],
              ),
          ]),
        ]),
      ]),
      MetroMap(
        progress: progress,
        layout: MetroLayout(stageCount: n, width: _width),
        selected: stage,
        flying: _flying,
        onSelect: (index) => setState(() {
          _selected = index;
          _topic = null;
        }),
        onSetStage: (index, learned) {
          final keys = progress.stageKeys(index);
          _save(learned ? {..._learned, ...keys} : _learned.difference(keys.toSet()));
          setState(() {
            _selected = null;
            _topic = null;
          });
        },
      ),
      StopPanel(
        progress: progress,
        stage: stage,
        topic: topic,
        knownProjects: component.knownProjects.toSet(),
        onStage: (index) => setState(() {
          _selected = index;
          _topic = null;
        }),
        onTopic: (j) => setState(() => _topic = j),
        onToggle: (key) => _save(_learned.contains(key) ? (_learned.difference({key})) : {..._learned, key}),
      ),
    ]);
  }
}
