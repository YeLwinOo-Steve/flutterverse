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

  GithubClient github(int stars) => GithubClient(
    MockClient((req) async {
      if (req.url.path.endsWith('/contributors')) return http.Response('[{},{}]', 200);
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
}
