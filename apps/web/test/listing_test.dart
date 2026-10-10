import 'package:fv_core/fv_core.dart';
import 'package:fv_web/components/ui/pager.dart';
import 'package:fv_web/data/full_index.dart';
import 'package:fv_web/data/listing.dart';
import 'package:fv_web/data/ranking.dart';
import 'package:fv_web/pages/projects/projects_view.dart';
import 'package:test/test.dart';

void main() {
  test('pagerItems shows the ends and the current page with neighbours', () {
    expect(pagerItems(0, 1), [0]);
    expect(pagerItems(0, 113), [0, 1, null, 112]);
    expect(pagerItems(50, 113), [0, null, 49, 50, 51, null, 112]);
    expect(pagerItems(2, 6), [0, 1, 2, 3, 4, 5], reason: 'a one-page gap shows the page');
  });

  // Ties everywhere: equal stars, duplicate names.
  final rows = [
    for (var i = 0; i < 300; i++) ProjectRow(id: 'p$i', name: 'n${i % 40}', stars: (i % 7) * 10),
  ];
  final index = IndexFile(categories: const {}, projects: rows);

  test('sortedBy is a total order, whatever the input order', () {
    final a = sortedBy(rows, (r) => r.stars).map((r) => r.id).toList();
    final b = sortedBy(rows.reversed, (r) => r.stars).map((r) => r.id).toList();
    expect(a, b);
  });

  test('the server preview is exactly the first page of the full list', () {
    final now = DateTime.utc(2026, 10, 10);
    final preview = previewOf(index, ProjectsView.previewRows(index, now));
    final fromPreview = listRows(preview, const ListFilters(), listSorts.first, now);
    final fromFull = listRows(index, const ListFilters(), listSorts.first, now).take(listPageSize);
    expect(fromPreview.map((r) => r.id), fromFull.map((r) => r.id));
  });
}
