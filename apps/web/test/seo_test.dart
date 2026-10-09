import 'dart:io';

import 'package:fv_web/components/layout/seo.dart';
import 'package:test/test.dart';

void main() {
  test('robots.txt and the deploy sitemap use siteUrl', () {
    expect(File('web/robots.txt').readAsStringSync(), contains('Sitemap: $siteUrl/sitemap.xml'));
    expect(File('../../.github/workflows/deploy-web.yml').readAsStringSync(), contains('--sitemap-domain=$siteUrl'));
  });

  test('clip cuts at a word boundary', () {
    expect(clip('short', 160), 'short');
    expect(clip('one two three four', 12), 'one two…');
    expect(clip('a  b\n c', 160), 'a b c');
  });

  test('ldJson escapes closing tags', () {
    expect(ldJson({'name': '</script>'}), isNot(contains('</')));
  });
}
