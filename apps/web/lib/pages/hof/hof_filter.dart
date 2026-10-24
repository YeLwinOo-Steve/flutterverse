import 'dart:async';

import 'package:universal_web/web.dart' as web;

/// The text a Hall of Fame card matches on, for its `data-hof` attribute.
String hofSearchText(Iterable<String?> parts) => foldForSearch(parts.whereType<String>().join(' '));

/// Lowercases [s], drops accents and punctuation, and collapses spaces, so
/// "hracek" finds Hráček and "osullivan" finds O'Sullivan.
String foldForSearch(String s) {
  final out = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final c = _plain[ch] ?? ch;
    if (RegExp(r'[a-z0-9 ]').hasMatch(c)) {
      out.write(c);
    } else if (RegExp(r'[\s/_.-]').hasMatch(c)) {
      out.write(' ');
    }
  }
  return out.toString().replaceAll(RegExp(' +'), ' ').trim();
}

const _plain = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'å': 'a', 'ã': 'a', 'ç': 'c', 'č': 'c', 'ć': 'c', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ñ': 'n', 'ń': 'n', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'ø': 'o', 'õ': 'o', 'ř': 'r', //
  'š': 's', 'ś': 's', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ý': 'y', 'ž': 'z', 'ł': 'l',
};

// The Hall of Fame's cards are pre-rendered, all of them, so the page is
// complete without script. Two kinds of island narrow them down in place:
// `HofSearch` sets the query, and a `HofPager` under each grid sets that
// grid's page. Both go through [_apply], which shows the cards that match the
// query and fall on their grid's page, then tells the pagers how many matched.

String _query = '';
final _pages = <String, int>{};
final _matches = <String, int>{};
final _changes = StreamController<void>.broadcast();

/// Fires after every change to the shown cards.
Stream<void> get hofChanges => _changes.stream;

/// [section]'s current page, zero-based.
int hofPage(String section) => _pages[section] ?? 0;

/// How many of [section]'s cards match the query; null before any change.
int? hofMatches(String section) => _matches[section];

/// Filters every grid on [text], from its first page. Returns how many cards
/// match in all.
int setHofQuery(String text) {
  _query = foldForSearch(text);
  _pages.clear();
  return _apply();
}

/// Shows [section]'s page [page].
void setHofPage(String section, int page) {
  _pages[section] = page;
  _apply();
}

/// Shows each `[data-hof-grid]`'s matching cards on its current page (the
/// grid's `data-page-size` per page), and its `data-hof-empty` message when
/// nothing matches. Returns how many cards matched in all.
int _apply() {
  final grids = web.document.querySelectorAll('[data-hof-grid]');
  var total = 0;
  for (var g = 0; g < grids.length; g++) {
    final grid = grids.item(g) as web.Element;
    final section = grid.getAttribute('data-hof-grid') ?? '';
    final size = int.tryParse(grid.getAttribute('data-page-size') ?? '') ?? 1 << 30;
    final cards = grid.querySelectorAll('[data-hof]');
    final hits = [
      for (var i = 0; i < cards.length; i++)
        if (cards.item(i) case final web.Element card
            when _query.isEmpty || (card.getAttribute('data-hof') ?? '').contains(_query))
          card,
    ];
    final pages = (hits.length / size).ceil();
    final page = (_pages[section] ?? 0).clamp(0, pages == 0 ? 0 : pages - 1);
    _pages[section] = page;
    for (var i = 0; i < cards.length; i++) {
      (cards.item(i) as web.Element).toggleAttribute('hidden', true);
    }
    for (final card in hits.skip(page * size).take(size)) {
      card.toggleAttribute('hidden', false);
    }
    grid.parentElement?.querySelector('[data-hof-empty]')?.toggleAttribute('hidden', hits.isNotEmpty);
    _matches[section] = hits.length;
    total += hits.length;
  }
  _changes.add(null);
  return total;
}
