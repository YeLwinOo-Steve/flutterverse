import 'package:fv_core/fv_core.dart';

import 'ranking.dart';

/// Every project grouped by author: its GitHub owner and its pub.dev
/// publisher, lowercased, so a project lands under both. Each group is
/// sorted by stars.
Map<String, List<ProjectRow>> authorIndex(Iterable<ProjectRow> rows) {
  final groups = <String, List<ProjectRow>>{};
  for (final r in rows) {
    for (final key in _authorKeys(r)) {
      (groups[key] ??= []).add(r);
    }
  }
  return {for (final MapEntry(:key, :value) in groups.entries) key: sortedBy(value, (r) => r.shownStars)};
}

/// Up to [max] other projects by [row]'s author, most starred first,
/// leaving out [exclude] (the projects already shown as related).
List<ProjectRow> moreByAuthor(
  ProjectRow row,
  Map<String, List<ProjectRow>> byAuthor, {
  Set<String> exclude = const {},
  int max = 6,
}) {
  final seen = {row.id, ...exclude};
  return [
    for (final key in _authorKeys(row))
      for (final r in byAuthor[key] ?? const <ProjectRow>[])
        if (seen.add(r.id)) r,
  ].take(max).toList();
}

Set<String> _authorKeys(ProjectRow r) => {?r.owner?.toLowerCase(), ?r.publisher?.toLowerCase()};
