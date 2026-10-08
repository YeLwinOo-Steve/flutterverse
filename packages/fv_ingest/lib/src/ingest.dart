import 'package:fv_core/fv_core.dart';

import 'http_util.dart';
import 'sources/github_graphql.dart';
import 'sources/pub_dev.dart';
import 'writers/history_store.dart';
import 'writers/json_writer.dart';

class IngestResult {
  const IngestResult({required this.projects, required this.warnings, required this.written});

  final int projects;
  final List<String> warnings;

  /// False when every source failed and nothing was written.
  final bool written;
}

/// fetch → normalise → score → write. One failing package or source never
/// fails the run: its values become null (shown as "N/A" on the site).
Future<IngestResult> runIngest({
  required Catalog catalog,
  required PubDevClient pub,
  required GithubClient? github,
  required HistoryStore history,
  required JsonWriter writer,
  required DateTime now,
  int concurrency = 4,
  void Function(String)? log,
}) async {
  final warnings = <String>[];
  void warn(String m) {
    warnings.add(m);
    log?.call('WARN $m');
  }

  // 1. pub.dev
  final pubStats = await _fetchPub(catalog, pub, now, concurrency, log, warn);
  List<String>? favorites;
  try {
    favorites = await pub.flutterFavorites();
    log?.call('pub.dev: ${favorites.length} Flutter Favorites');
  } on Object catch (e) {
    warn('pub.dev: Flutter Favorites search failed: $e');
  }
  final favoriteSet = favorites?.toSet() ?? const <String>{};

  // 2. Resolve repos from the pubspec when the seed doesn't name one.
  final projects = [
    for (final p in catalog.projects)
      p.repo != null ? p : p.copyWith(repo: githubRepoFromUrl(pubStats[p.id]?.repository)),
  ];
  final shared = _sharedRepos(projects);
  if (shared.isNotEmpty) log?.call('GitHub: shared monorepos, counters omitted: ${shared.join(', ')}');

  // 3. GitHub
  final gh = await _fetchGithub(projects, shared, catalog.hallOfFame, github, concurrency, log, warn);

  if (pubStats.isEmpty && gh.repos.isEmpty && projects.isNotEmpty) {
    warn('every source failed; leaving existing data untouched');
    return IngestResult(projects: projects.length, warnings: warnings, written: false);
  }

  // 4. History and per-project metrics.
  final today = Snapshot.dayOf(now);
  final built = <String, _Built>{};
  for (final project in projects) {
    var ps = pubStats[project.id];
    if (ps != null && favoriteSet.contains(project.pub)) ps = ps.copyWith(flutterFavorite: true);
    var ghs = project.repo == null ? null : gh.repos[project.repo];
    if (ghs != null && shared.contains(project.repo)) ghs = ghs.withoutCounters();

    final snaps = history.upsert(
      project.id,
      Snapshot(
        date: today,
        stars: ghs?.stars,
        forks: ghs?.forks,
        openIssues: ghs?.openIssues,
        likes: ps?.likes,
        points: ps?.points,
        downloads: ps?.downloads,
      ),
    );
    built[project.id] = _Built(project, ps, ghs, snaps);
  }

  // 5. Momentum is relative to the whole population.
  final scores = momentumScores({
    for (final b in built.values)
      b.project.id: MomentumInput(
        stars: b.gh?.stars,
        stars7d: starGrowth(b.history, 7),
        stars30d: starGrowth(b.history, 30),
        daysSinceCommit: _days(b.gh?.lastCommit ?? b.gh?.pushedAt, now),
        daysSinceRelease: _days(b.pub?.published, now),
        downloadGrowth: b.pub?.downloadGrowth,
      ),
  });

  // 6. Output.
  final rows = <ProjectRow>[];
  for (final b in built.values) {
    final row = ProjectRow.build(
      project: b.project,
      pub: b.pub,
      gh: b.gh,
      sharedRepo: shared.contains(b.project.repo),
      stars1d: starGrowth(b.history, 1),
      stars7d: starGrowth(b.history, 7),
      stars30d: starGrowth(b.history, 30),
      stars365d: starGrowth(b.history, 365),
      momentum: scores[b.project.id],
      maintenance: maintenance(lastCommit: b.gh?.lastCommit, lastRelease: b.pub?.published, now: now),
      spark: dailyStarGains(b.history),
    );
    rows.add(row);
    writer.write(
      'p/${b.project.id}.json',
      ProjectDetail(row: row, pub: b.pub, gh: b.gh, history: b.history, related: b.project.related).toJson(),
    );
  }
  writer.prune('p', {for (final p in projects) '${p.id}.json'});

  final hof = catalog.hallOfFame;
  writer
    ..write(
      'index.json',
      IndexFile(categories: catalog.categories, categoryGroups: catalog.categoryGroups, projects: rows).toJson(),
    )
    ..write('pub.json', PubFile(flutterFavorites: favorites).toJson())
    ..write(
      'hof.json',
      HallOfFameFile(
        edition: hof == null
            ? null
            : HallOfFameEdition(
                year: hof.year,
                projects: hof.projects,
                developers: [
                  for (final d in hof.developers)
                    d.withStats(followers: gh.users[d.handle]?.$1, repos: gh.users[d.handle]?.$2),
                ],
              ),
      ).toJson(),
    )
    ..write('roadmap.json', RoadmapFile(tracks: catalog.roadmap).toJson())
    ..write('meta.json', Meta(generatedAt: now, projectCount: rows.length).toJson());

  return IngestResult(projects: rows.length, warnings: warnings, written: true);
}

class _Built {
  _Built(this.project, this.pub, this.gh, this.history);

  final Project project;
  final PubStats? pub;
  final GhStats? gh;
  final List<Snapshot> history;
}

int? _days(DateTime? t, DateTime now) => t == null ? null : now.difference(t).inDays;

/// Repos used by more than one tracked project (e.g. `flutter/packages`).
Set<String> _sharedRepos(List<Project> projects) {
  final use = <String, int>{};
  for (final p in projects) {
    if (p.repo != null) use[p.repo!] = (use[p.repo!] ?? 0) + 1;
  }
  return {
    for (final e in use.entries)
      if (e.value > 1) e.key,
  };
}

Future<Map<String, PubStats>> _fetchPub(
  Catalog catalog,
  PubDevClient pub,
  DateTime now,
  int concurrency,
  void Function(String)? log,
  void Function(String) warn,
) async {
  final published = catalog.projects.where((p) => p.pub != null).toList();
  log?.call('pub.dev: fetching ${published.length} packages');
  final out = <String, PubStats>{};
  await mapPool(published, concurrency, (project) async {
    try {
      final stats = await pub.fetch(project.pub!, now: now);
      if (stats == null) {
        warn('pub.dev: package "${project.pub}" not found');
      } else {
        out[project.id] = stats;
        if (stats.weeklyDownloads == null) warn('pub.dev: no weekly downloads for ${project.pub}');
      }
    } on Object catch (e) {
      warn('pub.dev: ${project.pub}: $e');
    }
  });
  return out;
}

class _GithubData {
  const _GithubData(this.repos, this.users);

  final Map<String, GhStats> repos;
  final Map<String, (int?, int?)> users;
}

Future<_GithubData> _fetchGithub(
  List<Project> projects,
  Set<String> shared,
  HallOfFameEdition? hof,
  GithubClient? github,
  int concurrency,
  void Function(String)? log,
  void Function(String) warn,
) async {
  final repos = {for (final p in projects) ?p.repo};
  if (github == null) {
    warn('GitHub: no GITHUB_TOKEN set, skipping ${repos.length} repos');
    return const _GithubData({}, {});
  }
  log?.call('GitHub: fetching ${repos.length} repos');
  final stats = await github.fetchAll(repos, onError: warn);

  // Contributors need one REST call per repo; skip shared monorepos, whose
  // counters are omitted anyway.
  final counted = <String, GhStats>{};
  await mapPool(stats.entries.where((e) => !shared.contains(e.key)), concurrency, (e) async {
    int? n;
    try {
      n = await github.contributors(e.key);
    } on Object catch (err) {
      warn('GitHub: contributors for ${e.key}: $err');
    }
    counted[e.key] = _withContributors(e.value, n);
  });

  final logins = [for (final d in hof?.developers ?? const <HallOfFameDeveloper>[]) d.handle];
  final users = logins.isEmpty ? <String, (int?, int?)>{} : await github.fetchUsers(logins, onError: warn);
  return _GithubData({...stats, ...counted}, users);
}

GhStats _withContributors(GhStats g, int? n) => GhStats(
  stars: g.stars,
  forks: g.forks,
  openIssues: g.openIssues,
  watchers: g.watchers,
  contributors: n,
  createdAt: g.createdAt,
  pushedAt: g.pushedAt,
  lastCommit: g.lastCommit,
  license: g.license,
  languages: g.languages,
  topics: g.topics,
  archived: g.archived,
  description: g.description,
);
