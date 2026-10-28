import '../metrics/verdict.dart';
import '../models/discontinued.dart';
import '../models/output.dart';
import 'dependencies.dart';

/// One row's state in a Doctor report: a [Verdict], or why there's none.
enum DoctorStatus {
  replaceNow('Replace now'),
  atRisk('At risk'),
  watch('Watch'),
  healthy('Healthy'),
  stable('Stable'),
  notEnoughData('Not enough data'),
  notTracked('Not tracked'),
  notChecked('Not checked');

  const DoctorStatus(this.label);
  final String label;

  static DoctorStatus of(Verdict v) => switch (v) {
    Verdict.replaceNow => replaceNow,
    Verdict.healthy => healthy,
    Verdict.stable => stable,
    Verdict.watch => watch,
    Verdict.atRisk => atRisk,
  };

  /// A [Verdict] status that counts toward the score.
  bool get judged => index <= stable.index;
  bool get good => this == healthy || this == stable;
  bool get needsAttention => this == replaceNow || this == atRisk || this == watch;
}

/// A suggested replacement. Not a drop-in one: the UI says so.
class Alternative {
  const Alternative({required this.name, this.row, this.verdict, this.suggestedByPub = false});

  /// The pub.dev package name.
  final String name;

  /// Null when the package isn't tracked.
  final ProjectRow? row;
  final VerdictResult? verdict;

  /// pub.dev's `replacedBy` for a discontinued package.
  final bool suggestedByPub;
}

class DoctorEntry {
  const DoctorEntry({
    required this.dependency,
    required this.status,
    this.row,
    this.result,
    this.alternatives = const [],
  });

  final Dependency dependency;
  final DoctorStatus status;
  final ProjectRow? row;
  final VerdictResult? result;
  final List<Alternative> alternatives;

  String get name => dependency.name;
  bool get direct => dependency.kind != DependencyKind.transitive;
}

class DoctorReport {
  const DoctorReport({required this.entries, this.format = InputFormat.names, this.project});

  /// Most urgent first; in the pasted order within a status.
  final List<DoctorEntry> entries;
  final InputFormat format;
  final String? project;

  List<DoctorEntry> get direct => [
    for (final e in entries)
      if (e.direct) e,
  ];

  List<DoctorEntry> get transitive => [
    for (final e in entries)
      if (!e.direct) e,
  ];

  /// How many direct dependencies have each status.
  Map<DoctorStatus, int> get counts {
    final out = <DoctorStatus, int>{};
    for (final e in direct) {
      out[e.status] = (out[e.status] ?? 0) + 1;
    }
    return out;
  }

  /// Direct dependencies with a verdict.
  int get judged => direct.where((e) => e.status.judged).length;

  /// The project score: the share of judged direct dependencies that are
  /// Healthy or Stable, 0–100. Not tracked, Not checked and Not enough data
  /// are left out. Transitive ones are too, since the user never chose them.
  /// Null when nothing could be judged.
  int? get score {
    final n = judged;
    if (n == 0) return null;
    return (100 * direct.where((e) => e.status.good).length / n).round();
  }
}

/// How many alternatives to suggest beyond pub.dev's own.
const _alternatives = 2;

/// Judges every dependency in [input] against the tracked [index].
DoctorReport diagnose(
  ParsedDependencies input,
  IndexFile index, {
  DiscontinuedFile discontinued = const DiscontinuedFile(),
  required DateTime now,
}) {
  final byPub = {for (final r in index.projects) ?r.pub: r};
  final verdicts = <String, VerdictResult?>{};
  VerdictResult? judge(String name) => verdicts.putIfAbsent(
    name,
    () => verdictOf(
      byPub[name],
      now: now,
      discontinued: discontinued.contains(name),
      replacedBy: discontinued.packages[name],
    ),
  );

  final used = {for (final d in input.dependencies) d.name};
  final entries = <DoctorEntry>[];
  for (final dep in input.dependencies) {
    if (dep.source != DependencySource.hosted) {
      entries.add(DoctorEntry(dependency: dep, status: DoctorStatus.notChecked));
      continue;
    }
    final row = byPub[dep.name];
    final result = judge(dep.name);
    final status = switch (result?.verdict) {
      final v? => DoctorStatus.of(v),
      null when result == null => DoctorStatus.notTracked,
      null => DoctorStatus.notEnoughData,
    };
    entries.add(
      DoctorEntry(
        dependency: dep,
        status: status,
        row: row,
        result: result,
        alternatives: status.needsAttention ? _alternativesFor(row, result, index, byPub, used, judge) : const [],
      ),
    );
  }
  // A stable sort: Dart's List.sort isn't, so break ties by pasted order.
  final order = {for (final (i, e) in entries.indexed) e: i};
  entries.sort((a, b) {
    final c = a.status.index.compareTo(b.status.index);
    return c != 0 ? c : order[a]!.compareTo(order[b]!);
  });
  return DoctorReport(entries: entries, format: input.format, project: input.project);
}

/// pub.dev's `replacedBy` first, then up to [_alternatives] Healthy or
/// Stable packages that share a category and SDK with [row] and overlap on
/// platforms, highest momentum first (then most downloaded). Packages already in use are skipped.
List<Alternative> _alternativesFor(
  ProjectRow? row,
  VerdictResult? result,
  IndexFile index,
  Map<String, ProjectRow> byPub,
  Set<String> used,
  VerdictResult? Function(String) judge,
) {
  final out = <Alternative>[];
  if (result?.replacedBy case final r?) {
    out.add(Alternative(name: r, row: byPub[r], verdict: judge(r), suggestedByPub: true));
  }
  if (row == null) return out;
  // `other` holds whatever matched no topic: sharing it says nothing.
  final categories = row.categories.where((c) => c != 'other').toSet();
  if (categories.isEmpty) return out;
  final candidates =
      [
        for (final r in index.projects)
          if (r.pub case final pub?
              when pub != row.pub &&
                  !used.contains(pub) &&
                  !out.any((a) => a.name == pub) &&
                  r.sdk == row.sdk &&
                  r.categories.any(categories.contains) &&
                  (row.platforms.isEmpty || r.platforms.isEmpty || r.platforms.any(row.platforms.contains)) &&
                  (judge(pub)?.verdict?.good ?? false))
            r,
      ]..sort((a, b) {
        final c = (b.momentum ?? -1).compareTo(a.momentum ?? -1);
        return c != 0 ? c : (b.downloads ?? -1).compareTo(a.downloads ?? -1);
      });
  for (final r in candidates.take(_alternatives)) {
    out.add(Alternative(name: r.pub!, row: r, verdict: judge(r.pub!)));
  }
  return out;
}
