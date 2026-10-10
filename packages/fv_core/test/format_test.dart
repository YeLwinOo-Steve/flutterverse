import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

void main() {
  test('groupedNumber', () {
    expect(groupedNumber(7), '7');
    expect(groupedNumber(3002), '3,002');
    expect(groupedNumber(1234567), '1,234,567');
  });

  test('compactNumber', () {
    expect(compactNumber(null), 'N/A');
    expect(compactNumber(999), '999');
    expect(compactNumber(1000), '1k');
    expect(compactNumber(1234), '1.2k');
    expect(compactNumber(123456), '123k');
    expect(compactNumber(4698698), '4.7M');
    expect(compactNumber(12000000), '12M');
    expect(compactNumber(-1500), '-1.5k');
  });

  test('signedNumber and percent', () {
    expect(signedNumber(12), '+12');
    expect(signedNumber(0), '+0');
    expect(signedNumber(-3), '-3');
    expect(signedNumber(null), 'N/A');
    expect(percent(0.1234), '12.3%');
    expect(percent(null), 'N/A');
  });

  test('ago and dates', () {
    final now = DateTime.utc(2026, 10, 6);
    expect(ago(now, now: now), 'today');
    expect(ago(now.subtract(const Duration(days: 3)), now: now), '3d ago');
    expect(ago(now.subtract(const Duration(days: 65)), now: now), '2mo ago');
    expect(ago(now.subtract(const Duration(days: 365 * 2)), now: now), '2y ago');
    expect(age(now.subtract(const Duration(days: 548)), now: now), '1.5y');
    expect(fullDate(now), 'Oct 6, 2026');
    expect(monthYear(now), 'Oct 2026');
  });
}
