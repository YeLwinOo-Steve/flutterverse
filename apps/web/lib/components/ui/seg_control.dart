import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The design's segmented control. Without [onSelect] it renders static
/// (pre-rendered) markup.
class SegControl<T> extends StatelessComponent {
  const SegControl({required this.options, required this.selected, this.onSelect, this.label, super.key});

  final List<(T, String)> options;
  final T selected;
  final void Function(T)? onSelect;

  /// Accessible name for the group.
  final String? label;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'seg',
      attributes: {'role': 'tablist', 'aria-label': ?label},
      [
        for (final (value, text) in options)
          button(
            classes: value == selected ? 'on' : null,
            attributes: {'role': 'tab', 'aria-selected': '${value == selected}', 'type': 'button'},
            onClick: onSelect == null ? null : () => onSelect!(value),
            [.text(text)],
          ),
      ],
    );
  }
}

/// A wrapping row of chip-style tabs.
class ChipTabs<T> extends StatelessComponent {
  const ChipTabs({required this.options, required this.selected, this.onSelect, this.trailing, super.key});

  final List<(T, String)> options;
  final T selected;
  final void Function(T)? onSelect;

  /// Optional per-option suffix, e.g. a count.
  final String Function(T)? trailing;

  @override
  Component build(BuildContext context) {
    return div(classes: 'chip-tabs', [
      for (final (value, text) in options)
        button(
          classes: value == selected ? 'chip on' : 'chip',
          attributes: {'aria-pressed': '${value == selected}', 'type': 'button'},
          onClick: onSelect == null ? null : () => onSelect!(value),
          [
            .text(text),
            if (trailing != null) span(classes: 'chip-count', [.text(' ${trailing!(value)}')]),
          ],
        ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.chip-tabs').styles(raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    css('.chip-count').styles(raw: {'opacity': '0.6', 'font-family': "'Geist Mono',monospace", 'font-size': '12px'}),
  ];
}
