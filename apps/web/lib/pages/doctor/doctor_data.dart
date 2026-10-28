import 'package:fv_core/fv_core.dart';

/// Filled in by "Try an example": a small app with one of each kind of
/// problem, so the first run shows every part of the report.
const doctorExample = '''
name: my_app
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  provider: ^6.1.0
  shared_preferences: ^2.3.0
  intl: ^0.19.0
  dio: ^5.7.0
  pedantic: ^1.11.0
  uni_links: ^0.5.1
  my_design_system:
    git: https://github.com/acme/design_system
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
''';

/// One block of the report.
typedef ReportGroup = ({String title, String? note, List<DoctorEntry> entries});

/// Direct dependencies in three blocks, most urgent first. Empty blocks are
/// left out.
List<ReportGroup> reportGroups(DoctorReport report) {
  final direct = report.direct;
  return [
    (
      title: 'Needs attention',
      note: 'Alternatives share a category with the package. Check they fit before you switch.',
      entries: [
        for (final e in direct)
          if (e.status.needsAttention) e,
      ],
    ),
    (
      title: 'Looks good',
      note: null,
      entries: [
        for (final e in direct)
          if (e.status.good) e,
      ],
    ),
    (
      title: 'Couldn’t judge',
      note: 'Left out of the score.',
      entries: [
        for (final e in direct)
          if (!e.status.judged) e,
      ],
    ),
  ].where((g) => g.entries.isNotEmpty).toList();
}

/// `pubspec.yaml · 12 dependencies`: what the input was read as.
String inputSummary(ParsedDependencies p) {
  final n = p.dependencies.length;
  final noun = p.format == InputFormat.names ? 'package' : 'dependency';
  final plural = noun == 'package' ? 'packages' : 'dependencies';
  return '${p.format.label} · ${groupedNumber(n)} ${n == 1 ? noun : plural}';
}

/// Why a row has no verdict, or null when it has one.
String? statusNote(DoctorEntry e) => switch (e.status) {
  DoctorStatus.notTracked => 'Not among the packages Flutterverse tracks',
  DoctorStatus.notChecked => '${e.dependency.source.label} dependency: only pub.dev packages are checked',
  DoctorStatus.notEnoughData => 'Tracked, but its commit and release dates are unknown',
  _ => null,
};

/// The counts shown in the summary bar, in report order, zeroes dropped.
List<(DoctorStatus, int)> statusCounts(DoctorReport report) {
  final counts = report.counts;
  return [
    for (final s in DoctorStatus.values)
      if ((counts[s] ?? 0) > 0) (s, counts[s]!),
  ];
}
