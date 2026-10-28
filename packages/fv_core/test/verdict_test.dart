import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6);
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  ProjectRow row({
    Maintenance? maintenance = Maintenance.slowing,
    int? points = 150,
    DateTime? released,
    double? growth = 0.05,
    bool archived = false,
    int? momentum,
    bool early = false,
  }) => ProjectRow(
    id: 'pkg',
    name: 'pkg',
    pub: 'pkg',
    maintenance: maintenance,
    points: points,
    maxPoints: 160,
    released: released ?? daysAgo(200),
    downloadGrowth: growth,
    archived: archived,
    momentum: momentum,
    momentumEarly: early,
  );

  Verdict? verdict(ProjectRow r) => verdictOf(r, now: now)!.verdict;

  test('discontinued or archived means replace now', () {
    final d = verdictOf(
      row(maintenance: Maintenance.active),
      now: now,
      discontinued: true,
      replacedBy: 'lints',
    )!;
    expect(d.verdict, Verdict.replaceNow);
    expect(d.replacedBy, 'lints');
    expect(d.reasons, containsAll(['discontinued on pub.dev', 'pub.dev suggests lints']));
    expect(verdict(row(archived: true, maintenance: Maintenance.active)), Verdict.replaceNow);
  });

  test('a discontinued package that is not tracked still gets a verdict', () {
    expect(verdictOf(null, now: now, discontinued: true)!.verdict, Verdict.replaceNow);
    expect(verdictOf(null, now: now), isNull);
  });

  test('active is healthy', () {
    expect(verdict(row(maintenance: Maintenance.active, points: 10)), Verdict.healthy);
  });

  test('stable needs points, a release within 3 years and steady downloads', () {
    expect(verdict(row()), Verdict.stable);
    expect(verdict(row(maintenance: Maintenance.low)), Verdict.stable);
    expect(verdict(row(points: 139)), Verdict.watch);
    expect(verdict(row(points: 140)), Verdict.stable);
    expect(verdict(row(released: daysAgo(stableReleaseDays + 1))), Verdict.watch);
    expect(verdict(row(growth: -0.11)), Verdict.watch);
    expect(verdict(row(growth: -0.10)), Verdict.stable);
  });

  test('slowing is watch, low activity is at risk', () {
    expect(verdict(row(points: 50)), Verdict.watch);
    expect(verdict(row(points: 50, maintenance: Maintenance.low)), Verdict.atRisk);
  });

  test('missing numbers are never guessed', () {
    expect(verdict(row(maintenance: null)), isNull);
    // Stable can't be shown without its inputs, so it falls through.
    expect(verdict(row(points: null)), Verdict.watch);
    expect(verdict(row(growth: null, maintenance: Maintenance.low)), Verdict.atRisk);
  });

  test('rising needs a good verdict and a non-early high momentum', () {
    expect(verdictOf(row(maintenance: Maintenance.active, momentum: 80), now: now)!.rising, isTrue);
    expect(verdictOf(row(maintenance: Maintenance.active, momentum: 80, early: true), now: now)!.rising, isFalse);
    expect(verdictOf(row(maintenance: Maintenance.active, momentum: 60), now: now)!.rising, isFalse);
    expect(verdictOf(row(points: 50, momentum: 90), now: now)!.rising, isFalse);
  });

  test('reasons print the facts behind the verdict', () {
    final r = verdictOf(row(released: daysAgo(420), growth: 0.12), now: now)!;
    expect(r.reasons, ['slowing', 'last release 1.2y ago', '150/160 pub points', 'downloads up 12% this quarter']);
    expect(verdictOf(row(growth: -0.004), now: now)!.reasons.last, 'downloads flat this quarter');
  });

  group('badgeJson', () {
    test('is the Shields endpoint shape', () {
      expect(badgeJson(verdictOf(row(maintenance: Maintenance.active), now: now)!), {
        'schemaVersion': 1,
        'label': 'Flutterverse',
        'message': 'Healthy',
        'color': '0468D7',
      });
    });

    test('says Rising, and keeps watch and at risk grey', () {
      expect(badgeJson(verdictOf(row(maintenance: Maintenance.active, momentum: 90), now: now)!)!['message'], 'Rising');
      expect(badgeJson(verdictOf(row(points: 50), now: now)!)!['color'], '6B7A90');
      expect(badgeJson(verdictOf(row(archived: true), now: now)!)!['color'], 'C8382B');
    });

    test('is null without a verdict', () {
      expect(badgeJson(verdictOf(row(maintenance: null), now: now)!), isNull);
    });
  });
}
