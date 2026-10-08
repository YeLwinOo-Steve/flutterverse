import 'dart:async';
import 'dart:convert';

import 'package:fv_core/fv_core.dart';
import 'package:http/http.dart' as http;

/// Client-side access to the static JSON, cached in memory so moving
/// between widgets never downloads a file twice.
abstract final class DataRepo {
  static final _cache = <String, Future<Map<String, Object?>>>{};

  static Future<Map<String, Object?>> _get(String path) => _cache.putIfAbsent(path, () async {
    final res = await http.get(Uri.base.resolve('/data/$path'));
    if (res.statusCode != 200) {
      unawaited(_cache.remove(path)); // Let the next call retry.
      throw http.ClientException('HTTP ${res.statusCode}', res.request?.url);
    }
    return jsonDecode(res.body) as Map<String, Object?>;
  });

  static Future<IndexFile> index() async => IndexFile.fromJson(await _get('index.json'));
}
