import 'dart:async';

import 'package:http/http.dart' as http;

/// Identifies the jobs step in every request's User-Agent, so a vendor can
/// see who is calling and where to reach the maintainers.
const jobsUserAgent = 'FlutterverseJobs/1.0 (+https://github.com/YeLwinOo-Steve/flutterverse)';

/// Hosts that state no rate limit, so they skip the per-host spacing. YC's
/// official HN API README: "There is currently no rate limit."
const unthrottledHosts = {'hacker-news.firebaseio.com'};

/// Wraps a client for the jobs step: sets [jobsUserAgent], and sends at most
/// one request per [spacing] to each host (Lever's robots.txt asks for
/// `Crawl-delay: 1`), however many companies are fetched in parallel.
class PoliteClient extends http.BaseClient {
  PoliteClient(this._inner, {this.spacing = const Duration(seconds: 1)});

  final http.Client _inner;
  final Duration spacing;
  final _nextSlot = <String, DateTime>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final host = request.url.host;
    if (!unthrottledHosts.contains(host) && spacing > Duration.zero) {
      // Reserve the host's next free slot before waiting, so parallel
      // callers queue one after another.
      final now = DateTime.now();
      final slot = switch (_nextSlot[host]) {
        final DateTime t when t.isAfter(now) => t,
        _ => now,
      };
      _nextSlot[host] = slot.add(spacing);
      final wait = slot.difference(now);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    request.headers['user-agent'] = jobsUserAgent;
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
