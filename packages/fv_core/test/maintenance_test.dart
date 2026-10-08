import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6);
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  test('active needs a recent commit and release', () {
    expect(maintenance(lastCommit: daysAgo(3), lastRelease: daysAgo(40), now: now), Maintenance.active);
    expect(maintenance(lastCommit: daysAgo(3), lastRelease: daysAgo(200), now: now), Maintenance.slowing);
  });

  test('slowing within 120 days, low after', () {
    expect(maintenance(lastCommit: daysAgo(90), lastRelease: daysAgo(90), now: now), Maintenance.slowing);
    expect(maintenance(lastCommit: daysAgo(400), lastRelease: daysAgo(400), now: now), Maintenance.low);
  });

  test('release stands in for a missing commit date', () {
    expect(maintenance(lastRelease: daysAgo(6), now: now), Maintenance.active);
    expect(maintenance(now: now), isNull);
  });
}
