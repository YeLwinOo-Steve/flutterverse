import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

Job job(String id, {JobMatch match = JobMatch.title, String firstSeen = '2026-11-01', String title = 'Engineer'}) =>
    Job(
      id: id,
      title: title,
      company: 'Acme',
      companyId: 'acme',
      url: 'https://example.com/$id',
      source: JobSource.lever,
      match: match,
      firstSeen: firstSeen,
    );

void main() {
  group('flutterMatch', () {
    test('Flutter or Dart in the title is a title match', () {
      expect(flutterMatch('Senior Flutter Engineer', null), JobMatch.title);
      expect(flutterMatch('Dart Backend Developer', null), JobMatch.title);
      expect(flutterMatch('Mobile Engineer (flutter)', 'iOS'), JobMatch.title);
    });

    test('Flutter in the description of an app role is a mention', () {
      expect(flutterMatch('Mobile Engineer', 'You know Flutter or React Native.'), JobMatch.mentions);
      expect(flutterMatch('Senior Android/iOS Developer', 'Our app is built in Flutter.'), JobMatch.mentions);
      expect(flutterMatch('Frontend Engineer', 'Flutter web'), JobMatch.mentions);
    });

    test('a mention in a non-app or non-engineering role does not count', () {
      const boilerplate = 'Our customers love the app we build with Flutter.';
      expect(flutterMatch('Python Engineer', boilerplate), isNull);
      expect(flutterMatch('Engineering Manager, Core Infrastructure', boilerplate), isNull);
      expect(flutterMatch('Senior Product Manager, Mobile', boilerplate), isNull);
      expect(flutterMatch('Mobile Sales Engineer', boilerplate), isNull);
    });

    test('a bare Dart in the description does not count', () {
      expect(flutterMatch('Backend Engineer', 'We use Dart and Go.'), isNull);
    });

    test('whole words only', () {
      expect(flutterMatch('Dartmouth Research Assistant', null), isNull);
      expect(flutterMatch('FlutterFlow Developer', 'Build with FlutterFlow'), isNull);
      expect(flutterMatch('Engineer', null), isNull);
    });
  });

  test('compareJobs puts title matches first, then newest', () {
    final jobs = [
      job('a', match: JobMatch.mentions, firstSeen: '2026-11-03'),
      job('b', firstSeen: '2026-10-01'),
      job('c', firstSeen: '2026-11-02'),
    ]..sort(compareJobs);
    expect(jobs.map((j) => j.id), ['c', 'b', 'a']);
  });

  test('JobsFile round-trips and leaves out unknowns', () {
    final file = JobsFile(
      generatedAt: DateTime.utc(2026, 11, 4),
      companies: 2,
      failed: const ['beta'],
      jobs: [
        job('a'),
        job('b').copyWith(firstSeen: '2026-10-30'),
      ],
    );
    final json = file.toJson();
    final first = (json['jobs']! as List<Object?>).first! as Json;
    expect(first.containsKey('remote'), isFalse, reason: 'unknown remote stays unknown');
    expect(first.containsKey('location'), isFalse);
    expect(JobsFile.fromJson(json).toJson(), json);
    expect(JobsFile.fromJson(json).jobs.last.firstSeen, '2026-10-30');
  });
}
