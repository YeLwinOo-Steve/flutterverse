import 'package:fv_web/pages/hof/hof_filter.dart';
import 'package:test/test.dart';

void main() {
  test('foldForSearch drops case, accents and punctuation', () {
    expect(foldForSearch('Filip Hráček'), 'filip hracek');
    expect(foldForSearch("Mark O'Sullivan"), 'mark osullivan');
    expect(foldForSearch('Mike Rydström'), 'mike rydstrom');
    expect(foldForSearch('  flutter_local_notifications '), 'flutter local notifications');
  });

  test('hofSearchText joins the parts and skips nulls', () {
    final text = hofSearchText(['Dan Field', 'dnfield', null, 'flutter_svg']);
    expect(text, 'dan field dnfield flutter svg');
    expect(text.contains(foldForSearch('Flutter_SVG')), isTrue);
    expect(text.contains(foldForSearch('field')), isTrue);
  });
}
