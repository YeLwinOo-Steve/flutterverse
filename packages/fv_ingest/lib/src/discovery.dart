import 'package:fv_core/fv_core.dart';

import 'seeds.dart';

/// The id of a project discovered on GitHub: `owner-name`, lowercased and
/// URL-safe. pub package names can't contain `-`, so it never collides with
/// a package's id.
String githubProjectId(String repo) => repo.toLowerCase().replaceAll('/', '-').replaceAll(RegExp('[^a-z0-9_-]'), '-');

/// The category for open source apps: packages never land in it, and
/// unpublished Flutter repos that match nothing else do.
const appCategory = 'open-source-app';

/// Up to [max] category slugs for a discovered project, in [topicCategories]
/// order, or [otherCategory] when none match. A keyword matches one of the
/// project's [topics], a word of its [name] (split on `_` and `-`), or its
/// [description]: as a phrase for hyphenated keywords (`state-management`
/// matches "state management"), as a word otherwise unless it's too vague
/// to mean much in prose.
List<String> categorize(
  Iterable<String> topics,
  Map<String, List<String>> topicCategories, {
  String name = '',
  String? description,
  bool published = false,
  String? sdk,
  int max = 3,
}) {
  final have = {for (final t in topics) t.toLowerCase()};
  final nameWords = name.toLowerCase().split(RegExp('[_-]+')).toSet();
  final prose = (description ?? '').toLowerCase().split(RegExp('[^a-z0-9]+')).where((w) => w.isNotEmpty).toList();
  final proseWords = prose.toSet();
  final proseText = ' ${prose.join(' ')} ';

  bool matches(String keyword) {
    if (have.contains(keyword)) return true;
    if (keyword.contains('-')) return proseText.contains(' ${keyword.replaceAll('-', ' ')} ');
    return nameWords.contains(keyword) || (!_vague.contains(keyword) && proseWords.contains(keyword));
  }

  final matched = [
    for (final MapEntry(key: category, value: keywords) in topicCategories.entries)
      if (!(published && category == appCategory) && keywords.any(matches)) category,
  ];
  if (matched.isNotEmpty) return matched.take(max).toList();
  if (!published && sdk == 'Flutter' && topicCategories.containsKey(appCategory)) return const [appCategory];
  return const [otherCategory];
}

/// Keywords that only count as topics or name words: in a description they
/// are too common to say what a project is about.
final _vague =
    ('app apps application ui api state map test tests tools tooling server color theme widget widgets '
            'components layout cache storage auth login build generator game games time date log string async '
            'stream events event config share background plugin image images media picker player env math '
            'extensions helpers collection utils 2d')
        .split(' ')
        .toSet();

/// `Flutter` when an unpublished repo mentions Flutter in its name, topics or
/// description, otherwise `Dart`.
String guessSdk(String repo, GhStats gh) {
  bool flutter(String? s) => s != null && s.toLowerCase().contains('flutter');
  return flutter(repo) || gh.topics.any(flutter) || flutter(gh.description) ? 'Flutter' : 'Dart';
}

/// A project for a pub package found through discovery. Its categories are
/// filled in from its topics once the package has been fetched.
Project discoveredPackage(String name) => Project(id: name, name: name, pub: name);

/// A project for a repo found through GitHub discovery.
Project discoveredRepo(String repo, GhStats gh, Map<String, List<String>> topicCategories) => Project(
  id: githubProjectId(repo),
  name: repo.split('/').last,
  kind: ProjectKind.project,
  repo: repo,
  sdk: guessSdk(repo, gh),
  categories: categorize(
    gh.topics,
    topicCategories,
    name: repo.split('/').last,
    description: gh.description,
    sdk: guessSdk(repo, gh),
  ),
);
