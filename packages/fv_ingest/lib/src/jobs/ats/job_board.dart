import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

import '../../http_util.dart';
import '../jobs_config.dart';
import '../posting.dart';
import 'ashby.dart';
import 'greenhouse.dart';
import 'lever.dart';

/// Reads one company's open roles from its hiring system.
abstract interface class JobBoard {
  /// Throws [JobFeedException] (or a network error) when the feed fails.
  Future<List<Posting>> fetch(JobCompany company);
}

/// The [JobBoard] for each supported system, sharing one HTTP client.
Map<JobSource, JobBoard> defaultJobBoards(http.Client client) => {
  JobSource.greenhouse: GreenhouseBoard(client),
  JobSource.lever: LeverBoard(client),
  JobSource.ashby: AshbyBoard(client),
};

/// GETs [url] through [withRetry] and decodes the JSON body. Throws
/// [JobFeedException] on a non-200 answer.
Future<Object?> getJson(http.Client client, Uri url) async {
  final res = await withRetry(() => client.get(url, headers: {'accept': 'application/json'}));
  if (res.statusCode != 200) throw JobFeedException('${url.host}: HTTP ${res.statusCode}');
  return jsonDecode(utf8.decode(res.bodyBytes));
}
