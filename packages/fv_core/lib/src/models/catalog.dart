import '../json.dart';
import 'project.dart';
import 'roadmap.dart';

/// Everything hand-curated in `config/seeds.yaml` and `config/roadmap.json`.
class Catalog {
  const Catalog({
    required this.categories,
    required this.projects,
    this.categoryGroups = const {},
    this.hallOfFame,
    this.roadmap = const {},
  });

  /// Category slug → display label.
  final Map<String, String> categories;

  /// Explore-page group name → category slugs.
  final Map<String, List<String>> categoryGroups;
  final List<Project> projects;
  final HallOfFameEdition? hallOfFame;

  /// Track id (`flutter`, `dart`) → track.
  final Map<String, RoadmapTrack> roadmap;
}

/// One yearly Hall of Fame edition.
class HallOfFameEdition {
  const HallOfFameEdition({required this.year, this.projects = const [], this.developers = const []});

  final int year;
  final List<HallOfFameProject> projects;
  final List<HallOfFameDeveloper> developers;

  factory HallOfFameEdition.fromJson(Json json) => HallOfFameEdition(
    year: asInt(json['year'])!,
    projects: asList(json['projects'], HallOfFameProject.fromJson),
    developers: asList(json['developers'], HallOfFameDeveloper.fromJson),
  );

  Json toJson() => {
    'year': year,
    'projects': [for (final p in projects) p.toJson()],
    'developers': [for (final d in developers) d.toJson()],
  };
}

class HallOfFameProject {
  const HallOfFameProject({required this.id, required this.category, required this.reason});

  /// A [Project.id].
  final String id;

  /// The award, e.g. `Most Influential`.
  final String category;
  final String reason;

  factory HallOfFameProject.fromJson(Json json) => HallOfFameProject(
    id: json['id'] as String,
    category: json['category'] as String,
    reason: json['reason'] as String,
  );

  Json toJson() => {'id': id, 'category': category, 'reason': reason};
}

class HallOfFameDeveloper {
  const HallOfFameDeveloper({
    required this.handle,
    required this.name,
    required this.category,
    required this.tagline,
    this.projects = const [],
    this.followers,
    this.repos,
  });

  /// GitHub login.
  final String handle;
  final String name;
  final String category;
  final String tagline;

  /// [Project.id]s they're known for.
  final List<String> projects;

  /// Filled in by ingest from GitHub; null when unavailable.
  final int? followers;
  final int? repos;

  HallOfFameDeveloper withStats({int? followers, int? repos}) => HallOfFameDeveloper(
    handle: handle,
    name: name,
    category: category,
    tagline: tagline,
    projects: projects,
    followers: followers,
    repos: repos,
  );

  factory HallOfFameDeveloper.fromJson(Json json) => HallOfFameDeveloper(
    handle: json['handle'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    tagline: json['tagline'] as String,
    projects: asStrings(json['projects']),
    followers: asInt(json['followers']),
    repos: asInt(json['repos']),
  );

  Json toJson() => compact({
    'handle': handle,
    'name': name,
    'category': category,
    'tagline': tagline,
    'projects': projects,
    'followers': followers,
    'repos': repos,
  });
}
