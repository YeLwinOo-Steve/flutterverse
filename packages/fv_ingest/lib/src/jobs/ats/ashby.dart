import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../jobs_config.dart';
import '../posting.dart';
import 'job_board.dart';

/// Ashby's public posting API: `api.ashbyhq.com/posting-api/job-board/<name>`.
///
/// The list includes `descriptionPlain`, and with `includeCompensation`
/// each role's pay. Postings marked `isListed: false` are skipped. `workplaceType` wins over `isRemote`, which some boards set
/// on hybrid roles.
class AshbyBoard implements JobBoard {
  AshbyBoard(this._client);

  final http.Client _client;

  @override
  Future<List<Posting>> fetch(JobCompany company) async {
    final body = await getJson(
      _client,
      Uri.https('api.ashbyhq.com', '/posting-api/job-board/${company.token}', {'includeCompensation': 'true'}),
    );
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
              salary: ashbyPay(j['compensation']),
            ),
    ];
  }

  static bool _remote(Json j) => switch (j['workplaceType']) {
    final String w => w.toLowerCase() == 'remote',
    _ => j['isRemote'] == true,
  };
}

/// The `Salary` component of Ashby's `compensation.summaryComponents`
/// (`minValue`, `maxValue`, `currencyCode`, `interval` like `1 YEAR`).
Salary? ashbyPay(Object? compensation) {
  if (compensation is! Json) return null;
  final parts = (compensation['summaryComponents'] as List<Object?>? ?? const []).whereType<Json>();
  final c = parts.where((p) => p['compensationType'] == 'Salary').firstOrNull;
  if (c == null) return null;
  int? whole(Object? v) => v is num && v > 0 ? v.round() : null;
  final min = whole(c['minValue']);
  final max = whole(c['maxValue']);
  if (min == null && max == null) return null;
  final interval = '${c['interval'] ?? ''}'.toLowerCase();
  return Salary(
    min: min,
    max: max,
    currency: nonBlank(c['currencyCode'])?.toUpperCase(),
    per: interval.startsWith('1 ')
        ? [
            for (final p in PayPeriod.values)
              if (interval.endsWith(p.name)) p,
          ].firstOrNull
        : null,
  );
}
