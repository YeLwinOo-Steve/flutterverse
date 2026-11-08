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
/// Flutter outside the title, and `pay_transparency=true` the posted pay
/// ranges. Greenhouse has no remote flag, so a location that says "Remote"
/// is taken as the feed saying so.
class GreenhouseBoard implements JobBoard {
  GreenhouseBoard(this._client);

  final http.Client _client;

  @override
  Future<List<Posting>> fetch(JobCompany company) async {
    final url = Uri.https('boards-api.greenhouse.io', '/v1/boards/${company.token}/jobs', {
      'content': 'true',
      'pay_transparency': 'true',
    });
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
            salary: greenhousePay(j['pay_input_ranges']),
          ),
    ];
  }
}

final _hourly = RegExp(r'\bhour', caseSensitive: false);
final _monthly = RegExp(r'\bmonth', caseSensitive: false);
final _yearly = RegExp(r'\b(year|annual|salary)', caseSensitive: false);

/// The first of Greenhouse's `pay_input_ranges` (`min_cents`, `max_cents`,
/// `currency_type`, `title`). It has no period field, so the period comes
/// from the range's title ("Hourly Range", "Annual Salary"), or none.
Salary? greenhousePay(Object? ranges) {
  if (ranges is! List || ranges.isEmpty || ranges.first is! Json) return null;
  final r = ranges.first as Json;
  int? whole(Object? cents) => cents is num && cents > 0 ? (cents / 100).round() : null;
  final min = whole(r['min_cents']);
  final max = whole(r['max_cents']);
  if (min == null && max == null) return null;
  final title = '${r['title'] ?? ''} ${r['blurb'] ?? ''}';
  return Salary(
    min: min,
    max: max,
    currency: nonBlank(r['currency_type'])?.toUpperCase(),
    per: _hourly.hasMatch(title)
        ? PayPeriod.hour
        : _monthly.hasMatch(title)
        ? PayPeriod.month
        : _yearly.hasMatch(title)
        ? PayPeriod.year
        : null,
  );
}
