import 'package:yaml/yaml.dart';

/// What the user pasted into Pubspec Doctor.
enum InputFormat {
  pubspec('pubspec.yaml'),
  lock('pubspec.lock'),
  names('package list');

  const InputFormat(this.label);
  final String label;
}

/// How a dependency enters the project.
enum DependencyKind {
  direct('dependency'),
  dev('dev dependency'),
  transitive('transitive');

  const DependencyKind(this.label);
  final String label;
}

/// Where a dependency comes from. Only [hosted] (pub.dev) ones can be judged.
enum DependencySource {
  hosted('pub.dev'),
  git('git'),
  path('path'),
  custom('another registry');

  const DependencySource(this.label);
  final String label;
}

class Dependency {
  const Dependency(this.name, {this.kind = DependencyKind.direct, this.source = DependencySource.hosted});

  final String name;
  final DependencyKind kind;
  final DependencySource source;

  @override
  bool operator ==(Object other) =>
      other is Dependency && other.name == name && other.kind == kind && other.source == source;

  @override
  int get hashCode => Object.hash(name, kind, source);

  @override
  String toString() => 'Dependency($name, ${kind.name}, ${source.name})';
}

class ParsedDependencies {
  const ParsedDependencies({required this.format, required this.dependencies, this.project, this.ignored = const []});

  final InputFormat format;

  /// In the order pasted, without duplicates.
  final List<Dependency> dependencies;

  /// The pubspec's `name`, when there is one.
  final String? project;

  /// Words in a package list that can't be package names.
  final List<String> ignored;
}

/// SDK packages that ship with Flutter: never on pub.dev, so not worth a row.
const _sdkPackages = {'flutter', 'flutter_test', 'flutter_localizations', 'flutter_web_plugins', 'flutter_driver'};

final _packageName = RegExp(r'^[a-z][a-z0-9_]*$');
final _yamlKey = RegExp(r'^(dependencies|dev_dependencies|packages|name|environment)\s*:', multiLine: true);
final _version = RegExp(r'^(any|[\^<>=~]*\d+(\.\d+)*([-+][\w.]*)?)$');
final _addCommand = RegExp(r'^\s*(?:flutter|dart)\s+pub\s+add\s+', multiLine: true);

/// Reads a `pubspec.yaml`, a `pubspec.lock` or a plain list of package names
/// (split on spaces, commas and new lines; `flutter pub add` prefixes and
/// `:^1.2.0` version suffixes are dropped).
///
/// SDK dependencies are left out. Throws [FormatException] when the text
/// looks like YAML but can't be read as either file.
ParsedDependencies parseDependencies(String text) {
  if (_yamlKey.hasMatch(text)) {
    final Object? doc;
    try {
      doc = loadYaml(text);
    } on YamlException catch (e) {
      final line = e.span == null ? '' : ' on line ${e.span!.start.line + 1}';
      throw FormatException('This looks like YAML, but it has an error$line: ${e.message}');
    }
    if (doc is YamlMap) {
      if (doc['packages'] is YamlMap) return _lock(doc);
      if (doc.containsKey('dependencies') || doc.containsKey('dev_dependencies') || doc.containsKey('name')) {
        return _pubspec(doc);
      }
    }
    throw const FormatException('This looks like YAML, but it has no dependencies or packages section.');
  }
  return _names(text);
}

ParsedDependencies _pubspec(YamlMap doc) {
  final deps = <Dependency>[];
  final seen = <String>{};
  for (final (key, kind) in const [('dependencies', DependencyKind.direct), ('dev_dependencies', DependencyKind.dev)]) {
    final section = doc[key];
    if (section is! YamlMap) continue;
    for (final MapEntry(:key, :value) in section.entries) {
      final name = '$key';
      final source = _pubspecSource(value);
      if (source == null || _sdkPackages.contains(name) || !seen.add(name)) continue;
      deps.add(Dependency(name, kind: kind, source: source));
    }
  }
  final name = doc['name'];
  return ParsedDependencies(format: InputFormat.pubspec, dependencies: deps, project: name is String ? name : null);
}

/// Null for an SDK dependency.
DependencySource? _pubspecSource(Object? spec) {
  if (spec is! YamlMap) return DependencySource.hosted; // `^1.2.0`, `any` or empty.
  if (spec.containsKey('sdk')) return null;
  if (spec.containsKey('git')) return DependencySource.git;
  if (spec.containsKey('path')) return DependencySource.path;
  final hosted = spec['hosted'];
  final url = hosted is YamlMap ? hosted['url'] : hosted;
  return url is String && !_isPubDev(url) ? DependencySource.custom : DependencySource.hosted;
}

ParsedDependencies _lock(YamlMap doc) {
  final deps = <Dependency>[];
  for (final MapEntry(:key, :value) in (doc['packages'] as YamlMap).entries) {
    final name = '$key';
    if (value is! YamlMap || _sdkPackages.contains(name)) continue;
    final source = switch (value['source']) {
      'sdk' => null,
      'git' => DependencySource.git,
      'path' => DependencySource.path,
      'hosted' => _otherRegistry(value['description']) ? DependencySource.custom : DependencySource.hosted,
      _ => DependencySource.custom,
    };
    if (source == null) continue;
    final kind = switch (value['dependency']) {
      'direct main' || 'direct overridden' => DependencyKind.direct,
      'direct dev' => DependencyKind.dev,
      _ => DependencyKind.transitive,
    };
    deps.add(Dependency(name, kind: kind, source: source));
  }
  return ParsedDependencies(format: InputFormat.lock, dependencies: deps);
}

/// A lock entry's `description` names a registry other than pub.dev.
bool _otherRegistry(Object? description) =>
    description is YamlMap && description['url'] is String && !_isPubDev(description['url'] as String);

bool _isPubDev(String url) {
  final host = Uri.tryParse(url.trim())?.host;
  return host == 'pub.dev' || host == 'pub.dartlang.org';
}

ParsedDependencies _names(String text) {
  final deps = <Dependency>[];
  final ignored = <String>[];
  final seen = <String>{};
  for (var word in text.replaceAll(_addCommand, ' ').split(RegExp(r'[\s,;]+'))) {
    word = word.trim();
    if (word.isEmpty) continue;
    // `dev:mocktail` (flutter pub add) and `http:^1.2.0` or `http: ^1.2.0`.
    if (word.contains('://')) {
      ignored.add(word);
      continue;
    }
    if (word.startsWith('dev:')) word = word.substring(4);
    final colon = word.indexOf(':');
    if (colon >= 0) word = word.substring(0, colon);
    if (word.isEmpty) continue; // A bare version after `name:`.
    final name = word.toLowerCase();
    if (!_packageName.hasMatch(name)) {
      if (!_version.hasMatch(word)) ignored.add(word);
      continue;
    }
    if (_sdkPackages.contains(name) || !seen.add(name)) continue;
    deps.add(Dependency(name));
  }
  return ParsedDependencies(format: InputFormat.names, dependencies: deps, ignored: ignored);
}
