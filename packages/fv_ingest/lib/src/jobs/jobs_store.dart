import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';

/// What one company looked like on the last run.
class CompanyState {
  const CompanyState({this.lastOk, this.failStreak = 0});

  /// The last UTC day its fetch succeeded.
  final String? lastOk;

  /// Failed runs in a row.
  final int failStreak;

  factory CompanyState.fromJson(Json json) =>
      CompanyState(lastOk: json['lastOk'] as String?, failStreak: (json['failStreak'] as num?)?.toInt() ?? 0);

  Json toJson() => {'lastOk': ?lastOk, if (failStreak > 0) 'failStreak': failStreak};
}

/// The jobs step's memory between runs (`history/jobs.json`): every row it
/// wrote last time, for first-seen days and carry-over, and each company's
/// [CompanyState].
class JobsState {
  const JobsState({this.jobs = const [], this.companies = const {}});

  final List<Job> jobs;
  final Map<String, CompanyState> companies;

  factory JobsState.fromJson(Json json) => JobsState(
    jobs: [for (final j in json['jobs'] as List<Object?>? ?? const []) Job.fromJson(j! as Json)],
    companies: {
      for (final e in (json['companies'] as Json? ?? const {}).entries) e.key: CompanyState.fromJson(e.value! as Json),
    },
  );

  Json toJson() => {
    'jobs': [for (final j in jobs) j.toJson()],
    'companies': {for (final k in companies.keys.toList()..sort()) k: companies[k]!.toJson()},
  };
}

/// Reads and writes [JobsState] at [path]. A missing or unreadable file is
/// a fresh start, never a failed run.
class JobsStore {
  JobsStore(this.path);

  final String path;

  JobsState read() {
    final file = File(path);
    if (!file.existsSync()) return const JobsState();
    try {
      return JobsState.fromJson(jsonDecode(file.readAsStringSync()) as Json);
    } on FormatException {
      return const JobsState();
    }
  }

  void write(JobsState state) => File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(state.toJson()));
}
