import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Trimmed from real responses saved on 2026-11-04.
final greenhouseBody = jsonEncode({
  'jobs': [
    {
      'id': 4977315101,
      'title': 'Flutter Developer',
      'absolute_url': 'https://job-boards.eu.greenhouse.io/apadmi/jobs/4977315101',
      'location': {'name': 'Amsterdam'},
      'content': '&lt;p&gt;Build apps.&lt;/p&gt;',
    },
    {
      'id': 2,
      'title': 'Senior Mobile Engineer',
      'absolute_url': 'https://example.com/2',
      'location': {'name': 'Remote, United States'},
      'content': '&lt;p&gt;Our app is written in &lt;b&gt;Flutter&lt;/b&gt;.&lt;/p&gt;',
    },
    {
      'id': 3,
      'title': 'Python Engineer',
      'absolute_url': 'https://example.com/3',
      'location': {'name': 'London'},
      'content': 'We build our app with Flutter.',
    },
  ],
  'meta': {'total': 3},
});

Json leverPosting(String id, String title, {String? workplace, String? location, String text = ''}) => {
  'id': id,
  'text': title,
  'hostedUrl': 'https://jobs.lever.co/acme/$id',
  'categories': {'location': ?location},
  'workplaceType': ?workplace,
  'descriptionPlain': text,
  'lists': [
    {'text': 'Requirements', 'content': '<li>3 years of <b>Flutter</b></li>'},
  ],
};

final ashbyBody = jsonEncode({
  'apiVersion': '1',
  'jobs': [
    {
      'id': 'a1',
      'title': 'Lead Flutter Developer',
      'jobUrl': 'https://jobs.ashbyhq.com/labhouse/a1',
      'location': 'Barcelona',
      'isRemote': true,
      'workplaceType': 'Hybrid',
      'isListed': true,
      'descriptionPlain': 'Own products end to end.',
    },
    {
      'id': 'a2',
      'title': 'Flutter Engineer',
      'jobUrl': 'https://jobs.ashbyhq.com/labhouse/a2',
      'workplaceType': 'Remote',
      'isListed': false,
    },
    {'id': 'a3', 'title': 'Flutter Engineer', 'jobUrl': 'https://jobs.ashbyhq.com/labhouse/a3', 'isRemote': true},
  ],
});

/// The official HN API: `whoishiring`'s posts, newest first, then items.
final hnItems = <String, Object?>{
  '/v0/user/whoishiring.json': {
    'submitted': [2, 1],
  },
  '/v0/item/2.json': {'id': 2, 'title': 'Ask HN: Who wants to be hired? (November 2026)'},
  '/v0/item/1.json': {
    'id': 1,
    'title': 'Ask HN: Who is hiring? (November 2026)',
    'kids': [10, 11, 12],
  },
  '/v0/item/10.json': {'id': 10, 'text': 'Acme | Flutter Engineer | Remote'},
  '/v0/item/11.json': {'id': 11, 'deleted': true},
  '/v0/item/12.json': {'id': 12, 'text': 'Spam | Flutter', 'dead': true},
};

const greenhouse = JobCompany(id: 'apadmi', name: 'Apadmi', ats: JobSource.greenhouse, token: 'apadmi');
const lever = JobCompany(id: 'acme', name: 'Acme', ats: JobSource.lever, token: 'acme');
const ashby = JobCompany(id: 'labhouse', name: 'LABHOUSE', ats: JobSource.ashby, token: 'labhouse');

void main() {
  group('jobs config', () {
    test('parses and validates', () {
      final companies = parseJobsConfig('''
companies:
  - {id: acme, name: Acme, ats: lever, token: acme, region: eu, careers: "https://acme.example/careers"}
  - {id: beta, name: "Beta, Inc.", ats: ashby, token: Beta}
''');
      expect(companies.map((c) => c.name), ['Acme', 'Beta, Inc.']);
      expect(companies.first.region, 'eu');
      expect(validateJobsConfig(companies), isEmpty);
    });

    test('rejects duplicates, unknown systems and bad tokens', () {
      final problems = validateJobsConfig(
        parseJobsConfig('''
companies:
  - {id: acme, name: Acme, ats: lever, token: acme}
  - {id: acme, name: Acme 2, ats: workday, token: "bad token"}
  - {id: gh, name: GH, ats: greenhouse, token: x, region: eu}
  - {id: copy, name: Copy, ats: lever, token: ACME}
'''),
      );
      expect(problems, [
        contains('duplicate id'),
        contains('`ats` must be one of'),
        contains('`token` is missing or malformed'),
        contains('`region` is only for Lever'),
        contains('same board as another company'),
      ]);
    });

    test('an empty file is an empty list', () => expect(parseJobsConfig(''), isEmpty));

    test('exclude_companies ignores case and legal-form words', () {
      final exclude = parseJobsExclude('exclude_companies: [Xcellink, "Two95 International"]\ncompanies: []');
      expect(exclude.contains(normalizeCompany('Xcellink Pte Ltd')), isTrue);
      expect(exclude.contains(normalizeCompany('TWO95 International Inc.')), isTrue);
      expect(exclude.contains(normalizeCompany('Xcellent Apps')), isFalse);
    });
  });

  group('boards', () {
    test('Greenhouse decodes escaped HTML and reads Remote from the location', () async {
      final client = MockClient((req) async {
        expect(req.url.toString(), 'https://boards-api.greenhouse.io/v1/boards/apadmi/jobs?content=true');
        return http.Response(greenhouseBody, 200);
      });
      final posts = await GreenhouseBoard(client).fetch(greenhouse);
      expect(posts, hasLength(3));
      expect(posts[1].text, 'Our app is written in Flutter .');
      expect(posts[1].remote, isTrue);
      expect(posts[0].remote, isNull, reason: 'not stated is unknown, never false');
      expect(posts[0].location, 'Amsterdam');
    });

    test('Lever pages through results and reads lists', () async {
      final skips = <String>[];
      final client = MockClient((req) async {
        skips.add(req.url.queryParameters['skip']!);
        final page = req.url.queryParameters['skip'] == '0'
            ? [leverPosting('1', 'Mobile Developer', workplace: 'remote'), leverPosting('2', 'Designer')]
            : [leverPosting('3', 'iOS Engineer', location: 'Berlin')];
        return http.Response(jsonEncode(page), 200);
      });
      final posts = await LeverBoard(client, pageSize: 2).fetch(lever);
      expect(skips, ['0', '2']);
      expect(posts.map((p) => p.id), ['1', '2', '3']);
      expect(posts.first.remote, isTrue);
      expect(posts.first.text, contains('3 years of Flutter'));
      expect(posts.last.location, 'Berlin');
    });

    test('Lever retries on the EU host after a 404', () async {
      final hosts = <String>[];
      final client = MockClient((req) async {
        hosts.add(req.url.host);
        return req.url.host == 'api.lever.co' ? http.Response('{}', 404) : http.Response('[]', 200);
      });
      expect(await LeverBoard(client).fetch(lever), isEmpty);
      expect(hosts, ['api.lever.co', 'api.eu.lever.co']);
    });

    test('Ashby skips unlisted roles and prefers workplaceType over isRemote', () async {
      final client = MockClient((req) async => http.Response(ashbyBody, 200));
      final posts = await AshbyBoard(client).fetch(ashby);
      expect(posts.map((p) => p.id), ['a1', 'a3']);
      expect(posts[0].remote, isNull, reason: 'Hybrid, though isRemote says true');
      expect(posts[1].remote, isTrue);
    });

    test('a non-200 answer is a feed error', () async {
      final client = MockClient((req) async => http.Response('nope', 404));
      expect(() => AshbyBoard(client).fetch(ashby), throwsA(isA<JobFeedException>()));
    });
  });

  group('Hacker News', () {
    test('parseHnPost takes the first line and company, and links to the comment', () {
      final post = parseHnPost(
        '49980867',
        'Purchasely | <a href="https:&#x2F;&#x2F;www.purchasely.com" rel="nofollow">https:&#x2F;&#x2F;www.purchasely.com</a>'
            ' | Senior SDK Engineer | Paris | REMOTE (France)<p>We ship Flutter and React Native SDKs.',
      )!;
      expect(post.company, 'Purchasely');
      expect(post.url, 'https://news.ycombinator.com/item?id=49980867');
      expect(post.title, startsWith('Purchasely | https://www.purchasely.com | Senior SDK Engineer'));
      expect(post.remote, isTrue);
      expect(post.text, contains('Flutter'));
    });

    test('an empty post is skipped', () {
      expect(parseHnPost('8', '<p>'), isNull);
    });

    test('fetch reads the newest "Who is hiring?" thread and skips dead posts', () async {
      final client = MockClient((req) async {
        expect(req.url.host, 'hacker-news.firebaseio.com');
        return http.Response(jsonEncode(hnItems[req.url.path]), 200);
      });
      final posts = await HnHiring(client).fetch();
      expect(posts.single.company, 'Acme');
      expect(posts.single.url, 'https://news.ycombinator.com/item?id=10');
    });
  });

  group('Workable feed', () {
    String job(
      String ref,
      String title,
      String company, {
      String date = 'Mon, 02 Nov 2026 09:00:00 UTC',
      String remote = 'false',
      String text = '',
    }) =>
        '''
  <job>
    <title><![CDATA[$title]]></title>
    <date><![CDATA[$date]]></date>
    <referencenumber><![CDATA[$ref]]></referencenumber>
    <url><![CDATA[https://apply.workable.com/j/$ref]]></url>
    <company><![CDATA[$company]]></company>
    <city><![CDATA[Manila]]></city>
    <state><![CDATA[]]></state>
    <country><![CDATA[PH]]></country>
    <remote><![CDATA[$remote]]></remote>
    <description><![CDATA[<p>$text</p>]]></description>
  </job>''';

    test('parses jobs across chunk boundaries and skips old ones', () async {
      final xml =
          '<?xml version="1.0"?><source>'
          '${job('A1', 'Flutter Dev', 'Acme', remote: 'true')}'
          '${job('B2', 'Mobile Engineer', 'Beta', text: 'We use Flutter')}'
          '${job('C3', 'Flutter Dev', 'Old Co', date: 'Wed, 28 Jul 2021 10:24:17 UTC')}'
          '</source>';
      final bytes = utf8.encode(xml);
      // Split mid-tag to prove blocks are reassembled.
      final chunks = Stream.fromIterable([bytes.sublist(0, 333), bytes.sublist(333, 700), bytes.sublist(700)]);
      final posts = await parseWorkableFeed(chunks, now: DateTime.utc(2026, 11, 4)).toList();
      expect(posts.map((p) => p.id), ['A1', 'B2']);
      expect(posts.first.url, 'https://apply.workable.com/j/A1');
      expect(posts.first.remote, isTrue);
      expect(posts.first.location, 'Manila, PH');
      expect(posts.last.text, 'We use Flutter');
    });

    test('retries a 429, then gives up after three tries', () async {
      var calls = 0;
      final feed = WorkableFeed(
        MockClient((req) async {
          calls++;
          return http.Response('', 429, headers: {'retry-after': '0'});
        }),
        now: DateTime.utc(2026, 11, 4),
        retryPause: Duration.zero,
      );
      await expectLater(feed.fetch, throwsA(isA<JobFeedException>()));
      expect(calls, 3);
    });

    test('a 429 that clears is fetched and parsed', () async {
      var calls = 0;
      final feed = WorkableFeed(
        MockClient((req) async {
          calls++;
          if (calls == 1) return http.Response('', 429);
          return http.Response(
            '<source>${job('A1', 'Flutter Dev', 'Acme')}</source>',
            200,
            headers: {'content-type': 'application/xml; charset=utf-8'},
          );
        }),
        now: DateTime.utc(2026, 11, 4),
        retryPause: Duration.zero,
      );
      expect((await feed.fetch()).single.id, 'A1');
    });

    test('a 404 fails at once', () async {
      var calls = 0;
      final feed = WorkableFeed(
        MockClient((req) async {
          calls++;
          return http.Response('', 404);
        }),
        now: DateTime.utc(2026, 11, 4),
      );
      await expectLater(feed.fetch, throwsA(isA<JobFeedException>()));
      expect(calls, 1);
    });

    test('company ids are prefixed slugs', () {
      expect(searchCompanyId('wk', 'Questronix Corporation'), 'wk-questronix-corporation');
    });
  });

  group('PoliteClient', () {
    test('sets the User-Agent and spaces requests to one host', () async {
      final seen = <(String, String?, DateTime)>[];
      final client = PoliteClient(
        MockClient((req) async {
          seen.add((req.url.host, req.headers['user-agent'], DateTime.now()));
          return http.Response('[]', 200);
        }),
        spacing: const Duration(milliseconds: 120),
      );
      await Future.wait([
        client.get(Uri.https('api.lever.co', '/a')),
        client.get(Uri.https('api.lever.co', '/b')),
        client.get(Uri.https('hacker-news.firebaseio.com', '/c')),
      ]);
      expect(seen.every((s) => s.$2 == jobsUserAgent), isTrue);
      final lever = [
        for (final s in seen)
          if (s.$1 == 'api.lever.co') s.$3,
      ]..sort();
      expect(lever[1].difference(lever[0]), greaterThanOrEqualTo(const Duration(milliseconds: 100)));
      final hosts = seen.map((s) => s.$1).toList();
      expect(
        hosts.indexOf('hacker-news.firebaseio.com'),
        lessThan(hosts.lastIndexOf('api.lever.co')),
        reason: 'HN is not held behind the Lever queue',
      );
    });
  });

  group('runJobs', () {
    late Directory tmp;
    late JobsStore store;
    late JsonWriter writer;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('fv_jobs');
      store = JobsStore(p.join(tmp.path, 'history', 'jobs.json'));
      writer = JsonWriter(p.join(tmp.path, 'data'));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    JobsFile output() =>
        JobsFile.fromJson(jsonDecode(File(p.join(tmp.path, 'data', 'jobs.json')).readAsStringSync()) as Json);

    Future<JobsResult> run(Map<String, List<Posting>?> feeds, DateTime now, {HnHiring? hn}) => runJobs(
      companies: [
        for (final id in feeds.keys) JobCompany(id: id, name: id.toUpperCase(), ats: JobSource.lever, token: id),
      ],
      boards: {JobSource.lever: _FakeBoard(feeds)},
      store: store,
      writer: writer,
      now: now,
      hn: hn,
    );

    Posting post(String id, String title, {String? location, String? text}) =>
        Posting(id: id, title: title, url: 'https://example.com/$id', location: location, text: text);

    test('keeps Flutter roles, title matches first, and remembers first-seen', () async {
      await run({
        'acme': [
          post('1', 'Mobile Engineer', text: 'Flutter'),
          post('2', 'Flutter Engineer'),
          post('3', 'Accountant', text: 'Flutter'),
        ],
      }, DateTime.utc(2026, 11, 1));
      expect(output().jobs.map((j) => j.id), ['lever:acme:2', 'lever:acme:1']);
      expect(output().jobs.first.company, 'ACME');

      await run({
        'acme': [post('2', 'Flutter Engineer'), post('4', 'Dart Developer')],
      }, DateTime.utc(2026, 11, 2));
      final jobs = {for (final j in output().jobs) j.id: j};
      expect(jobs.keys, unorderedEquals(['lever:acme:2', 'lever:acme:4']), reason: 'a missing role is gone');
      expect(jobs['lever:acme:2']!.firstSeen, '2026-11-01');
      expect(jobs['lever:acme:4']!.firstSeen, '2026-11-02');
    });

    test('a failing company carries over for 3 days, then drops', () async {
      await run({
        'acme': [post('1', 'Flutter Engineer')],
        'beta': [post('2', 'Flutter Engineer')],
      }, DateTime.utc(2026, 11, 1));
      final result = await run({
        'acme': null,
        'beta': [post('2', 'Flutter Engineer')],
      }, DateTime.utc(2026, 11, 4));
      expect(result.failed, ['acme']);
      expect(output().jobs.map((j) => j.companyId), containsAll(['acme', 'beta']));
      expect(output().failed, ['acme']);

      await run({'acme': null, 'beta': <Posting>[]}, DateTime.utc(2026, 11, 5));
      expect(output().jobs, isEmpty);
    });

    test('warns after 7 failed runs in a row', () async {
      JobsResult? last;
      for (var d = 1; d <= 7; d++) {
        last = await run({'acme': null}, DateTime.utc(2026, 11, d));
      }
      expect(last!.warnings.last, contains('acme has failed 7 runs in a row'));
    });

    test('folds one role posted in several places into one row', () async {
      await run({
        'acme': [
          post('1', 'Flutter Engineer', location: 'Lagos'),
          post('2', 'Flutter  engineer', location: 'Nairobi'),
          post('3', 'Flutter Engineer', location: 'Accra'),
        ],
      }, DateTime.utc(2026, 11, 1));
      expect(output().jobs.single.location, 'Lagos +2 more');
    });

    test('caps each company at 25 roles', () async {
      await run({
        'acme': [for (var i = 0; i < 30; i++) post('$i', 'Flutter Engineer $i')],
      }, DateTime.utc(2026, 11, 1));
      expect(output().jobs, hasLength(maxPerCompany));
    });

    test('cross-company rows skip excluded and directly listed companies, and carry over on failure', () async {
      final search = _FakeSearch([
        for (final (id, company) in [('1', 'Good Co'), ('2', 'Agency Ltd'), ('3', 'ACME')])
          Posting(id: id, title: 'Flutter Engineer', url: 'https://apply.workable.com/j/$id', company: company),
      ]);
      Future<void> go(DateTime now) => runJobs(
        companies: const [JobCompany(id: 'acme', name: 'Acme', ats: JobSource.lever, token: 'acme')],
        boards: {
          JobSource.lever: _FakeBoard({'acme': []}),
        },
        store: store,
        writer: writer,
        now: now,
        searches: [search],
        exclude: {normalizeCompany('Agency')},
      );
      await go(DateTime.utc(2026, 11, 1));
      expect(output().jobs.map((j) => j.id), ['workable:wk-good-co:1']);
      expect(output().companies, 1);

      search.down = true;
      await go(DateTime.utc(2026, 11, 2));
      expect(output().jobs.map((j) => j.id), ['workable:wk-good-co:1'], reason: 'carried over');
      expect(output().failed, ['workable']);
    });

    test('Hacker News rows use the post company and the hn id', () async {
      final hn = HnHiring(MockClient((req) async => http.Response(jsonEncode(hnItems[req.url.path]), 200)));
      await run({}, DateTime.utc(2026, 11, 1), hn: hn);
      final job = output().jobs.single;
      expect(job.id, 'hn:hn:10');
      expect(job.company, 'Acme');
      expect(job.source, JobSource.hn);
    });
  });
}

class _FakeBoard implements JobBoard {
  _FakeBoard(this.feeds);

  final Map<String, List<Posting>?> feeds;

  @override
  Future<List<Posting>> fetch(JobCompany company) async => feeds[company.id] ?? (throw const JobFeedException('down'));
}

class _FakeSearch implements CompanySearch {
  _FakeSearch(this.posts);

  final List<Posting> posts;
  bool down = false;

  @override
  JobSource get source => JobSource.workable;

  @override
  String companyId(String name) => searchCompanyId('wk', name);

  @override
  Future<List<Posting>> fetch() async => down ? throw const JobFeedException('down') : posts;
}
