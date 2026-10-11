import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 11, 3);
  // Sunday 2026-09-27 and the week after.
  final github = [
    {
      'week': DateTime.utc(2026, 9, 27).millisecondsSinceEpoch ~/ 1000,
      'days': [0, 1, 2, 0, 0, 3, 0],
      'total': 6,
    },
    {
      'week': DateTime.utc(2026, 10, 4).millisecondsSinceEpoch ~/ 1000,
      'days': [4, 0, 0, 0, 0, 0, 0],
      'total': 4,
    },
  ];

  test('parses GitHub weeks into a run of days from the first Sunday', () {
    final a = CommitActivity.fromGithub(github, now)!;
    expect(a.start, '2026-09-27');
    expect(a.days, hasLength(14));
    expect(a.total, 10);
    expect(a.dayAt(7), DateTime.utc(2026, 10, 4));
    expect(a.fetched, '2026-10-11');
    expect(a.ageAt(DateTime.utc(2026, 10, 18, 1)), 7);
  });

  test('is null for anything but whole weeks', () {
    expect(CommitActivity.fromGithub(const <Object?>[], now), isNull);
    expect(CommitActivity.fromGithub({'message': 'nope'}, now), isNull);
    expect(
      CommitActivity.fromGithub([
        {
          'week': 0,
          'days': [1, 2],
        },
      ], now),
      isNull,
    );
  });

  test('round-trips through JSON, inside ProjectDetail too', () {
    final a = CommitActivity.fromGithub(github, now)!;
    final back = CommitActivity.fromJson(a.toJson());
    expect(back.toJson(), a.toJson());

    final detail = ProjectDetail(
      row: const ProjectRow(id: 'x', name: 'x'),
      activity: a,
    );
    expect(ProjectDetail.fromJson(detail.toJson()).activity!.total, 10);
    expect(
      const ProjectDetail(
        row: ProjectRow(id: 'x', name: 'x'),
      ).toJson(),
      isNot(contains('activity')),
    );
  });
}
