import 'package:fv_core/fv_core.dart';
import 'package:fv_web/pages/detail/commit_heatmap.dart';
import 'package:test/test.dart';

void main() {
  test('heatLevels splits busy days by quartile, so one spike does not wash out the rest', () {
    final level = heatLevels([0, 1, 2, 3, 4, 500]);
    expect([0, 1, 2, 3, 4, 500].map(level), [0, 1, 1, 2, 3, 4]);
    expect(heatLevels([0, 0])(0), 0);
    expect(heatLevels([7])(7), 1);
  });

  test('monthStarts labels the week each month begins, skipping cut-short ends', () {
    // 52 weeks from Sunday 2025-10-19: no room for October at the start.
    final a = CommitActivity(start: '2025-10-19', days: List.filled(364, 0), fetched: '2026-10-11');
    final months = monthStarts(a);
    expect(months.first, (2, 'Nov'), reason: 'Nov 2 is the first Sunday in November');
    expect(months.map((m) => m.$2), hasLength(11));
    expect(months.last.$2, 'Sep', reason: 'October would start in the last two weeks');
  });

  test('commitCount reads naturally', () {
    expect([0, 1, 1711].map(commitCount), ['No commits', '1 commit', '1,711 commits']);
  });
}
