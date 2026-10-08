import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../http_util.dart';
import '../nominations.dart';

/// Fetches repository and user stats through GitHub's GraphQL API, in
/// batches of [batchSize] per query, which is far cheaper on rate limits
/// than one REST call each.
class GithubClient {
  GithubClient(
    this._http, {
    required this.token,
    this.endpoint = 'https://api.github.com/graphql',
    this.restBase = 'https://api.github.com',
    this.batchSize = 50,
    this.retryDelay = const Duration(seconds: 2),
  });

  final http.Client _http;
  final String token;
  final String endpoint;
  final String restBase;
  final int batchSize;
  final Duration retryDelay;

  /// Stats keyed by the requested `owner/name`. Repos that don't resolve, or
  /// whose batch failed, are missing from the result; [onError] is told why.
  Future<Map<String, GhStats>> fetchAll(Iterable<String> repos, {void Function(String message)? onError}) =>
      _batched(repos.toSet().toList(), _repoQuery, _parseRepo, onError);

  /// `(followers, public repos)` keyed by login.
  Future<Map<String, (int?, int?)>> fetchUsers(Iterable<String> logins, {void Function(String message)? onError}) =>
      _batched(logins.toSet().toList(), _userQuery, _parseUser, onError);

  /// Contributor count from the REST API's pagination (GraphQL doesn't
  /// expose it). Null on failure.
  Future<int?> contributors(String repo) async {
    final uri = Uri.parse('$restBase/repos/$repo/contributors?per_page=1&anon=1');
    final res = await withRetry(() => _http.get(uri, headers: _headers), baseDelay: retryDelay);
    if (res.statusCode != 200) return null;
    final last = RegExp(r'[?&]page=(\d+)>; rel="last"').firstMatch(res.headers['link'] ?? '');
    if (last != null) return int.parse(last[1]!);
    return (jsonDecode(res.body) as List<Object?>).length;
  }

  /// A user or organization, or null if [login] doesn't exist.
  Future<GhAccount?> account(String login) async {
    final json = await _restJson('/users/${Uri.encodeComponent(login)}');
    if (json is! Map<String, Object?>) return null;
    return GhAccount(
      login: json['login'] as String,
      isOrganization: json['type'] == 'Organization',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Repository basics, or null if [repo] (`owner/name`) doesn't exist.
  /// Follows renames, so [GhRepoInfo.fullName] is the canonical name.
  Future<GhRepoInfo?> repoInfo(String repo) async {
    final json = await _restJson('/repos/$repo');
    if (json is! Map<String, Object?>) return null;
    return GhRepoInfo(
      fullName: json['full_name'] as String,
      stars: (json['stargazers_count'] as num?)?.toInt() ?? 0,
      archived: json['archived'] as bool? ?? false,
      fork: json['fork'] as bool? ?? false,
    );
  }

  /// Open issues (not pull requests) in [repo] carrying [label], up to
  /// [maxPages] pages of 100.
  Future<List<OpenNomination>> openNominations(String repo, {String label = 'nomination', int maxPages = 10}) async {
    final out = <OpenNomination>[];
    for (var page = 1; page <= maxPages; page++) {
      final json = await _restJson(
        '/repos/$repo/issues?state=open&labels=${Uri.encodeQueryComponent(label)}&per_page=100&page=$page',
      );
      if (json is! List<Object?> || json.isEmpty) break;
      for (final issue in json.cast<Map<String, Object?>>()) {
        if (issue.containsKey('pull_request')) continue;
        out.add(
          OpenNomination(
            number: (issue['number'] as num).toInt(),
            author: (issue['user'] as Map<String, Object?>)['login'] as String,
            nomination: parseNomination(issue['body'] as String? ?? ''),
          ),
        );
      }
      if (json.length < 100) break;
    }
    return out;
  }

  /// Decoded JSON for a REST GET, or null on 404. Throws on other failures.
  Future<Object?> _restJson(String path) async {
    final uri = Uri.parse('$restBase$path');
    final res = await withRetry(
      () => _http.get(uri, headers: {..._headers, 'accept': 'application/vnd.github+json'}),
      baseDelay: retryDelay,
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}: ${res.body}', uri);
    return jsonDecode(res.body);
  }

  Map<String, String> get _headers => {'authorization': 'bearer $token'};

  Future<Map<String, T>> _batched<T>(
    List<String> keys,
    String Function(int alias, String key) field,
    T Function(Map<String, Object?>) parse,
    void Function(String)? onError,
  ) async {
    final out = <String, T>{};
    for (var i = 0; i < keys.length; i += batchSize) {
      final batch = keys.sublist(i, (i + batchSize).clamp(0, keys.length));
      try {
        final data = await _query([for (final (j, k) in batch.indexed) field(j, k)], onError);
        for (final (j, k) in batch.indexed) {
          if (data['r$j'] case final Map<String, Object?> node) out[k] = parse(node);
        }
      } on Object catch (e) {
        onError?.call('GitHub batch ${i ~/ batchSize + 1} failed: $e');
      }
    }
    return out;
  }

  Future<Map<String, Object?>> _query(List<String> fields, void Function(String)? onError) async {
    // GraphQL rejects unused fragments, so only append it when referenced.
    final fragment = fields.any((f) => f.contains('...F')) ? _fragment : '';
    final query = 'query {\n${fields.join('\n')}\n}\n$fragment';
    final res = await withRetry(
      () => _http.post(
        Uri.parse(endpoint),
        headers: {..._headers, 'content-type': 'application/json'},
        body: jsonEncode({'query': query}),
      ),
      baseDelay: retryDelay,
    );
    if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}: ${res.body}', Uri.parse(endpoint));
    final json = jsonDecode(res.body) as Map<String, Object?>;
    // Missing repos/users come back as per-alias errors alongside partial data.
    for (final e in (json['errors'] as List<Object?>? ?? const []).cast<Map<String, Object?>>()) {
      onError?.call('GitHub: ${e['message']}');
    }
    return json['data'] as Map<String, Object?>? ?? const {};
  }

  static String _repoQuery(int i, String repo) {
    final [owner, name] = repo.split('/');
    return '  r$i: repository(owner: ${jsonEncode(owner)}, name: ${jsonEncode(name)}) { ...F }';
  }

  static String _userQuery(int i, String login) =>
      '  r$i: user(login: ${jsonEncode(login)}) { followers { totalCount } '
      'repositories(ownerAffiliations: OWNER, privacy: PUBLIC) { totalCount } }';

  static (int?, int?) _parseUser(Map<String, Object?> u) => (
    ((u['followers'] as Map<String, Object?>?)?['totalCount'] as num?)?.toInt(),
    ((u['repositories'] as Map<String, Object?>?)?['totalCount'] as num?)?.toInt(),
  );

  static GhStats _parseRepo(Map<String, Object?> r) {
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);
    int? count(String key) => ((r[key] as Map<String, Object?>?)?['totalCount'] as num?)?.toInt();
    final langs = r['languages'] as Map<String, Object?>?;
    final total = (langs?['totalSize'] as num?)?.toDouble() ?? 0;
    final commit = (r['defaultBranchRef'] as Map<String, Object?>?)?['target'] as Map<String, Object?>?;
    return GhStats(
      stars: (r['stargazerCount'] as num?)?.toInt(),
      forks: (r['forkCount'] as num?)?.toInt(),
      openIssues: count('issues'),
      watchers: count('watchers'),
      createdAt: date(r['createdAt']),
      pushedAt: date(r['pushedAt']),
      lastCommit: date(commit?['committedDate']),
      license: (r['licenseInfo'] as Map<String, Object?>?)?['spdxId'] as String?,
      languages: [
        if (total > 0)
          for (final e in (langs!['edges'] as List<Object?>).cast<Map<String, Object?>>())
            '${(e['node'] as Map<String, Object?>)['name']} ${_share((e['size'] as num) / total)}',
      ],
      topics: [
        for (final n
            in ((r['repositoryTopics'] as Map<String, Object?>?)?['nodes'] as List<Object?>? ?? const [])
                .cast<Map<String, Object?>>())
          (n['topic'] as Map<String, Object?>)['name'] as String,
      ],
      archived: r['isArchived'] as bool? ?? false,
      description: r['description'] as String?,
    );
  }

  /// `0.996` → `99.6%`, `1.0` → `100%`.
  static String _share(num f) {
    final s = (f * 100).toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}%';
  }

  static const _fragment = '''
fragment F on Repository {
  stargazerCount
  forkCount
  issues(states: OPEN) { totalCount }
  watchers { totalCount }
  createdAt
  pushedAt
  defaultBranchRef { target { ... on Commit { committedDate } } }
  licenseInfo { spdxId }
  languages(first: 2, orderBy: { field: SIZE, direction: DESC }) { totalSize edges { size node { name } } }
  repositoryTopics(first: 20) { nodes { topic { name } } }
  isArchived
  description
}''';
}
