import 'package:fv_core/fv_core.dart';

import 'posting.dart';

/// A source that covers many companies' postings at once (Workable's job
/// feed), unlike a [JobBoard], which reads one company. Each
/// [Posting] carries its company name.
abstract interface class CompanySearch {
  JobSource get source;

  /// A stable id for a company found by this search, distinct from every id
  /// in `config/jobs.yaml` and from other searches'.
  String companyId(String name);

  /// Throws on failure; `runJobs` then carries the source's roles over.
  Future<List<Posting>> fetch();
}

/// `<prefix>-<slug of name>`, e.g. `wk-questronix-corporation`.
String searchCompanyId(String prefix, String name) =>
    '$prefix-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '')}';
