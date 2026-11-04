import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../jobs_config.dart';
import '../posting.dart';
import 'job_board.dart';

final _remote = RegExp(r'\bremote\b', caseSensitive: false);

/// Greenhouse's public job board API:
/// `boards-api.greenhouse.io/v1/boards/<token>/jobs?content=true`.
///
/// `content=true` adds the (escaped HTML) description, needed to find
/// Flutter outside the title. Greenhouse has no remote flag, so a location
/// that says "Remote" is taken as the feed saying so.
class GreenhouseBoard implements JobBoard {
  GreenhouseBoard(this._client);

  final http.Client _client;

  @override
  Future<List<Posting>> fetch(JobCompany company) async {
    final url = Uri.https('boards-api.greenhouse.io', '/v1/boards/${company.token}/jobs', {'content': 'true'});
    final body = await getJson(_client, url);
    if (body is! Json || body['jobs'] is! List) throw const JobFeedException('greenhouse: no `jobs` list');
    return [
      for (final j in (body['jobs']! as List<Object?>).whereType<Json>())
        if (nonBlank(j['title']) case final title? when j['absolute_url'] is String)
          Posting(
            id: '${j['id']}',
            title: title,
            url: j['absolute_url']! as String,
            text: switch (j['content']) {
              final String html => htmlToText(html),
              _ => null,
            },
            location: nonBlank((j['location'] as Json?)?['name']),
            remote: _remote.hasMatch(((j['location'] as Json?)?['name'] as String?) ?? '') ? true : null,
          ),
    ];
  }
}
