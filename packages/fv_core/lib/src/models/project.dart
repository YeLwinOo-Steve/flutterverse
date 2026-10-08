import '../json.dart';

/// Whether a tracked entry is a published library or a standalone project
/// (an app, a tool, a framework repository).
enum ProjectKind {
  package,
  project;

  static ProjectKind parse(String? s) => s == 'project' ? project : package;
}

/// A tracked project, as curated in `config/seeds.yaml`.
class Project {
  const Project({
    required this.id,
    required this.name,
    this.kind = ProjectKind.package,
    this.pub,
    this.repo,
    this.categories = const [],
    this.description,
    this.sdk,
    this.platforms,
    this.related = const [],
  });

  /// Stable, URL-safe identifier; the pub package name for packages.
  final String id;
  final String name;
  final ProjectKind kind;

  /// pub.dev package name, if the project is published.
  final String? pub;

  /// GitHub `owner/name`. Derived from the pubspec when not set.
  final String? repo;

  /// Category slugs (keys of the seeds' `categories` map).
  final List<String> categories;

  /// Editorial description; falls back to the pub.dev/GitHub one.
  final String? description;

  /// `Dart` or `Flutter`; only set for unpublished projects.
  final String? sdk;

  /// Display platform names; only set for unpublished projects.
  final List<String>? platforms;

  /// Ids of projects commonly used together with this one.
  final List<String> related;

  /// The GitHub owner, which the site uses as the author.
  String? get owner => repo?.split('/').first;

  Project copyWith({String? repo}) => Project(
    id: id,
    name: name,
    kind: kind,
    pub: pub,
    repo: repo ?? this.repo,
    categories: categories,
    description: description,
    sdk: sdk,
    platforms: platforms,
    related: related,
  );

  factory Project.fromJson(Json json) => Project(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    kind: ProjectKind.parse(json['kind'] as String?),
    pub: json['pub'] as String?,
    repo: json['repo'] as String?,
    categories: asStrings(json['categories']),
    description: json['description'] as String?,
    sdk: json['sdk'] as String?,
    platforms: json['platforms'] == null ? null : asStrings(json['platforms']),
    related: asStrings(json['related']),
  );
}
