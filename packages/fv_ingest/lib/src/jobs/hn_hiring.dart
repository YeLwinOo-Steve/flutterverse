import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../http_util.dart';
import 'ats/job_board.dart';
import 'posting.dart';

/// The monthly "Ask HN: Who is hiring?" thread, read through YC's official
/// Hacker News API (hacker-news.firebaseio.com). YC's terms forbid scraping
/// "except as expressly authorized by Y Combinator", and this is the API YC
/// publishes, so it is used rather than a third-party mirror.
///
/// Posts are free-form: the title is the first line as written (cut to
/// [maxTitle] characters), the company is the text before its first `|`, and
/// every row links to the HN comment itself, crediting the source.
class HnHiring {
  HnHiring(this._client, {this.concurrency = 8});

  final http.Client _client;
  final int concurrency;

  static const maxTitle = 140;
  static const _api = 'hacker-news.firebaseio.com';

  /// How many of `whoishiring`'s newest posts to look through for the
  /// thread; it posts three a month.
  static const _lookBack = 6;

  Future<List<Posting>> fetch() async {
    final user = await getJson(_client, Uri.https(_api, '/v0/user/whoishiring.json'));
    final submitted = [for (final id in (user as Json?)?['submitted'] as List<Object?>? ?? const []) '$id'];
    Json? thread;
    for (final id in submitted.take(_lookBack)) {
      final item = await _item(id);
      if ('${item?['title']}'.startsWith('Ask HN: Who is hiring')) {
        thread = item;
        break;
      }
    }
    if (thread == null) throw const JobFeedException('hn: no "Who is hiring?" thread');
    final kids = [for (final k in thread['kids'] as List<Object?>? ?? const []) '$k'];
    final items = await mapPool(kids, concurrency, (id) async {
      try {
        return await _item(id);
      } on JobFeedException {
        return null;
      }
    });
    return [
      for (final c in items)
        if (c != null && c['deleted'] != true && c['dead'] != true)
          if (c['text'] case final String html) ?parseHnPost('${c['id']}', html),
    ];
  }

  Future<Json?> _item(String id) async => await getJson(_client, Uri.https(_api, '/v0/item/$id.json')) as Json?;
}

final _remote = RegExp(r'\bremote\b', caseSensitive: false);

/// Turns one top-level post into a [Posting], or null when it is empty. It
/// always links to the HN comment, the post's own page, never a URL inside it.
Posting? parseHnPost(String id, String html) {
  final firstHtml = html.split(RegExp(r'<p>', caseSensitive: false)).first;
  final first = htmlToText(firstHtml);
  if (first.isEmpty) return null;
  final company = first.split('|').first.trim();
  return Posting(
    id: id,
    title: first.length <= HnHiring.maxTitle ? first : '${first.substring(0, HnHiring.maxTitle - 1).trimRight()}…',
    url: 'https://news.ycombinator.com/item?id=$id',
    text: htmlToText(html),
    remote: _remote.hasMatch(first) ? true : null,
    company: company.isEmpty || company.length > 60 ? 'Hacker News post' : company,
  );
}
