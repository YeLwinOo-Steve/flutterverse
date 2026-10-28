import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import 'source_panel.dart';

/// `flutter pub add <name>`, or `dart pub add` for a pure Dart package.
String installCommand(ProjectRow r) => '${r.sdk == 'Dart' ? 'dart' : 'flutter'} pub add ${r.pub}';

/// The pub.dev panel, or null for unpublished projects.
SourcePanel? pubPanel(ProjectDetail d, DateTime now) {
  final p = d.pub, r = d.row;
  if (p == null || r.pub == null) return null;
  return SourcePanel(
    title: 'pub.dev',
    subtitle: 'Published by ${p.publisher ?? notAvailable}',
    badge: span(classes: 'src-mark pub', []),
    cta: 'View on pub.dev',
    href: 'https://pub.dev/packages/${r.pub}',
    ctaIcon: span(classes: 'pub-favicon', []),
    install: installCommand(r),
    tiles: [
      (icon: Icons.heart, label: 'Likes', value: compactNumber(p.likes)),
      (icon: Icons.check, label: 'Pub points', value: '${p.points ?? notAvailable}/${p.maxPoints ?? 160}'),
      (icon: Icons.download, label: 'Downloads 30d', value: compactNumber(p.downloads)),
      (icon: Icons.tag, label: 'Version', value: p.version == null ? notAvailable : 'v${p.version}'),
    ],
    rows: [
      (icon: Icons.shield, label: 'Publisher', value: p.publisher ?? notAvailable),
      (icon: Icons.code, label: 'Dart SDK', value: p.dartSdk ?? notAvailable),
      (icon: Icons.box, label: 'Flutter SDK', value: p.flutterSdk ?? notApplicable),
      (icon: Icons.scale, label: 'License', value: d.gh?.license ?? p.license ?? notAvailable),
      (icon: Icons.clock, label: 'Last published', value: ago(p.published, now: now)),
    ],
  );
}

/// The GitHub panel; a note replaces the counters for shared monorepos.
SourcePanel? githubPanel(ProjectDetail d, DateTime now) {
  final r = d.row, g = d.gh;
  if (r.repo == null) return null;
  final badge = span(classes: 'src-mark gh', [const Icon(Icons.github, size: 18, filled: true)]);
  const ctaIcon = Icon(Icons.github, filled: true);
  if (r.sharedRepo || g == null) {
    return SourcePanel(
      title: 'GitHub',
      subtitle: r.repo!,
      badge: badge,
      cta: 'View on GitHub',
      href: 'https://github.com/${r.repo}',
      ctaIcon: ctaIcon,
      note: r.sharedRepo
          ? 'Lives in the ${r.repo} monorepo, shared with other packages, so its stars are the whole repo’s.'
          : 'GitHub data is unavailable right now.',
      rows: [
        (icon: Icons.star, label: r.repoWideStars ? 'Repo stars' : 'Stars', value: compactNumber(r.shownStars)),
        const (icon: Icons.issue, label: 'Open issues', value: notAvailable),
      ],
    );
  }
  return SourcePanel(
    title: 'GitHub',
    subtitle: r.repo!,
    badge: badge,
    cta: 'View on GitHub',
    href: 'https://github.com/${r.repo}',
    ctaIcon: ctaIcon,
    topics: g.topics,
    tiles: [
      (icon: Icons.star, label: 'Stars', value: compactNumber(g.stars)),
      (icon: Icons.fork, label: 'Forks', value: compactNumber(g.forks)),
      (icon: Icons.people, label: 'Contributors', value: compactNumber(g.contributors)),
      (icon: Icons.issue, label: 'Open issues', value: compactNumber(g.openIssues)),
    ],
    rows: [
      (icon: Icons.eye, label: 'Watchers', value: compactNumber(g.watchers)),
      (icon: Icons.pulse, label: 'Last commit', value: ago(g.lastCommit, now: now)),
      (icon: Icons.calendar, label: 'Repository age', value: age(g.createdAt, now: now)),
      (icon: Icons.scale, label: 'License', value: g.license ?? notAvailable),
      (icon: Icons.code, label: 'Languages', value: g.languages.isEmpty ? notAvailable : g.languages.join(' · ')),
      (icon: Icons.user, label: 'Owner', value: r.owner ?? notAvailable),
    ],
  );
}
