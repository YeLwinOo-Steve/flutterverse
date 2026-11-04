import 'package:fv_web/components/layout/site_nav.dart';
import 'package:test/test.dart';

void main() {
  test('navSection maps /jobs to the Jobs entry', () {
    expect(navSection('/jobs'), 'jobs');
    expect(navPrimary.map((i) => i.key), contains('jobs'));
  });

  test("each More page's path maps to its key in navMore", () {
    for (final item in navMore) {
      expect(navSection(item.path), item.key, reason: item.path);
    }
  });

  test('no key is in both lists, and navItems has each once', () {
    final primary = navPrimary.map((i) => i.key).toSet();
    final more = navMore.map((i) => i.key).toSet();
    expect(primary.intersection(more), isEmpty);
    final all = navItems.map((i) => i.key).toList();
    expect(all.toSet(), hasLength(all.length));
    expect(all, [...primary, ...more]);
  });

  test('the bar has six entries: five links and More', () => expect(navPrimary.length + 1, 6));
}
