import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Sends [request] (re-created per attempt), retrying 429/5xx, GitHub's
/// secondary rate limit (a 403) and network errors with exponential backoff.
/// Honors `Retry-After` when present.
Future<http.Response> withRetry(
  Future<http.Response> Function() request, {
  int attempts = 4,
  Duration baseDelay = const Duration(seconds: 2),
}) async {
  for (var attempt = 1; ; attempt++) {
    try {
      final res = await request();
      final retryable = res.statusCode == 429 || res.statusCode >= 500 || _secondaryLimit(res);
      if (!retryable || attempt >= attempts) return res;
      await Future<void>.delayed(_delay(res, attempt, baseDelay));
    } on Object catch (e) {
      if (e is! SocketException && e is! http.ClientException && e is! TimeoutException) rethrow;
      if (attempt >= attempts) rethrow;
      await Future<void>.delayed(_delay(null, attempt, baseDelay));
    }
  }
}

bool _secondaryLimit(http.Response res) => res.statusCode == 403 && res.body.contains('secondary rate limit');

Duration _delay(http.Response? res, int attempt, Duration base) {
  final retryAfter = int.tryParse(res?.headers['retry-after'] ?? '');
  if (retryAfter != null) return Duration(seconds: math.min(retryAfter, 120));
  // GitHub asks for at least a minute before retrying a secondary limit.
  if (res != null && _secondaryLimit(res) && base > Duration.zero) return const Duration(seconds: 60) * attempt;
  return base * math.pow(2, attempt - 1).toInt();
}

/// Runs [fn] over [items] with at most [concurrency] calls in flight,
/// returning results in input order.
Future<List<R>> mapPool<T, R>(Iterable<T> items, int concurrency, Future<R> Function(T) fn) async {
  final list = items.toList();
  final results = List<R?>.filled(list.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < list.length) {
      final i = next++;
      results[i] = await fn(list[i]);
    }
  }

  await Future.wait([for (var w = 0; w < math.min(concurrency, list.length); w++) worker()]);
  return results.cast<R>();
}
