import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../http_util.dart';

class PubDevClient {
  PubDevClient(this._http, {this.baseUrl = 'https://pub.dev', this.retryDelay = const Duration(seconds: 2)});

  final http.Client _http;
  final String baseUrl;
  final Duration retryDelay;

  static const _headers = {'user-agent': 'flutterverse-ingest (+https://github.com/flutterverse)'};

  /// Package info, score and download history, or null if the package
  /// doesn't exist. Throws on any other failure, except for the weekly
  /// downloads, which are best effort and become null.
  Future<PubStats?> fetch(String name, {required DateTime now}) async {
    final info = await _getJson('/api/packages/$name');
    if (info == null) return null;
    final score = await _getJson('/api/packages/$name/score') ?? const {};
    WeeklyDownloads? weekly;
    try {
      weekly = await _weeklyDownloads(name);
    } on Object {
      weekly = null;
    }
    return parsePackage(info, score, weekly: weekly, now: now);
  }

  /// All Flutter Favorite package names, following pagination.
  Future<List<String>> flutterFavorites() async {
    final names = <String>[];
    String? url = '$baseUrl/api/search?q=is:flutter-favorite';
    while (url != null) {
      final res = await withRetry(() => _http.get(Uri.parse(url!), headers: _headers), baseDelay: retryDelay);
      if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', Uri.parse(url));
      final json = jsonDecode(res.body) as Map<String, Object?>;
      for (final p in (json['packages'] as List<Object?>).cast<Map<String, Object?>>()) {
        names.add(p['package'] as String);
      }
      url = json['next'] as String?;
    }
    return names;
  }

  /// pub.dev has no API for download history, but the score page embeds the
  /// weekly series as base64 JSON in `data-downloads-chart-points`.
  Future<WeeklyDownloads?> _weeklyDownloads(String name) async {
    final uri = Uri.parse('$baseUrl/packages/$name/score');
    final res = await withRetry(() => _http.get(uri, headers: _headers), baseDelay: retryDelay);
    if (res.statusCode != 200) return null;
    return parseWeeklyDownloads(res.body);
  }

  Future<Map<String, Object?>?> _getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await withRetry(() => _http.get(uri, headers: _headers), baseDelay: retryDelay);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}', uri);
    return jsonDecode(res.body) as Map<String, Object?>;
  }
}

const _platformNames = {
  'ios': 'iOS',
  'android': 'Android',
  'web': 'Web',
  'macos': 'macOS',
  'windows': 'Windows',
  'linux': 'Linux',
};

/// Builds [PubStats] from `/api/packages/<name>` and its `/score`.
PubStats parsePackage(
  Map<String, Object?> info,
  Map<String, Object?> score, {
  WeeklyDownloads? weekly,
  required DateTime now,
}) {
  final latest = info['latest'] as Map<String, Object?>;
  final pubspec = latest['pubspec'] as Map<String, Object?>;
  final env = (pubspec['environment'] as Map<String, Object?>?) ?? const {};
  final tags = ((score['tags'] as List<Object?>?) ?? const []).cast<String>();
  List<String> tagged(String prefix) => [
    for (final t in tags)
      if (t.startsWith(prefix)) t.substring(prefix.length),
  ];

  final releases = [
    for (final v in ((info['versions'] as List<Object?>?) ?? const []).cast<Map<String, Object?>>())
      if (v['published'] != null)
        Release(version: v['version'] as String, date: DateTime.parse(v['published'] as String)),
  ]..sort((a, b) => a.date.compareTo(b.date));

  final platformTags = tagged('platform:');
  final license = tagged('license:').where((l) => !const {'fsf-libre', 'osi-approved'}.contains(l)).firstOrNull;

  return PubStats(
    version: latest['version'] as String?,
    published: latest['published'] == null ? null : DateTime.parse(latest['published'] as String),
    firstPublished: releases.firstOrNull?.date,
    releasesLastYear: releases.isEmpty ? null : releases.where((r) => now.difference(r.date).inDays <= 365).length,
    majors: majorReleases(releases),
    likes: (score['likeCount'] as num?)?.toInt(),
    points: (score['grantedPoints'] as num?)?.toInt(),
    maxPoints: (score['maxPoints'] as num?)?.toInt(),
    downloads: (score['downloadCount30Days'] as num?)?.toInt(),
    weeklyDownloads: weekly?.counts,
    weeklyDownloadsEnd: weekly?.end,
    publisher: tagged('publisher:').firstOrNull,
    description: (pubspec['description'] as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim(),
    repository: (pubspec['repository'] ?? pubspec['homepage']) as String?,
    license: license?.toUpperCase().replaceFirst('CLAUSE', 'Clause'),
    dartSdk: env['sdk'] as String?,
    flutterSdk: env['flutter'] as String?,
    sdks: [
      for (final s in tagged('sdk:'))
        if (s == 'dart') 'Dart' else if (s == 'flutter') 'Flutter',
    ],
    platforms: [
      for (final e in _platformNames.entries)
        if (platformTags.contains(e.key)) e.value,
      if (tags.contains('is:wasm-ready')) 'WASM',
    ],
    flutterFavorite: tags.contains('is:flutter-favorite'),
  );
}

final _semver = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

/// The first stable release of each major version from 1 on, oldest first.
List<Release> majorReleases(List<Release> sortedReleases) {
  final seen = <int>{};
  return [
    for (final r in sortedReleases)
      if (_semver.firstMatch(r.version) case final m? when int.parse(m[1]!) >= 1 && seen.add(int.parse(m[1]!))) r,
  ];
}

final _chartPoints = RegExp(r'data-downloads-chart-points="([^"]*)"');

/// Weekly download counts, oldest first, and the day the last week ends.
typedef WeeklyDownloads = ({List<int> counts, DateTime? end});

/// Extracts `totalWeeklyDownloads` (newest first in the page) as oldest
/// first. Null when the attribute is missing or malformed.
WeeklyDownloads? parseWeeklyDownloads(String html) {
  final m = _chartPoints.firstMatch(html);
  if (m == null) return null;
  try {
    final raw = m[1]!.replaceAll('&#x3D;', '=').replaceAll('&quot;', '"');
    final json = jsonDecode(utf8.decode(base64.decode(base64.normalize(raw)))) as Map<String, Object?>;
    final weeks = (json['totalWeeklyDownloads'] as List<Object?>).map((e) => (e as num).toInt()).toList();
    final end = json['newestDate'] as String?;
    return (counts: weeks.reversed.toList(), end: end == null ? null : DateTime.parse(end));
  } on Object {
    return null;
  }
}

final _githubUrl = RegExp(r'^https?://(?:www\.)?github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)');

/// `https://github.com/cfug/dio/blob/main/dio` → `cfug/dio`; null otherwise.
String? githubRepoFromUrl(String? url) {
  final m = url == null ? null : _githubUrl.firstMatch(url.trim());
  if (m == null) return null;
  final name = m[2]!.endsWith('.git') ? m[2]!.substring(0, m[2]!.length - 4) : m[2]!;
  return '${m[1]}/$name';
}
