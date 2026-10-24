import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';

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

/// Filters the pre-rendered Hall of Fame cards as you type. Each card carries
/// its [hofSearchText] in `data-hof`; each grid has a hidden `data-hof-empty`
/// message, shown when none of its cards match.
@client
class HofSearch extends StatefulComponent {
  const HofSearch({super.key});

  @override
  State<HofSearch> createState() => _HofSearchState();

  @css
  static List<StyleRule> get styles => [
    rule('.hof-search', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'height': '44px',
      'padding': '0 14px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'color': 'var(--muted)',
      'flex': '0 1 360px',
      'min-width': '280px',
    }),
    rule('.hof-search:focus-within', {'border-color': 'var(--ink)'}),
    rule('.hof-search input', {
      'flex': '1',
      'min-width': '0',
      'border': '0',
      'outline': '0',
      'background': 'transparent',
      'color': 'var(--ink)',
      'font-size': '15px',
    }),
    rule('.hof-search-count', {'font': mono(12, weight: 400), 'white-space': 'nowrap'}),
    // Cards set their own display, which would beat the UA's [hidden] rule.
    rule('[data-hof][hidden], [data-hof-empty][hidden]', {'display': 'none'}),
  ];
}

class _HofSearchState extends State<HofSearch> {
  String _query = '';
  int _matches = 0;

  void _filter(String query) {
    final q = foldForSearch(query);
    var matches = 0;
    final grids = web.document.querySelectorAll('[data-hof-grid]');
    for (var g = 0; g < grids.length; g++) {
      final grid = grids.item(g) as web.Element;
      final cards = grid.querySelectorAll('[data-hof]');
      var shown = 0;
      for (var i = 0; i < cards.length; i++) {
        final card = cards.item(i) as web.Element;
        final hit = q.isEmpty || (card.getAttribute('data-hof') ?? '').contains(q);
        card.toggleAttribute('hidden', !hit);
        if (hit) shown++;
      }
      grid.parentElement?.querySelector('[data-hof-empty]')?.toggleAttribute('hidden', shown > 0);
      matches += shown;
    }
    setState(() {
      _query = query;
      _matches = matches;
    });
  }

  @override
  Component build(BuildContext context) {
    return label(classes: 'hof-search', [
      const Icon(Icons.search, size: 16, strokeWidth: 1.5),
      input<String>(
        type: InputType.search,
        value: _query,
        attributes: {
          'placeholder': 'Search developers and projects',
          'aria-label': 'Search the Hall of Fame',
          'autocomplete': 'off',
        },
        onInput: _filter,
      ),
      if (_query.trim().isNotEmpty)
        span(
          classes: 'hof-search-count',
          attributes: {'aria-live': 'polite'},
          [
            .text('$_matches ${_matches == 1 ? 'match' : 'matches'}'),
          ],
        ),
    ]);
  }
}
