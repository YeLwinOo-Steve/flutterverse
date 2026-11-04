import 'package:fv_core/fv_core.dart';

import '../http_util.dart';
import '../writers/json_writer.dart';
import 'ats/job_board.dart';
import 'hn_hiring.dart';
import 'jobs_config.dart';
import 'jobs_store.dart';
import 'posting.dart';
import 'company_search.dart';

/// Hacker News rows use this as their company id.
const hnCompanyId = 'hn';

/// The state key for a cross-company search, which spans many companies:
/// its source's name, e.g. `workable`.
String searchStateKey(CompanySearch search) => search.source.name;

/// Most rows kept per company, title matches first.
const maxPerCompany = 25;

/// Most rows in `jobs.json`.
const maxJobs = 500;

/// How many days a failing company's roles stay listed.
const carryOverDays = 3;

/// A company failing this many runs in a row gets a warning.
const failWarnAfter = 7;

class JobsResult {
  const JobsResult({required this.jobs, required this.failed, required this.warnings});

  final int jobs;
  final List<String> failed;
  final List<String> warnings;
}

/// Fetches every company's roles, keeps the Flutter ones and writes
/// `jobs.json` through [writer], plus the state for the next run.
///
/// One company failing never fails the run: its roles from earlier runs are
/// carried over for up to [carryOverDays] days, then dropped. A role missing
/// from a successful fetch is gone.
Future<JobsResult> runJobs({
  required List<JobCompany> companies,
  required Map<JobSource, JobBoard> boards,
  required JobsStore store,
  required JsonWriter writer,
  required DateTime now,
  HnHiring? hn,
  List<CompanySearch> searches = const [],
  Set<String> exclude = const {},
  int concurrency = 4,
  void Function(String)? log,
}) async {
  final warnings = <String>[];
  void warn(String m) {
    warnings.add(m);
    log?.call('WARN: $m');
  }

  final today = Snapshot.dayOf(now);
  final prev = store.read();
  final prevById = {for (final j in prev.jobs) j.id: j};
  final states = <String, CompanyState>{};
  final failed = <String>[];
  final jobs = <Job>[];

  // Keeps the roles a failed source had last time, while they're recent.
  // [belongs] picks its rows; by default, the rows of company [companyId].
  void carryOver(String companyId, [bool Function(Job)? belongs]) {
    final state = prev.companies[companyId];
    final streak = (state?.failStreak ?? 0) + 1;
    states[companyId] = CompanyState(lastOk: state?.lastOk, failStreak: streak);
    failed.add(companyId);
    if (streak >= failWarnAfter) warn('jobs: $companyId has failed $streak runs in a row');
    final lastOk = state?.lastOk;
    if (lastOk == null || now.difference(DateTime.parse(lastOk)).inDays > carryOverDays) return;
    jobs.addAll(prev.jobs.where(belongs ?? (j) => j.companyId == companyId));
  }

  void keep(String companyId, List<Job> found) {
    states[companyId] = CompanyState(lastOk: today);
    jobs.addAll(_capPerCompany(_dedupe(found)));
  }

  Job? toJob(Posting p, {required JobSource source, required String companyId, String? name, String? careers}) {
    final match = flutterMatch(p.title, p.text);
    if (match == null) return null;
    final id = '${source.name}:$companyId:${p.id}';
    return Job(
      id: id,
      title: p.title,
      company: p.company ?? name ?? companyId,
      companyId: companyId,
      companyUrl: careers,
      url: p.url,
      location: p.location,
      remote: p.remote,
      source: source,
      match: match,
      firstSeen: prevById[id]?.firstSeen ?? today,
    );
  }

  final fetched = await mapPool(companies, concurrency, (c) async {
    final board = boards[c.ats];
    if (board == null) return null;
    try {
      return await board.fetch(c);
    } on Object catch (e) {
      warn('jobs: ${c.id} (${c.atsName}) failed: $e');
      return null;
    }
  });
  for (final (i, c) in companies.indexed) {
    final postings = fetched[i];
    if (postings == null) {
      carryOver(c.id);
    } else {
      keep(c.id, [
        for (final p in postings) ?toJob(p, source: c.ats!, companyId: c.id, name: c.name, careers: c.careers),
      ]);
    }
  }

  if (hn != null) {
    try {
      final posts = await hn.fetch();
      keep(hnCompanyId, [for (final p in posts) ?toJob(p, source: JobSource.hn, companyId: hnCompanyId)]);
    } on Object catch (e) {
      warn('jobs: Hacker News failed: $e');
      carryOver(hnCompanyId);
    }
  }

  // Companies listed directly are read from their own board instead.
  final listed = {for (final c in companies) normalizeCompany(c.name)};
  for (final search in searches) {
    final key = searchStateKey(search);
    try {
      final byCompany = <String, List<Job>>{};
      for (final p in await search.fetch()) {
        final name = normalizeCompany(p.company!);
        if (exclude.contains(name) || listed.contains(name)) continue;
        final id = search.companyId(p.company!);
        if (toJob(p, source: search.source, companyId: id) case final job?) (byCompany[id] ??= []).add(job);
      }
      states[key] = CompanyState(lastOk: today);
      for (final found in byCompany.values) {
        jobs.addAll(_capPerCompany(_dedupe(found)));
      }
    } on Object catch (e) {
      warn('jobs: ${search.source.label} feed failed: $e');
      carryOver(key, (j) => j.source == search.source);
    }
  }

  final sorted = (jobs..sort(compareJobs)).take(maxJobs).toList();
  final companyCount = {for (final j in sorted) j.companyId}.length;
  writer.write(
    'jobs.json',
    JobsFile(generatedAt: now, companies: companyCount, failed: failed, jobs: sorted).toJson(),
  );
  store.write(JobsState(jobs: sorted, companies: states));
  log?.call('jobs: ${sorted.length} roles from $companyCount companies, ${failed.length} sources failed');
  return JobsResult(jobs: sorted.length, failed: failed, warnings: warnings);
}

/// Companies repost one role per office: the same title counts once, and
/// its other locations fold into the first ("Lagos +7 more"). The row is
/// remote if any copy is.
List<Job> _dedupe(List<Job> jobs) {
  final groups = <String, List<Job>>{};
  for (final j in jobs) {
    (groups[j.title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()] ??= []).add(j);
  }
  return [
    for (final g in groups.values)
      if (g.length == 1)
        g.single
      else
        g.first.copyWith(
          location: switch ({for (final j in g) ?j.location}.toList()) {
            [] => null,
            [final one] => one,
            [final first, ...final rest] => '$first +${rest.length} more',
          },
          remote: g.any((j) => j.remote == true) ? true : null,
        ),
  ];
}

List<Job> _capPerCompany(List<Job> jobs) => (jobs..sort(compareJobs)).take(maxPerCompany).toList();
