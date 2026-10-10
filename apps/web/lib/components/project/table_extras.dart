import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// The table's empty state.
class TableEmpty extends StatelessComponent {
  const TableEmpty({required this.title, required this.message, this.resetHref, super.key});

  final String title;
  final String message;

  /// Shows a "Reset filters" link when set.
  final String? resetHref;

  @override
  Component build(BuildContext context) {
    return div(classes: 'empty', [
      b([.text(title)]),
      span([.text(message)]),
      if (resetHref != null)
        a(href: resetHref!, classes: 'btn small', styles: Styles(raw: {'margin-top': '8px'}), [.text('Reset filters')]),
    ]);
  }
}

/// The legend under every project table.
class TableLegend extends StatelessComponent {
  const TableLegend({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'table-legend', [
      .text(
        '“N/A” = metric unavailable from source · “—” = not applicable (e.g. not published to pub.dev). Momentum is a '
        'Flutterverse calculated score (0–100) weighting recent growth over lifetime stars; “~” marks an early '
        'estimate from under a week of history.',
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.table-legend', {'margin-top': '12px', 'font-size': '13px', 'color': 'var(--muted)'}),
  ];
}
