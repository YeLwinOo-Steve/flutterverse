import 'package:fv_core/fv_core.dart';

import 'discovery.dart';
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

  // 1. Who to track: the seeds, plus (with discovery on) every Flutter
  // Favorite and pub.dev's most popular packages.
  List<String>? favorites;
  try {
    favorites = await pub.flutterFavorites();
    log?.call('pub.dev: ${favorites.length} Flutter Favorites');
  } on Object catch (e) {
    warn('pub.dev: Flutter Favorites search failed: $e');
  }
  final favoriteSet = favorites?.toSet() ?? const <String>{};
  final discovery = catalog.discovery;
  final curated = {for (final p in catalog.projects) p.id};
  var projects = [...catalog.projects];
  if (discovery.enabled) {
    var popular = const <String>[];
    if (discovery.pubTop > 0) {
      try {
        popular = await pub.popularPackages(discovery.pubTop);
      } on Object catch (e) {
        warn('pub.dev: popular packages failed: $e');
      }
    }
    final taken = {
      for (final p in projects) ...[p.id, ?p.pub],
    };
    final before = projects.length;
    for (final name in {...favoriteSet, ...popular}) {
      if (taken.add(name)) projects.add(discoveredPackage(name));
    }
    log?.call('pub.dev: discovered ${projects.length - before} packages');
  }

  // 2. pub.dev stats. The weekly download series costs a page scrape, so
  // only curated packages and Flutter Favorites get one.
  final pubStats = await _fetchPub(
    projects,
    pub,
    now,
    concurrency,
    log,
    warn,
    weekly: (p) => curated.contains(p.id) || favoriteSet.contains(p.pub),
  );

  // 3. Resolve repos from the pubspec when the seed doesn't name one.
  projects = [
    for (final p in projects) p.repo != null ? p : p.copyWith(repo: githubRepoFromUrl(pubStats[p.id]?.repository)),
  ];

  // 4. GitHub discovery: popular Dart repos not already tracked through a
  // package. Repo names are compared case-insensitively throughout.
  var found = const <String, GhStats>{};
  if (github != null && discovery.githubMinStars != null) {
    found = await github.searchDartRepos(discovery.githubMinStars!, onError: warn);
    final tracked = {for (final p in projects) ?p.repo?.toLowerCase()};
    final ids = {for (final p in projects) p.id};
    final before = projects.length;
    for (final MapEntry(key: repo, value: stats) in found.entries) {
      if (tracked.contains(repo.toLowerCase())) continue;
      final project = discoveredRepo(repo, stats, catalog.topicCategories);
      if (ids.add(project.id)) projects.add(project);
    }
    log?.call('GitHub: ${found.length} repos found, ${projects.length - before} new projects');
  }

  final omitted = _withoutRepoCounters(projects, curated);
  if (omitted.isNotEmpty) log?.call('GitHub: ${omitted.length} projects share a repo, counters omitted');

  // 5. GitHub stats for the rest. Contributors take one REST call each, so
  // only curated projects and Flutter Favorites get them.
  final gh = await _fetchGithub(
    projects,
    {
      for (final p in projects)
        if (!omitted.contains(p.id)) ?p.repo?.toLowerCase(),
    },
    catalog.hallOfFame,
    github,
    concurrency,
    log,
    warn,
    known: found,
    contributors: {
      for (final p in projects)
        if (curated.contains(p.id) || favoriteSet.contains(p.pub)) ?p.repo?.toLowerCase(),
    },
  );

  // 6. Discovered packages are categorised by their topics, name and
  // description.
  projects = [
    for (final p in projects)
      if (curated.contains(p.id) || p.pub == null)
        p
      else
        p.copyWith(
          categories: categorize(
            [...?pubStats[p.id]?.topics, ...?gh.repos[p.repo?.toLowerCase()]?.topics],
            catalog.topicCategories,
            name: p.name,
            description: pubStats[p.id]?.description,
            published: true,
          ),
        ),
  ];

  if (pubStats.isEmpty && gh.repos.isEmpty && projects.isNotEmpty) {
    warn('every source failed; leaving existing data untouched');
    return IngestResult(projects: projects.length, warnings: warnings, written: false);
  }

  // 7. History and per-project metrics.
  final today = Snapshot.dayOf(now);
  final built = <String, _Built>{};
  for (final project in projects) {
    var ps = pubStats[project.id];
    if (ps != null && favoriteSet.contains(project.pub)) ps = ps.copyWith(flutterFavorite: true);
    final repo = project.repo?.toLowerCase();
    var ghs = gh.repos[repo];
    if (ghs != null && omitted.contains(project.id)) ghs = ghs.withoutCounters();

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

  // 8. Momentum is relative to the whole population.
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

  // 9. Output.
  final rows = <ProjectRow>[];
  for (final b in built.values) {
    final row = ProjectRow.build(
      project: b.project,
      pub: b.pub,
      gh: b.gh,
      sharedRepo: omitted.contains(b.project.id),
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

/// The ids of projects whose repo-wide counters (stars, forks, issues)
/// are omitted because they share a repo with other tracked projects.
/// Each shared repo keeps one owner, which shows its counters: the one
/// curated project using it, or else the package named after the repo.
/// A monorepo curated more than once (`flutter/packages`) has no owner.
Set<String> _withoutRepoCounters(List<Project> projects, Set<String> curated) {
  final byRepo = <String, List<Project>>{};
  for (final p in projects) {
    if (p.repo?.toLowerCase() case final repo?) (byRepo[repo] ??= []).add(p);
  }
  final omit = <String>{};
  for (final MapEntry(key: repo, value: users) in byRepo.entries) {
    if (users.length < 2) continue;
    final owner = _repoOwner(repo, users, curated);
    omit.addAll([
      for (final p in users)
        if (p != owner) p.id,
    ]);
  }
  return omit;
}

Project? _repoOwner(String repo, List<Project> users, Set<String> curated) {
  final picked = users.where((p) => curated.contains(p.id)).toList();
  if (picked.isNotEmpty) return picked.length == 1 ? picked.single : null;
  // `rrousselGit/riverpod` → riverpod, `rodydavis/signals.dart` → signals.
  final name = repo.split('/').last.replaceAll(RegExp(r'\.dart$'), '').replaceAll('-', '_');
  return users.where((p) => (p.pub ?? p.id).toLowerCase() == name).firstOrNull;
}

Future<Map<String, PubStats>> _fetchPub(
  List<Project> projects,
  PubDevClient pub,
  DateTime now,
  int concurrency,
  void Function(String)? log,
  void Function(String) warn, {
  required bool Function(Project) weekly,
}) async {
  final published = projects.where((p) => p.pub != null).toList();
  log?.call('pub.dev: fetching ${published.length} packages');
  final out = <String, PubStats>{};
  await mapPool(published, concurrency, (project) async {
    try {
      final series = weekly(project);
      final stats = await pub.fetch(project.pub!, now: now, weekly: series);
      if (stats == null) {
        warn('pub.dev: package "${project.pub}" not found');
      } else {
        out[project.id] = stats;
        if (series && stats.weeklyDownloads == null) warn('pub.dev: no weekly downloads for ${project.pub}');
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
  Set<String> owned,
  HallOfFameEdition? hof,
  GithubClient? github,
  int concurrency,
  void Function(String)? log,
  void Function(String) warn, {
  Map<String, GhStats> known = const {},
  Set<String> contributors = const {},
}) async {
  // Everything here is keyed by the lowercased `owner/name`.
  final have = {for (final e in known.entries) e.key.toLowerCase(): e.value};
  final missing = {
    for (final p in projects)
      if (p.repo?.toLowerCase() case final repo? when !have.containsKey(repo)) repo,
  };
  if (github == null) {
    warn('GitHub: no GITHUB_TOKEN set, skipping ${missing.length} repos');
    return const _GithubData({}, {});
  }
  log?.call('GitHub: fetching ${missing.length} repos');
  final fetched = await github.fetchAll(missing, onError: warn);
  final stats = {...have, for (final e in fetched.entries) e.key.toLowerCase(): e.value};

  // Contributors need one REST call per repo; skip repos whose counters are
  // omitted for everyone using them.
  final counted = <String, GhStats>{};
  final wanted = stats.entries.where((e) => contributors.contains(e.key) && owned.contains(e.key));
  await mapPool(wanted, concurrency, (e) async {
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
