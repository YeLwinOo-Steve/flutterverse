import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';
import 'hof_filter.dart';

/// Filters the Hall of Fame cards as you type, on [hofSearchText] (each
/// card's `data-hof`). A new query starts every grid on its first page.
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
  String _text = '';
  int _count = 0;

  void _filter(String text) {
    final count = setHofQuery(text);
    setState(() {
      _text = text;
      _count = count;
    });
  }

  @override
  Component build(BuildContext context) {
    return label(classes: 'hof-search', [
      const Icon(Icons.search, size: 16, strokeWidth: 1.5),
      input<String>(
        type: InputType.search,
        value: _text,
        attributes: {
          'placeholder': 'Search developers and projects',
          'aria-label': 'Search the Hall of Fame',
          'autocomplete': 'off',
        },
        onInput: _filter,
      ),
      if (_text.trim().isNotEmpty)
        span(
          classes: 'hof-search-count',
          attributes: {'aria-live': 'polite'},
          [
            .text('$_count ${_count == 1 ? 'match' : 'matches'}'),
          ],
        ),
    ]);
  }
}
