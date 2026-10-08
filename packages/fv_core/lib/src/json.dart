/// Bump when the shape of the generated JSON files changes.
const schemaVersion = 2;

typedef Json = Map<String, Object?>;

int? asInt(Object? v) => (v as num?)?.toInt();

double? asDouble(Object? v) => (v as num?)?.toDouble();

DateTime? asDate(Object? v) => v == null ? null : DateTime.parse(v as String);

List<String> asStrings(Object? v) => [for (final e in (v as List<Object?>? ?? const [])) e as String];

List<T> asList<T>(Object? v, T Function(Json) fromJson) => [
  for (final e in (v as List<Object?>? ?? const [])) fromJson(e as Json),
];

/// Drops null values so the generated files stay small.
Json compact(Json json) => {
  for (final e in json.entries)
    if (e.value != null) e.key: e.value,
};

/// Like [asList] but null when the value is absent, so "unknown" stays
/// distinguishable from "empty".
List<T>? asListOrNull<T>(Object? v, T Function(Json) fromJson) => v == null ? null : asList(v, fromJson);

List<int>? asIntsOrNull(Object? v) => v == null ? null : [for (final e in v as List<Object?>) asInt(e)!];

String? isoDate(DateTime? t) => t?.toUtc().toIso8601String();
