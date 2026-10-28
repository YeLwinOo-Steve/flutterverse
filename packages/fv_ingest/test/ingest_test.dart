import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('fv_ingest'));
  tearDown(() => tmp.deleteSync(recursive: true));

  final catalog = parseSeeds('''
categories: {networking: Networking}
projects:
  - {id: dio, pub: dio, categories: [networking], related: [broken]}
  - {id: broken, pub: broken_pkg, categories: [networking]}
hall_of_fame:
  year: 2026
  projects: [{id: dio, category: Most Starred, reason: Everyone uses it.}]
  developers: [{handle: someone, name: Some One, category: X, tagline: Y, projects: [dio]}]
''', roadmapJson: '{"dart":{"name":"Dart","intro":"i","stages":[]}}');

  final pubMock = MockClient((req) async {
    return switch (req.url.path) {
      '/api/packages/dio' => http.Response(
        jsonEncode({
          'latest': {
            'version': '5.0.0',
            'published': '2026-09-20T00:00:00Z',
            'pubspec': {'repository': 'https://github.com/cfug/dio'},
          },
        }),
        200,
      ),
      '/api/packages/dio/score' => http.Response(jsonEncode({'likeCount': 7, 'tags': <String>[]}), 200),
      '/api/search' => http.Response(
        jsonEncode({
          'packages': [
            {'package': 'dio'},
          ],
        }),
        200,
      ),
      '/packages/dio/score' => http.Response('<html></html>', 200),
      _ => http.Response('boom', 500),
    };
  });

  GithubClient github(int stars, {http.Response Function()? activity}) => GithubClient(
    MockClient((req) async {
      if (req.url.path.endsWith('/contributors')) return http.Response('[{},{}]', 200);
      if (req.url.path.endsWith('/stats/commit_activity')) return activity?.call() ?? http.Response('', 500);
      final query = (jsonDecode(req.body) as Map)['query'] as String;
      if (query.contains('user(')) {
        return http.Response(
          jsonEncode({
            'data': {
              'r0': {
                'followers': {'totalCount': 42},
                'repositories': {'totalCount': 5},
              },
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'data': {
            'r0': {
              'stargazerCount': stars,
              'pushedAt': '2026-10-01T00:00:00Z',
              'defaultBranchRef': {
                'target': {'committedDate': '2026-10-01T00:00:00Z'},
              },
            },
          },
        }),
        200,
      );
    }),
    token: 't',
    retryDelay: Duration.zero,
  );

  Map<String, Object?> readJson(String rel) =>
      jsonDecode(File(p.join(tmp.path, 'out', rel)).readAsStringSync()) as Map<String, Object?>;

  Future<IngestResult> run(DateTime now, int stars, {Catalog? seeds}) => runIngest(
    catalog: seeds ?? catalog,
    pub: PubDevClient(pubMock, retryDelay: Duration.zero),
    github: github(stars),
    history: HistoryStore(p.join(tmp.path, 'history')),
    writer: JsonWriter(p.join(tmp.path, 'out')),
    now: now,
  );

  test('writes every file, keeps going past a failing package, builds history', () async {
    final first = await run(DateTime.utc(2026, 10, 1, 3), 1000);
    expect(first.written, isTrue);
    expect(first.warnings, contains(contains('broken_pkg')));

    // Re-running on the same day replaces that day's snapshot.
    await run(DateTime.utc(2026, 10, 1, 9), 1005);
    await run(DateTime.utc(2026, 10, 2, 3), 1015);

    final index = IndexFile.fromJson(readJson('index.json'));
    final dio = index.projects.firstWhere((r) => r.id == 'dio');
    expect(dio.repo, 'cfug/dio', reason: 'derived from the pubspec');
    expect(dio.owner, 'cfug');
    expect(dio.stars, 1015);
    expect(dio.stars1d, 10);
    expect(dio.stars7d, isNull, reason: 'only 1 day of history');
    expect(dio.likes, 7);
    expect(dio.flutterFavorite, isTrue);
    expect(dio.maintenance, Maintenance.active);
    expect(dio.spark!.last, 10);

    final broken = index.projects.firstWhere((r) => r.id == 'broken');
    expect(broken.stars, isNull);
    expect(broken.likes, isNull);

    final detail = ProjectDetail.fromJson(readJson('p/dio.json'));
    expect(detail.history.map((s) => s.stars), [1005, 1015]);
    expect(detail.gh!.contributors, 2);
    expect(detail.related, ['broken']);

    final hof = HallOfFameFile.fromJson(readJson('hof.json')).edition!;
    expect(hof.developers.single.followers, 42);
    expect(RoadmapFile.fromJson(readJson('roadmap.json')).tracks.keys, ['dart']);
    expect(PubFile.fromJson(readJson('pub.json')).flutterFavorites, ['dio']);
    expect(Meta.fromJson(readJson('meta.json')).schema, schemaVersion);
  });

  test('writes discontinued.json and a badge per judged package', () async {
    Map<String, Object?> info({Map<String, Object?> deps = const {}, bool discontinued = false, String? by}) => {
      'isDiscontinued': discontinued,
      'replacedBy': ?by,
      'latest': {
        'version': '1.0.0',
        'published': '2026-09-20T00:00:00Z',
        'pubspec': {'repository': 'https://github.com/cfug/dio', 'dependencies': deps},
      },
    };
    final pub = MockClient((req) async {
      return switch (req.url.path) {
        '/api/packages/dio' => http.Response(
          jsonEncode(
            info(
              deps: {
                'pedantic': '^1.0.0',
                'meta': '^1.0.0',
                'flutter': {'sdk': 'flutter'},
                'mine': {'path': '../mine'},
              },
            ),
          ),
          200,
        ),
        '/api/packages/old' => http.Response(jsonEncode(info(discontinued: true)), 200),
        '/api/packages/pedantic' => http.Response(jsonEncode(info(discontinued: true, by: 'lints')), 200),
        '/api/packages/meta' => http.Response(jsonEncode(info()), 200),
        '/api/packages/js' => http.Response(jsonEncode(info(discontinued: true)), 200),
        '/api/search' => http.Response(jsonEncode({'packages': <Object>[]}), 200),
        _ when req.url.path.endsWith('/score') => http.Response(jsonEncode({'tags': <String>[]}), 200),
        _ => http.Response('', 404),
      };
    });
    final requested = <String>[];
    await runIngest(
      catalog: parseSeeds('''
discovery: {discontinued_watch: [js, dio]}
categories: {networking: Networking}
projects:
  - {id: dio, pub: dio, categories: [networking]}
  - {id: old, pub: old, repo: a/old, categories: [networking]}
'''),
      pub: PubDevClient(
        MockClient((req) {
          requested.add(req.url.path);
          return pub.send(http.Request(req.method, req.url)).then(http.Response.fromStream);
        }),
        retryDelay: Duration.zero,
      ),
      github: github(10),
      history: HistoryStore(p.join(tmp.path, 'history')),
      writer: JsonWriter(p.join(tmp.path, 'out')),
      now: DateTime.utc(2026, 10, 2),
    );

    expect(DiscontinuedFile.fromJson(readJson('discontinued.json')).packages, {
      'js': null,
      'old': null,
      'pedantic': 'lints',
    });
    expect(requested, isNot(contains('/api/packages/mine')), reason: 'path dependencies are skipped');
    expect(requested.where((r) => r == '/api/packages/dio'), hasLength(1), reason: 'tracked: not looked up again');
    expect(readJson('badge/dio.json'), {
      'schemaVersion': 1,
      'label': 'Flutterverse',
      'message': 'Healthy',
      'color': '0468D7',
    });
    expect(readJson('badge/old.json')['message'], 'Replace now');
  });

  test('omits repo-wide counters for packages sharing a monorepo', () async {
    final result = await run(
      DateTime.utc(2026, 10, 1),
      5000,
      seeds: parseSeeds('''
categories: {ui: UI}
projects:
  - {id: a, repo: flutter/packages, categories: [ui]}
  - {id: b, repo: flutter/packages, categories: [ui]}
'''),
    );
    expect(result.written, isTrue);
    final rows = IndexFile.fromJson(readJson('index.json')).projects;
    expect(rows.map((r) => r.stars), [null, null]);
    expect(rows.map((r) => r.sharedRepo), [true, true]);
    expect(rows.map((r) => r.lastCommit), everyElement(isNotNull));
    final history = ProjectDetail.fromJson(readJson('p/a.json')).history.single;
    expect((history.stars, history.repoStars), (null, 5000), reason: 'the repo stars are kept for the chart');
  });

  test('writes nothing when every source fails', () async {
    final result = await runIngest(
      catalog: catalog,
      pub: PubDevClient(MockClient((_) async => http.Response('', 503)), retryDelay: Duration.zero),
      github: null,
      history: HistoryStore(p.join(tmp.path, 'history')),
      writer: JsonWriter(p.join(tmp.path, 'out')),
      now: DateTime.utc(2026, 10, 1),
    );
    expect(result.written, isFalse);
    expect(Directory(p.join(tmp.path, 'out')).existsSync(), isFalse);
  });

  test('discovers popular packages and GitHub repos beyond the seeds', () async {
    final seeds = parseSeeds('''
categories: {networking: Networking, open-source-app: Open source app, other: Other}
discovery: {pub_top: 3, github_min_stars: 100}
topic_categories: {networking: [http], open-source-app: [app]}
projects:
  - {id: dio, pub: dio, categories: [networking]}
''');
    final scraped = <String>[];
    final pub = MockClient((req) async {
      if (req.url.path.startsWith('/packages/')) scraped.add(req.url.path);
      return switch (req.url.path) {
        '/api/package-name-completion-data' => http.Response(
          jsonEncode({
            'packages': ['dio', 'http_x', 'dio_extra', 'fourth'],
          }),
          200,
        ),
        '/api/search' => http.Response(
          jsonEncode({
            'packages': [
              {'package': 'dio'},
            ],
          }),
          200,
        ),
        '/api/packages/dio' || '/api/packages/http_x' || '/api/packages/dio_extra' => http.Response(
          jsonEncode({
            'latest': {
              'version': '1.0.0',
              'pubspec': {
                'repository': req.url.path.contains('dio') ? 'https://github.com/cfug/dio' : null,
                'topics': ['HTTP'],
              },
            },
          }),
          200,
        ),
        '/api/packages/dio/score' ||
        '/api/packages/dio_extra/score' ||
        '/api/packages/http_x/score' => http.Response(jsonEncode({'tags': <String>[]}), 200),
        _ => http.Response('<html></html>', 200),
      };
    });
    final gh = GithubClient(
      MockClient((req) async {
        final query = (jsonDecode(req.body) as Map)['query'] as String;
        if (query.contains('repositoryCount')) {
          return http.Response(
            jsonEncode({
              'data': {
                'search': {'repositoryCount': 2},
              },
            }),
            200,
          );
        }
        if (query.contains('search(')) {
          return http.Response(
            jsonEncode({
              'data': {
                'search': {
                  'pageInfo': {'hasNextPage': false},
                  'nodes': [
                    {'nameWithOwner': 'CFUG/dio', 'stargazerCount': 9000},
                    {'nameWithOwner': 'acme/flutter_wallet', 'stargazerCount': 300},
                  ],
                },
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'data': <String, Object?>{}}), 200);
      }),
      token: 't',
      retryDelay: Duration.zero,
    );
    final result = await runIngest(
      catalog: seeds,
      pub: PubDevClient(pub, retryDelay: Duration.zero),
      github: gh,
      history: HistoryStore(p.join(tmp.path, 'history')),
      writer: JsonWriter(p.join(tmp.path, 'out')),
      now: DateTime.utc(2026, 10, 1),
    );
    expect(result.written, isTrue);

    final rows = {for (final r in IndexFile.fromJson(readJson('index.json')).projects) r.id: r};
    expect(
      rows.keys,
      unorderedEquals(['dio', 'http_x', 'dio_extra', 'acme-flutter_wallet']),
      reason: 'pub_top caps packages',
    );
    expect(rows['dio']!.stars, 9000, reason: 'search results match tracked repos case-insensitively');
    expect(rows['dio']!.sharedRepo, isFalse, reason: 'the curated project owns a shared repo');
    expect((rows['dio_extra']!.stars, rows['dio_extra']!.sharedRepo), (null, true));
    expect(rows['dio_extra']!.repoStars, 9000, reason: 'shown as the repo\'s, never ranked');
    expect(rows['dio']!.repoStars, isNull);
    expect(rows['http_x']!.categories, ['networking']);
    expect(rows['acme-flutter_wallet']!.kind, ProjectKind.project);
    expect(rows['acme-flutter_wallet']!.sdk, 'Flutter');
    expect(rows['acme-flutter_wallet']!.categories, ['open-source-app']);
    expect(
      scraped,
      unorderedEquals(['/packages/dio/score', '/packages/http_x/score', '/packages/dio_extra/score']),
      reason: 'every package gets the weekly series',
    );
  });

  test('a failed GitHub discovery still writes the seeded projects', () async {
    final seeds = parseSeeds('''
categories: {networking: Networking}
discovery: {pub_top: 0, github_min_stars: 100}
projects:
  - {id: dio, pub: dio, categories: [networking]}
''');
    final gh = GithubClient(
      MockClient((req) async {
        final query = (jsonDecode(req.body) as Map)['query'] as String;
        if (query.contains('search(')) return http.Response(jsonEncode({'data': {'search': null}}), 200);
        return http.Response(
          jsonEncode({
            'data': {
              'r0': {'stargazerCount': 9000},
            },
          }),
          200,
        );
      }),
      token: 't',
      retryDelay: Duration.zero,
    );
    final result = await runIngest(
      catalog: seeds,
      pub: PubDevClient(pubMock, retryDelay: Duration.zero),
      github: gh,
      history: HistoryStore(p.join(tmp.path, 'history')),
      writer: JsonWriter(p.join(tmp.path, 'out')),
      now: DateTime.utc(2026, 10, 1),
    );
    expect(result.written, isTrue);
    expect(result.warnings, contains(startsWith('GitHub: discovery failed')));
    final rows = {for (final r in IndexFile.fromJson(readJson('index.json')).projects) r.id: r};
    expect(rows.keys, ['dio']);
    expect(rows['dio']!.stars, 9000);
  });

  group('commit activity', () {
    final week = DateTime.utc(2026, 9, 27).millisecondsSinceEpoch ~/ 1000;
    final weeks = jsonEncode([
      {
        'week': week,
        'days': [0, 1, 2, 0, 0, 3, 0],
      },
    ]);

    test('activityDue takes missing repos (priority first), then the oldest stale ones', () {
      CommitActivity at(String day) => CommitActivity(start: '2026-01-04', days: const [], fetched: day);
      final have = {'fresh': at('2026-10-10'), 'old': at('2026-09-01'), 'older': at('2026-08-01')};
      final now = DateTime.utc(2026, 10, 11);
      final repos = ['fresh', 'old', 'b', 'older', 'a'];
      expect(activityDue(repos, have, now, budget: 10, priority: {'a'}), ['a', 'b', 'older', 'old']);
      expect(activityDue(repos, have, now, budget: 2), ['b', 'a']);
    });

    test('is fetched once a week, retries a 202 once, and lands in the detail file', () async {
      var calls = 0;
      final client = github(
        100,
        activity: () => ++calls == 1 ? http.Response('{}', 202) : http.Response(weeks, 200),
      );
      final store = ActivityStore(p.join(tmp.path, 'history', 'activity.json'));
      Future<void> runOn(DateTime now) => runIngest(
        catalog: catalog,
        pub: PubDevClient(pubMock, retryDelay: Duration.zero),
        github: client,
        history: HistoryStore(p.join(tmp.path, 'history')),
        writer: JsonWriter(p.join(tmp.path, 'out')),
        now: now,
        activity: store,
      );

      await runOn(DateTime.utc(2026, 10, 1));
      expect(calls, 2, reason: 'the 202 is asked again');
      expect(ProjectDetail.fromJson(readJson('p/dio.json')).activity!.total, 6);
      expect(store.read().keys, ['cfug/dio']);

      await runOn(DateTime.utc(2026, 10, 4));
      expect(calls, 2, reason: 'three days old: carried over');
      expect(ProjectDetail.fromJson(readJson('p/dio.json')).activity!.fetched, '2026-10-01');

      await runOn(DateTime.utc(2026, 10, 8));
      expect(calls, 3, reason: 'a week old: refreshed');
    });
  });
}
