import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  const topics = {
    'state-management': ['state-management', 'bloc'],
    'networking': ['http', 'rest'],
    'ui': ['ui', 'widget'],
    'open-source-app': ['app'],
  };

  test('githubProjectId is URL-safe and never a pub name', () {
    expect(githubProjectId('Owner/My.Repo'), 'owner-my-repo');
    expect(githubProjectId('felangel/bloc'), contains('-'));
  });

  test('categorize follows the topic map order and falls back to other', () {
    expect(categorize(['HTTP', 'bloc'], topics), ['state-management', 'networking']);
    expect(categorize(['ui', 'http', 'bloc'], topics, max: 2), ['state-management', 'networking']);
    expect(categorize(['unrelated'], topics, published: true), [otherCategory]);
    expect(categorize(const [], topics, published: true), [otherCategory]);
  });

  test('categorize reads names and descriptions', () {
    expect(categorize(const [], topics, name: 'rest_client', published: true), ['networking']);
    expect(categorize(const [], topics, description: 'Simple state management.', published: true), [
      'state-management',
    ]);
    // Vague words only count as topics or name words, not in prose.
    expect(categorize(const [], topics, description: 'A widget for your UI.', published: true), [otherCategory]);
    expect(categorize(const [], topics, name: 'cool_widget', published: true), ['ui']);
  });

  test('categorize keeps packages out of the app category', () {
    expect(categorize(['app'], topics, published: true), [otherCategory]);
    expect(categorize(['app'], topics), [appCategory]);
    expect(categorize(const [], topics, sdk: 'Flutter'), [appCategory]);
    expect(categorize(const [], topics, sdk: 'Dart'), [otherCategory]);
  });

  test('guessSdk looks for Flutter in the name, topics and description', () {
    expect(guessSdk('a/flutter_x', const GhStats()), 'Flutter');
    expect(guessSdk('a/x', const GhStats(topics: ['flutter-app'])), 'Flutter');
    expect(guessSdk('a/x', const GhStats(description: 'A Flutter app')), 'Flutter');
    expect(guessSdk('a/cli', const GhStats(description: 'A Dart CLI')), 'Dart');
  });

  test('discoveredRepo builds an unpublished project', () {
    final p = discoveredRepo('acme/Cool_App', const GhStats(topics: ['widget']), topics);
    expect(p.id, 'acme-cool_app');
    expect(p.name, 'Cool_App');
    expect(p.kind, ProjectKind.project);
    expect(p.categories, ['ui', 'open-source-app']);
  });

  test('searchDartRepos splits star ranges over the 1,000-result cap', () async {
    // Counts per star range: [100, ∞) has 1,500, so it splits into
    // [100, 200] (600) and [201, ∞) (900).
    const counts = {'>=100': 1500, '100..200': 600, '>=201': 900};
    final searched = <String>[];
    final client = MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, Object?>;
      final vars = body['variables'] as Map<String, Object?>;
      final q = vars['q'] as String;
      final range = q.split('stars:').last;
      if ((body['query'] as String).contains('repositoryCount')) {
        return http.Response(jsonEncode({'data': {'search': {'repositoryCount': counts[range]}}}), 200);
      }
      searched.add(range);
      final page = vars['after'] == null ? 1 : 2;
      return http.Response(
        jsonEncode({
          'data': {
            'search': {
              'pageInfo': {'hasNextPage': page == 1, 'endCursor': 'c1'},
              'nodes': [
                {'nameWithOwner': 'o/$range-$page', 'stargazerCount': 150},
              ],
            },
          },
        }),
        200,
      );
    });
    final gh = GithubClient(client, token: 't', retryDelay: Duration.zero);
    final repos = await gh.searchDartRepos(100);
    expect(searched..sort(), ['100..200', '100..200', '>=201', '>=201']);
    expect(repos.keys, unorderedEquals(['o/100..200-1', 'o/100..200-2', 'o/>=201-1', 'o/>=201-2']));
    expect(repos['o/>=201-1']!.stars, 150);
  });

  test('withRetry retries GitHub secondary rate limits', () async {
    var calls = 0;
    final res = await withRetry(() async {
      calls++;
      return calls == 1
          ? http.Response('{"message": "You have exceeded a secondary rate limit."}', 403)
          : http.Response('ok', 200);
    }, baseDelay: Duration.zero);
    expect((calls, res.statusCode), (2, 200));

    calls = 0;
    final forbidden = await withRetry(() async {
      calls++;
      return http.Response('Bad credentials', 403);
    }, baseDelay: Duration.zero);
    expect((calls, forbidden.statusCode), (1, 403));
  });
}
