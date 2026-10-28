import '../json.dart';

/// `discontinued.json`: packages pub.dev marks discontinued, whether or not
/// they're tracked, so Doctor can warn about them instead of calling them
/// "Not tracked". Kept out of `index.json`, which stays slim.
class DiscontinuedFile {
  const DiscontinuedFile({this.packages = const {}});

  /// Package name → the package pub.dev suggests instead, if any.
  final Map<String, String?> packages;

  bool contains(String name) => packages.containsKey(name);

  factory DiscontinuedFile.fromJson(Json json) => DiscontinuedFile(
    packages: {for (final e in (json['packages'] as Json? ?? const {}).entries) e.key: e.value as String?},
  );

  // Null values stay: a discontinued package without a replacement is still
  // discontinued.
  Json toJson() => {'packages': packages};
}
