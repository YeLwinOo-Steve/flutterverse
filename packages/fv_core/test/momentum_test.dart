import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

/// Daily snapshots ending on 2026-10-01, one per value in [stars].
List<Snapshot> daily(List<int?> stars) {
  final end = DateTime.utc(2026, 10, 1);
  return [
    for (var i = 0; i < stars.length; i++)
      Snapshot(
        date: Snapshot.dayOf(end.subtract(Duration(days: stars.length - 1 - i))),
        stars: stars[i],
      ),
  ];
}

void main() {
  group('starGrowth', () {
    test('is null without enough history', () {
      expect(starGrowth(const [], 7), isNull);
      expect(starGrowth(daily([10, 11, 12]), 7), isNull);
    });

    test('measures from the snapshot on or before the cutoff', () {
      final h = daily(List.generate(31, (i) => 100 + i * 2));
      expect(starGrowth(h, 1), 2);
      expect(starGrowth(h, 7), 14);
      expect(starGrowth(h, 30), 60);
    });

    test('tolerates gaps and null counters, and can be negative', () {
      final h = [
        const Snapshot(date: '2026-09-20', stars: 100),
        const Snapshot(date: '2026-09-23'),
        const Snapshot(date: '2026-09-28', stars: 95),
      ];
      expect(starGrowth(h, 7), -5);
    });
  });

  group('starGrowthEstimate', () {
    test('is measured once the history reaches back far enough', () {
      expect(starGrowthEstimate(daily(List.generate(8, (i) => 100 + i)), 7), (gain: 7, early: false));
    });

    test('scales up a shorter history, flagged early', () {
      expect(starGrowthEstimate(daily([100, 103]), 7), (gain: 21, early: true));
      expect(starGrowthEstimate(daily([100, null, 104]), 7), (gain: 14, early: true));
    });

    test('is null with under two days of stars', () {
      expect(starGrowthEstimate(daily([100]), 7), isNull);
      expect(starGrowthEstimate(daily([null, 100, null]), 7), isNull);
    });
  });

  group('dailyStarGains', () {
    test('null with less than two star snapshots', () {
      expect(dailyStarGains(daily([5])), isNull);
    });

    test('places gains on the right day, zero-filling gaps', () {
      final gains = dailyStarGains(daily([10, 12, 12, 20]), days: 5)!;
      expect(gains, [0, 0, 2, 0, 8]);
    });
  });

  group('momentumScores', () {
    const flat = MomentumInput(stars: 1000, stars7d: 0, stars30d: 0, daysSinceCommit: 400, daysSinceRelease: 400);

    test('null without 7-day growth', () {
      final s = momentumScores({'a': const MomentumInput(stars: 10, stars7d: null, stars30d: null)});
      expect(s['a'], isNull);
    });

    test('a dormant project scores only the floor signals', () {
      // 0.12 * 0.4 (unknown downloads) + 0.12 * 0.1 + 0.10 * 0.2 = 0.08
      expect(momentumScores({'a': flat})['a'], 8);
    });

    test('the fastest, accelerating, active project scores 100', () {
      final s = momentumScores({
        'hot': const MomentumInput(
          stars: 1000,
          stars7d: 300,
          stars30d: 300,
          daysSinceCommit: 1,
          daysSinceRelease: 5,
          downloadGrowth: 0.5,
        ),
        'flat': flat,
      });
      expect(s['hot'], 100);
      expect(s['flat'], 8);
    });

    test('is relative to the fastest project', () {
      MomentumInput at(int d7) =>
          MomentumInput(stars: 5000, stars7d: d7, stars30d: d7 * 4, daysSinceCommit: 10, daysSinceRelease: 10);
      final s = momentumScores({'slow': at(10), 'fast': at(200)});
      expect(s['fast']!, greaterThan(s['slow']!));
    });

    test('extrapolates the 30-day gain from the week while history is short', () {
      final s = momentumScores({'new': const MomentumInput(stars: 100, stars7d: 7, stars30d: null)});
      expect(s['new'], isNotNull);
    });
  });
}
