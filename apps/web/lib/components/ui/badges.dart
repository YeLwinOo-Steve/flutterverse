import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/view.dart';
import 'icon.dart';
import 'icons.dart';

/// A rounded mono category label.
Component categoryPill(String label, {String padding = '4px 8px'}) =>
    span(classes: 'pill', styles: Styles(raw: {'padding': padding}), [.text(label)]);

/// `● Active` / `● Slowing` / `● Low activity`.
Component healthPill(ProjectRow r) => span(classes: 'health ${r.healthClass}', [.text(r.healthLabel)]);

/// The accent "Flutter Favorite" badge.
Component favoriteBadge() => span(
  classes: 'ff-badge',
  attributes: {'title': 'Flutter Favorite'},
  [
    const Icon(Icons.star, size: 12, filled: true),
    .text('Flutter Favorite'),
  ],
);

/// `↑ +12 today`.
Component growthChip(String text) => span(classes: 'growth', [.text('↑ $text')]);
