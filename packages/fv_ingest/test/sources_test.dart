import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

final now = DateTime.utc(2026, 10, 6);

String scorePage(List<int> newestFirst) {
  final payload = base64.encode(
    utf8.encode(jsonEncode({'totalWeeklyDownloads': newestFirst, 'newestDate': '2026-10-05T00:00:00.000Z'})),
  );
  return '<div data-downloads-chart-points="$payload"></div>';
}

void main() {
  test('githubRepoFromUrl', () {
    expect(githubRepoFromUrl('https://github.com/cfug/dio/blob/main/dio'), 'cfug/dio');
    expect(githubRepoFromUrl('https://github.com/a/b.git'), 'a/b');
    expect(githubRepoFromUrl('https://gitlab.com/a/b'), isNull);
  });

  test('majorReleases keeps the first stable release per major from 1 on', () {
    final r = [
      for (final (v, y) in [('0.9.0', 2019), ('1.0.0-dev', 2019), ('1.0.0', 2020), ('1.2.0', 2020), ('2.0.0', 2022)])
        Release(version: v, date: DateTime.utc(y)),
    ];
    expect(majorReleases(r).map((e) => e.version), ['1.0.0', '2.0.0']);
  });

  test('parseWeeklyDownloads reverses to oldest first and tolerates junk', () {
    final w = parseWeeklyDownloads(scorePage([30, 20, 10]))!;
    expect(w.counts, [10, 20, 30]);
    expect(w.end, DateTime.utc(2026, 10, 5));
    expect(parseWeeklyDownloads('<div data-downloads-chart-points="!!!"></div>'), isNull);
    expect(parseWeeklyDownloads('<html></html>'), isNull);
  });

  group('PubDevClient', () {
    test('combines info, score, releases and downloads', () async {
      final client = MockClient((req) async {
        return switch (req.url.path) {
          '/api/packages/dio' => http.Response(
            jsonEncode({
              'latest': {
                'version': '5.0.0',
                'published': '2026-09-04T00:00:00Z',
                'pubspec': {
                  'description': 'A  powerful\nclient',
                  'repository': 'https://github.com/cfug/dio',
                  'environment': {'sdk': '^3.0.0', 'flutter': '>=3.10.0'},
                },
              },
              'versions': [
                {'version': '1.0.0', 'published': '2019-01-01T00:00:00Z'},
                {'version': '4.9.0', 'published': '2025-12-01T00:00:00Z'},
                {'version': '5.0.0', 'published': '2026-09-04T00:00:00Z'},
              ],
            }),
            200,
          ),
          '/api/packages/dio/score' => http.Response(
            jsonEncode({
              'grantedPoints': 150,
              'maxPoints': 160,
              'likeCount': 10,
              'downloadCount30Days': 99,
              'tags': [
                'publisher:flutter.cn',
                'sdk:dart',
                'sdk:flutter',
                'platform:web',
                'platform:ios',
                'is:wasm-ready',
                'is:flutter-favorite',
                'license:bsd-3-clause',
                'license:osi-approved',
              ],
            }),
            200,
          ),
          '/packages/dio/score' => http.Response(scorePage([3, 2, 1]), 200),
          _ => http.Response('', 404),
        };
      });
      final s = (await PubDevClient(client).fetch('dio', now: now))!;
      expect(s.version, '5.0.0');
      expect(s.points, 150);
      expect(s.publisher, 'flutter.cn');
      expect(s.sdks, ['Dart', 'Flutter']);
      expect(s.platforms, ['iOS', 'Web', 'WASM']);
      expect(s.flutterFavorite, isTrue);
      expect(s.license, 'BSD-3-Clause');
      expect(s.dartSdk, '^3.0.0');
      expect(s.flutterSdk, '>=3.10.0');
      expect(s.description, 'A powerful client');
      expect(s.firstPublished, DateTime.utc(2019));
      expect(s.releasesLastYear, 2);
      expect(s.majors.map((r) => r.version), ['1.0.0', '4.9.0', '5.0.0']);
      expect(s.weeklyDownloads, [1, 2, 3]);
      expect(s.weeklyDownloadsEnd, DateTime.utc(2026, 10, 5));
      expect(await PubDevClient(client).fetch('missing', now: now), isNull);
    });

    test('retries on 429 and follows pagination', () async {
      var calls = 0;
      final client = MockClient((req) async {
        if (++calls == 1) return http.Response('', 429, headers: {'retry-after': '0'});
        final page2 = req.url.queryParameters['page'] == '2';
        return http.Response(
          jsonEncode({
            'packages': [
              {'package': page2 ? 'b' : 'a'},
            ],
            if (!page2) 'next': 'https://pub.dev/api/search?q=is%3Aflutter-favorite&page=2',
          }),
          200,
        );
      });
      expect(await PubDevClient(client, retryDelay: Duration.zero).flutterFavorites(), ['a', 'b']);
    });
  });

  group('GithubClient', () {
    Map<String, Object?> repoNode(int stars) => {
      'stargazerCount': stars,
      'forkCount': 1,
      'issues': {'totalCount': 2},
      'watchers': {'totalCount': 3},
      'createdAt': '2020-01-01T00:00:00Z',
      'pushedAt': '2026-10-01T00:00:00Z',
      'defaultBranchRef': {
        'target': {'committedDate': '2026-09-30T00:00:00Z'},
      },
      'licenseInfo': {'spdxId': 'MIT'},
      'languages': {
        'totalSize': 1000,
        'edges': [
          {
            'size': 996,
            'node': {'name': 'Dart'},
          },
        ],
      },
      'repositoryTopics': {
        'nodes': [
          {
            'topic': {'name': 'flutter'},
          },
        ],
      },
      'isArchived': false,
    };

    test('batches repos, parses fields and tolerates missing ones', () async {
      final queries = <String>[];
      final client = MockClient((req) async {
        final query = (jsonDecode(req.body) as Map)['query'] as String;
        queries.add(query);
        final n = RegExp(r'r\d+:').allMatches(query).length;
        final gone = query.contains('"gone"');
        return http.Response(
          jsonEncode({
            'data': {for (var i = 0; i < n; i++) 'r$i': gone && i == 0 ? null : repoNode(100 + i)},
            if (gone)
              'errors': [
                {'message': 'Could not resolve to a Repository'},
              ],
          }),
          200,
        );
      });
      final errors = <String>[];
      final out = await GithubClient(
        client,
        token: 't',
        batchSize: 2,
      ).fetchAll(['a/gone', 'a/b', 'c/d'], onError: errors.add);
      expect(queries, hasLength(2));
      expect(queries.first, contains('fragment F'));
      expect(out.keys, unorderedEquals(['a/b', 'c/d']));
      final ab = out['a/b']!;
      expect(ab.stars, 101);
      expect(ab.watchers, 3);
      expect(ab.lastCommit, DateTime.utc(2026, 9, 30));
      expect(ab.languages, ['Dart 99.6%']);
      expect(errors.single, contains('Could not resolve'));
    });

    test('fetchUsers omits the repository fragment', () async {
      late String query;
      final client = MockClient((req) async {
        query = (jsonDecode(req.body) as Map)['query'] as String;
        return http.Response(
          jsonEncode({
            'data': {
              'r0': {
                'followers': {'totalCount': 9},
                'repositories': {'totalCount': 4},
              },
            },
          }),
          200,
        );
      });
      final users = await GithubClient(client, token: 't').fetchUsers(['felangel']);
      expect(users['felangel'], (9, 4));
      expect(query, isNot(contains('fragment')));
    });

    test('contributors reads the last page from the Link header', () async {
      final client = MockClient(
        (req) async =>
            http.Response('[{}]', 200, headers: {'link': '<https://x/contributors?per_page=1&page=143>; rel="last"'}),
      );
      expect(await GithubClient(client, token: 't').contributors('cfug/dio'), 143);
    });

    test('commitActivity: a 204 is a year of zeros, a 202 is pending, the limit is passed on', () async {
      final now = DateTime.utc(2026, 10, 11);
      Future<ActivityReply> reply(int status) => GithubClient(
        MockClient((_) async => http.Response('', status, headers: {'x-ratelimit-remaining': '321'})),
        token: 't',
        retryDelay: Duration.zero,
      ).commitActivity('a/b', now);

      final empty = (await reply(204)).activity!;
      expect(empty.days, hasLength(364));
      expect(empty.total, 0);
      expect(empty.dayAt(363), DateTime.utc(2026, 10, 17), reason: 'the week of now, through Saturday');

      final pending = await reply(202);
      expect((pending.activity, pending.pending, pending.remaining), (null, true, 321));
      expect((await reply(404)).pending, isFalse);
    });
  });
}
