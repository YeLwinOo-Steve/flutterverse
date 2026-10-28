import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../components/project/table_extras.dart';
import '../../data/data_repo.dart';
import '../../data/track.dart';
import '../../styles/css.dart';
import 'doctor_data.dart';
import 'doctor_input.dart';
import 'doctor_results.dart';
import 'share_card.dart';

/// `/doctor`'s interactive part: the paste box and the report. Everything
/// runs in the browser against `index.json`, so nothing is uploaded.
@client
class DoctorTool extends StatefulComponent {
  const DoctorTool({required this.now, super.key});

  /// ISO timestamp of the data snapshot: verdicts are judged as of then.
  final String now;

  @override
  State<DoctorTool> createState() => _DoctorToolState();

  @css
  static List<StyleRule> get styles => [
    rule('.doc-tool', {'display': 'flex', 'flex-direction': 'column', 'gap': '32px'}),
  ];
}

class _DoctorToolState extends State<DoctorTool> {
  String _text = '';
  int _revision = 0;
  ParsedDependencies? _parsed;
  String? _error;

  IndexFile? _index;
  DiscontinuedFile _discontinued = const DiscontinuedFile();
  bool _loadFailed = false;

  /// A check was asked for before the data arrived; it runs on arrival.
  bool _waiting = false;
  DoctorReport? _report;

  DateTime get _now => DateTime.parse(component.now);

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _load();
  }

  // Started on page load, so the 650 KB index is usually here by the time
  // anything has been pasted.
  void _load() {
    Future.wait([DataRepo.index(), DataRepo.discontinued()]).then(
      (data) => setState(() {
        _index = data[0] as IndexFile;
        _discontinued = data[1] as DiscontinuedFile;
        _loadFailed = false;
        if (_waiting) _run();
      }),
      onError: (Object _) => setState(() {
        _loadFailed = true;
        _waiting = false;
      }),
    );
  }

  void _setText(String text, {bool replace = false}) {
    setState(() {
      _text = text;
      if (replace) _revision++;
      try {
        final parsed = text.trim().isEmpty ? null : parseDependencies(text);
        _parsed = parsed;
        _error = parsed != null && parsed.dependencies.isEmpty ? _emptyMessage(parsed) : null;
      } on FormatException catch (e) {
        _parsed = null;
        _error = e.message;
      }
    });
  }

  static String _emptyMessage(ParsedDependencies p) => p.format == InputFormat.names
      ? 'No package names found${p.ignored.isEmpty ? '' : ' (ignored ${p.ignored.take(3).join(', ')})'}.'
      : 'No pub.dev dependencies found in this ${p.format.label}.';

  void _check() {
    if (_parsed == null || _error != null) return;
    if (_index == null) {
      setState(() => _waiting = true);
      if (_loadFailed) _load();
      return;
    }
    setState(_run);
  }

  /// Builds the report; call inside [setState].
  void _run() {
    _waiting = false;
    final report = diagnose(_parsed!, _index!, discontinued: _discontinued, now: _now);
    _report = report;
    track('doctor_run', {
      'format': report.format.name,
      'direct': report.direct.length,
      'transitive': report.transitive.length,
      'score': ?report.score,
      for (final MapEntry(:key, :value) in report.counts.entries) key.name: value,
    });
    // After this frame renders, bring the report into view.
    Future(() {
      final el = web.document.getElementById('doctor-report');
      el?.scrollIntoView(web.ScrollIntoViewOptions(behavior: 'smooth', block: 'start'));
    });
  }

  void _share() {
    final report = _report;
    if (report == null) return;
    downloadShareCard(report, dataDate: fullDate(_now));
    track('doctor_share', {'score': ?report.score});
  }

  @override
  Component build(BuildContext context) {
    final parsed = _parsed;
    final ignored = parsed?.ignored ?? const <String>[];
    return div(classes: 'doc-tool', [
      DoctorInput(
        text: _text,
        revision: _revision,
        hint: parsed == null
            ? null
            : '${inputSummary(parsed)}${ignored.isEmpty ? '' : ' · ignored ${ignored.length} other words'}',
        error: _error,
        busy: _waiting,
        onInput: _setText,
        onLoad: (t) => _setText(t, replace: true),
        onCheck: _check,
        onExample: () => _setText(doctorExample.trim(), replace: true),
        onClear: () {
          _report = null;
          _setText('', replace: true);
        },
      ),
      if (_loadFailed && _report == null)
        const TableEmpty(
          title: 'Couldn’t load package data',
          message: 'Check your connection, then press Check dependencies to try again.',
        ),
      if (_report case final report?) DoctorResults(report: report, dataDate: fullDate(_now), onShare: _share),
    ]);
  }
}
