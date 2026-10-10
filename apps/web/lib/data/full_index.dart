import 'package:fv_core/fv_core.dart';
import 'package:jaspr/jaspr.dart';

import 'data_repo.dart';

/// For islands that would be too heavy with every project in their props:
/// the server passes a preview (just what the first render shows) and the
/// browser swaps in the full `index.json` once it arrives.
///
/// Until then, render from [index] only in the island's initial state, which
/// is what the preview was picked for; [loaded] says when other states (a
/// different tab, page or filter) can be rendered too.
mixin FullIndex<T extends StatefulComponent> on State<T> {
  /// The server-picked preview, usually the island's `index` parameter.
  IndexFile get preview;

  IndexFile? _full;

  IndexFile get index => _full ?? preview;
  bool get loaded => _full != null;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    DataRepo.index().then((full) => setState(() => _full = full), onError: (Object _) {});
  }
}

/// [index] with only [rows], for an island's preview.
IndexFile previewOf(IndexFile index, Iterable<ProjectRow> rows) =>
    IndexFile(categories: index.categories, categoryGroups: index.categoryGroups, projects: rows.toList());
