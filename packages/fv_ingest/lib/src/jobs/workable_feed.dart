import 'dart:convert';
import 'dart:io';

import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'company_search.dart';
import 'posting.dart';

/// Workable's official XML job feed, which carries every Workable customer's
/// published jobs. Workable's help centre documents it for this use: "share
/// this with a job board/partner we don't integrate with to programmatically
/// get your job postings ... and publish them under their site", and says to
/// "read/download the full file and then filter the data on your end".
/// https://help.workable.com/hc/en-us/articles/4420464031767
///
/// The file is large (about 670 MB), so it is streamed and parsed one
/// `<job>` at a time, never held whole. Roles published more than [maxAge]
/// before [now] are skipped: the feed keeps some postings open for years.
class WorkableFeed implements CompanySearch {
  WorkableFeed(
    this._client, {
    required this.now,
    this.maxAge = const Duration(days: 365),
    this.retryPause = const Duration(seconds: 10),
    this.maxWait = const Duration(minutes: 2),
  });

  final http.Client _client;
  final DateTime now;
  final Duration maxAge;

  /// The pause before retry n is n × this, unless the server says otherwise.
  final Duration retryPause;

  /// The longest the feed waits before a retry, whatever `Retry-After` says.
  final Duration maxWait;

  static final feedUrl = Uri.https('www.workable.com', '/boards/workable.xml');

  @override
  JobSource get source => JobSource.workable;

  @override
  String companyId(String name) => searchCompanyId('wk', name);

  @override
  Future<List<Posting>> fetch() async {
    // Download to a temp file at full speed, then parse from disk. Parsing
    // straight off the socket is slower than the download, and Workable's
    // server drops a connection that backs up.
    final dir = await Directory.systemTemp.createTemp('fv_workable');
    try {
      final file = File(p.join(dir.path, 'workable.xml'));
      await _download(file);
      return await parseWorkableFeed(file.openRead(), now: now, maxAge: maxAge).toList();
    } finally {
      await dir.delete(recursive: true);
    }
  }

  /// Retries a dropped connection, and a 429 or 5xx after the server's
  /// `Retry-After` (capped at [maxWait]) or a growing pause.
  Future<void> _download(File file, {int attempts = 3}) async {
    for (var attempt = 1; ; attempt++) {
      Duration? wait;
      try {
        final res = await _client.send(http.Request('GET', feedUrl));
        if (res.statusCode == 200) {
          await res.stream.pipe(file.openWrite());
          return;
        }
        await res.stream.drain<void>();
        final retryable = res.statusCode == 429 || res.statusCode >= 500;
        if (!retryable || attempt >= attempts) throw JobFeedException('workable feed: HTTP ${res.statusCode}');
        final after = int.tryParse(res.headers['retry-after'] ?? '');
        wait = after == null ? null : Duration(seconds: after);
      } on http.ClientException {
        if (attempt >= attempts) rethrow;
      }
      final pause = wait ?? retryPause * attempt;
      await Future<void>.delayed(pause > maxWait ? maxWait : pause);
    }
  }
}

/// Parses the feed's bytes into postings, one `<job>` block at a time.
Stream<Posting> parseWorkableFeed(
  Stream<List<int>> bytes, {
  required DateTime now,
  Duration maxAge = const Duration(days: 365),
}) async* {
  var pending = '';
  await for (final chunk in const Utf8Decoder(allowMalformed: true).bind(bytes)) {
    pending += chunk;
    var end = pending.indexOf('</job>');
    while (end >= 0) {
      final block = pending.substring(0, end);
      pending = pending.substring(end + 6);
      if (_posting(block, now: now, maxAge: maxAge) case final p?) yield p;
      end = pending.indexOf('</job>');
    }
  }
}

/// Jobs that never mention Flutter or Dart can't match, so they are skipped
/// before any parsing: the feed has over 100,000 jobs, and keeping them all
/// would cost hundreds of megabytes.
final _maybeFlutter = RegExp(r'flutter|\bdart\b', caseSensitive: false);

Posting? _posting(String block, {required DateTime now, required Duration maxAge}) {
  if (!_maybeFlutter.hasMatch(block)) return null;
  final title = nonBlank(_field(block, 'title'));
  final url = nonBlank(_field(block, 'url'));
  final company = nonBlank(_field(block, 'company'));
  final id = nonBlank(_field(block, 'referencenumber'));
  if (title == null || url == null || company == null || id == null) return null;
  final published = _date(_field(block, 'date'));
  if (published != null && now.difference(published) > maxAge) return null;
  final place = [
    nonBlank(_field(block, 'city')),
    nonBlank(_field(block, 'state')),
    nonBlank(_field(block, 'country')),
  ].whereType<String>().toSet().join(', ');
  return Posting(
    id: id,
    title: title,
    url: url,
    company: company,
    text: switch (_field(block, 'description')) {
      final String html => htmlToText(html),
      _ => null,
    },
    location: place.isEmpty ? null : place,
    remote: _field(block, 'remote')?.trim() == 'true' ? true : null,
  );
}

String? _field(String block, String name) {
  final m = RegExp('<$name>\\s*<!\\[CDATA\\[(.*?)\\]\\]>\\s*</$name>', dotAll: true).firstMatch(block);
  return m?[1];
}

const _months = {
  'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, //
  'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
};

/// "Wed, 28 Jul 2021 10:24:17 UTC" → a UTC date.
DateTime? _date(String? s) {
  final m = RegExp(r'(\d{1,2}) ([A-Z][a-z]{2}) (\d{4})').firstMatch(s ?? '');
  final month = _months[m?[2]];
  if (m == null || month == null) return null;
  return DateTime.utc(int.parse(m[3]!), month, int.parse(m[1]!));
}
