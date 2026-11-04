import 'package:fv_core/fv_core.dart';
import 'package:yaml/yaml.dart';

/// The hiring systems a company in `config/jobs.yaml` can use.
const jobBoards = {JobSource.greenhouse, JobSource.lever, JobSource.ashby};

/// One company in `config/jobs.yaml`.
class JobCompany {
  const JobCompany({
    required this.id,
    required this.name,
    required this.ats,
    required this.token,
    this.region,
    this.careers,
  });

  /// Lowercase slug, unique in the file.
  final String id;
  final String name;

  /// The hiring system, null when the file names an unknown one (reported by
  /// [validateJobsConfig]).
  final JobSource? ats;

  /// The company's board token, slug or name on [ats].
  final String token;

  /// Lever only: `eu` for accounts on `api.eu.lever.co`.
  final String? region;

  /// The company's own careers page.
  final String? careers;

  /// What the YAML said for `ats`, kept for error messages.
  String get atsName => ats?.name ?? '?';
}

/// Parses `config/jobs.yaml`. Throws [FormatException] when the shape is
/// wrong; [validateJobsConfig] does the semantic checks.
List<JobCompany> parseJobsConfig(String source) {
  final doc = loadYaml(source);
  if (doc == null) return const [];
  if (doc is! YamlMap) throw const FormatException('jobs.yaml must be a map');
  final list = doc['companies'];
  if (list == null) return const [];
  if (list is! YamlList) throw const FormatException('jobs.yaml: `companies` must be a list');
  return [
    for (final (i, e) in list.indexed)
      if (e is YamlMap)
        JobCompany(
          id: '${e['id'] ?? ''}',
          name: '${e['name'] ?? ''}',
          ats: JobSource.parse(e['ats'] as String?),
          token: '${e['token'] ?? ''}',
          region: e['region'] as String?,
          careers: e['careers'] as String?,
        )
      else
        throw FormatException('jobs.yaml: company #${i + 1} must be a map'),
  ];
}

final _idPattern = RegExp(r'^[a-z0-9][a-z0-9_-]*$');
final _tokenPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]*$');

/// Offline checks. Returns a list of problems (empty = valid).
List<String> validateJobsConfig(List<JobCompany> companies) {
  final errors = <String>[];
  final ids = <String>{};
  final boards = <String>{};
  for (final c in companies) {
    final where = 'company "${c.id}"';
    if (!_idPattern.hasMatch(c.id)) errors.add('$where: id must match ${_idPattern.pattern}');
    if (c.id == 'hn') errors.add('$where: "hn" is reserved for Hacker News rows');
    if (!ids.add(c.id)) errors.add('$where: duplicate id');
    if (c.name.trim().isEmpty) errors.add('$where: needs a `name`');
    if (c.ats == null || !jobBoards.contains(c.ats)) {
      errors.add('$where: `ats` must be one of ${jobBoards.map((b) => b.name).join(', ')}');
    }
    if (!_tokenPattern.hasMatch(c.token)) errors.add('$where: `token` is missing or malformed');
    if (!boards.add('${c.atsName}/${c.token.toLowerCase()}')) errors.add('$where: same board as another company');
    if (c.region != null && (c.ats != JobSource.lever || c.region != 'eu')) {
      errors.add('$where: `region` is only for Lever, and must be "eu"');
    }
    if (c.careers != null && !c.careers!.startsWith('https://')) errors.add('$where: `careers` must be an https URL');
  }
  return errors;
}

/// `exclude_companies:` in `config/jobs.yaml`: company names (any case) whose
/// roles are dropped from cross-company sources such as [JobSource.workable],
/// for recruiters and marketplaces that post other companies' roles.
Set<String> parseJobsExclude(String source) {
  final doc = loadYaml(source);
  if (doc is! YamlMap) return const {};
  final list = doc['exclude_companies'];
  if (list == null) return const {};
  if (list is! YamlList) throw const FormatException('jobs.yaml: `exclude_companies` must be a list');
  return {for (final e in list) normalizeCompany('$e')};
}

/// A company name for comparing: lowercase, single spaces, and legal-form
/// words such as "Inc.", "Ltd", "Pte" and "GmbH" removed.
String normalizeCompany(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[.,]'), ' ')
    .replaceAll(RegExp(r'\b(inc|ltd|llc|gmbh|corp|corporation|co|pte|plc|bv|sdn|bhd)\b'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
