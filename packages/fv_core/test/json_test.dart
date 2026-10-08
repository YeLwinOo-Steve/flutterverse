import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

void main() {
  test('ProjectDetail round-trips through JSON', () {
    final detail = ProjectDetail(
      row: ProjectRow.build(
        project: const Project(id: 'dio', name: 'dio', pub: 'dio', repo: 'cfug/dio', categories: ['networking']),
        pub: PubStats(
          likes: 10,
          points: 160,
          maxPoints: 160,
          published: DateTime.utc(2026, 9, 4),
          sdks: const ['Dart', 'Flutter'],
          publisher: 'cfug.dev',
          weeklyDownloads: List.generate(52, (i) => 1000 + i),
          majors: [Release(version: '5.0.0', date: DateTime.utc(2023, 2, 1))],
        ),
        gh: GhStats(stars: 12000, lastCommit: DateTime.utc(2026, 9, 30), languages: const ['Dart 97%']),
        momentum: 42,
        maintenance: Maintenance.active,
        spark: const [1, 2, 3],
      ),
      history: const [
        Snapshot(date: '2026-09-30', stars: 11990),
        Snapshot(date: '2026-10-01', stars: 12000),
      ],
      related: const ['freezed'],
    );
    final back = ProjectDetail.fromJson(detail.toJson());
    expect(back.toJson(), detail.toJson());
    expect(back.row.owner, 'cfug');
    expect(back.row.sdk, 'Dart', reason: 'tagged for both SDKs means pure Dart');
    expect(back.row.publisher, 'cfug.dev');
    expect(back.row.maintenance, Maintenance.active);
    expect(back.row.downloadGrowth, closeTo((1051 - 1038) / 1038, 0.001));
  });

  test('timeline orders creation, majors, milestones and latest release', () {
    final d = ProjectDetail(
      row: const ProjectRow(id: 'x', name: 'x'),
      pub: PubStats(
        version: '2.1.0',
        published: DateTime.utc(2026, 9, 1),
        majors: [Release(version: '2.0.0', date: DateTime.utc(2025, 1, 1))],
      ),
      gh: GhStats(createdAt: DateTime.utc(2020, 5, 1)),
      history: const [
        Snapshot(date: '2026-08-01', stars: 990),
        Snapshot(date: '2026-08-02', stars: 1004),
      ],
    );
    expect(timelineOf(d).map((e) => e.label), [
      'Repository created',
      'v2.0.0 released',
      '1k GitHub stars',
      'Latest release v2.1.0',
    ]);
  });
}
