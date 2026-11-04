import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../jobs_config.dart';
import '../posting.dart';
import 'job_board.dart';

/// Ashby's public posting API: `api.ashbyhq.com/posting-api/job-board/<name>`.
///
/// The list includes `descriptionPlain`. Postings marked `isListed: false`
/// are skipped. `workplaceType` wins over `isRemote`, which some boards set
/// on hybrid roles.
class AshbyBoard implements JobBoard {
  AshbyBoard(this._client);

  final http.Client _client;

  @override
  Future<List<Posting>> fetch(JobCompany company) async {
    final body = await getJson(_client, Uri.https('api.ashbyhq.com', '/posting-api/job-board/${company.token}'));
    if (body is! Json || body['jobs'] is! List) throw const JobFeedException('ashby: no `jobs` list');
    return [
      for (final j in (body['jobs']! as List<Object?>).whereType<Json>())
        if (j['isListed'] != false)
          if (nonBlank(j['title']) case final title? when j['jobUrl'] is String)
            Posting(
              id: '${j['id']}',
              title: title,
              url: j['jobUrl']! as String,
              text: j['descriptionPlain'] as String?,
              location: nonBlank(j['location']),
              remote: _remote(j) ? true : null,
            ),
    ];
  }

  static bool _remote(Json j) => switch (j['workplaceType']) {
    final String w => w.toLowerCase() == 'remote',
    _ => j['isRemote'] == true,
  };
}
