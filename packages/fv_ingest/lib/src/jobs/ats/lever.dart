import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../jobs_config.dart';
import '../posting.dart';
import 'job_board.dart';

/// Lever's postings API: `api.lever.co/v0/postings/<slug>?mode=json`.
///
/// Pages of [pageSize] through `skip` and `limit`. Some accounts live only
/// on `api.eu.lever.co`: `region: eu` goes there directly, and a 404 on the
/// global host retries there.
class LeverBoard implements JobBoard {
  LeverBoard(this._client, {this.pageSize = 100});

  final http.Client _client;
  final int pageSize;

  @override
  Future<List<Posting>> fetch(JobCompany company) async {
    if (company.region == 'eu') return _fetchAll('api.eu.lever.co', company.token);
    try {
      return await _fetchAll('api.lever.co', company.token);
    } on JobFeedException catch (e) {
      if (!e.message.endsWith('HTTP 404')) rethrow;
      return _fetchAll('api.eu.lever.co', company.token);
    }
  }

  Future<List<Posting>> _fetchAll(String host, String slug) async {
    final out = <Posting>[];
    for (var skip = 0; ; skip += pageSize) {
      final url = Uri.https(host, '/v0/postings/$slug', {'mode': 'json', 'skip': '$skip', 'limit': '$pageSize'});
      final body = await getJson(_client, url);
      if (body is! List) throw const JobFeedException('lever: expected a list');
      out.addAll(body.whereType<Json>().map(_posting).whereType<Posting>());
      if (body.length < pageSize) return out;
    }
  }

  Posting? _posting(Json j) {
    final title = nonBlank(j['text']);
    final url = j['hostedUrl'];
    if (title == null || url is! String) return null;
    final lists = [
      for (final l in (j['lists'] as List<Object?>? ?? const []).whereType<Json>()) ...[
        ?(l['text'] as String?),
        if (l['content'] case final String html) htmlToText(html),
      ],
    ];
    return Posting(
      id: '${j['id']}',
      title: title,
      url: url,
      text: [?(j['descriptionPlain'] as String?), ...lists, ?(j['additionalPlain'] as String?)].join('\n'),
      location: nonBlank((j['categories'] as Json?)?['location']),
      remote: j['workplaceType'] == 'remote' ? true : null,
    );
  }
}
