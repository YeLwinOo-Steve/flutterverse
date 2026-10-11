import 'package:fv_core/fv_core.dart';
import 'package:fv_web/pages/detail/chart_data.dart';
import 'package:fv_web/pages/detail/kpi_cells.dart';
import 'package:test/test.dart';

void main() {
  ProjectDetail detail(List<Snapshot> history, {bool shared = false}) => ProjectDetail(
    row: ProjectRow(id: 'x', name: 'x', repo: 'dart-lang/sdk', sharedRepo: shared),
    history: history,
  );

  test('a package sharing its repo charts the repo stars', () {
    final s = chartSeries(
      detail(shared: true, const [
        Snapshot(date: '2026-10-10', repoStars: 10000),
        Snapshot(date: '2026-10-11', repoStars: 10012),
      ]),
      ChartMetric.stars,
      ChartRange.year,
    );
    expect(s.empty, isNull);
    expect(s.points.map((p) => p.v), [10000, 10012]);
  });

  test('says the repo history is still building up with one day of it', () {
    final s = chartSeries(
      detail(shared: true, const [Snapshot(date: '2026-10-11', repoStars: 10012)]),
      ChartMetric.stars,
      ChartRange.year,
    );
    expect(s.empty, contains('whole dart-lang/sdk repo'));
  });

  test('repoStarHistory lets the growth helpers measure the whole repo', () {
    final h = repoStarHistory(const [
      Snapshot(date: '2026-10-10', repoStars: 10000),
      Snapshot(date: '2026-10-11', repoStars: 10012),
    ]);
    expect(starGrowth(h, 1), 12);
    expect(dailyStarGains(h, days: 2), [0, 12]);
  });

  List<ChartPoint> points(List<int> vs) => [
    for (final (i, v) in vs.indexed) (t: DateTime.utc(2026, 10, 8).add(Duration(days: i)), v: v),
  ];

  test('y labels never repeat: exact numbers for a narrow range', () {
    final narrow = ChartGeometry(points([5300, 5306, 5312])).gridLabels.map((l) => l.$2).toList();
    expect(narrow.toSet(), hasLength(narrow.length));
    expect(narrow.first, contains(','));
    final wide = ChartGeometry(points([1000, 9000])).gridLabels.map((l) => l.$2);
    expect(wide, ['10k', '6.6k', '3.3k', '40'], reason: 'a wide range keeps the short labels');
    final flat = ChartGeometry(points([2, 2])).gridLabels.map((l) => l.$2).toList();
    expect(flat.toSet(), hasLength(flat.length));
  });

  test('x labels never repeat a point', () {
    expect(ChartGeometry(points([1, 2, 3])).xLabels, ['Oct 8, 2026', 'Oct 9, 2026', 'Oct 10, 2026']);
    expect(ChartGeometry(points([1, 2])).xLabels, hasLength(2));
    expect(ChartGeometry(points(List.filled(30, 1))).xLabels, hasLength(4));
  });
}
