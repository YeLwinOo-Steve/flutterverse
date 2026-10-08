import 'dart:io';

import 'package:fv_core/fv_core.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:test/test.dart';

const _yaml = '''
categories:
  networking: Networking
  state: State management
category_groups:
  Data: [networking]
projects:
  - { id: dio, pub: dio, categories: [networking], related: [bloc] }
  - { id: bloc, pub: flutter_bloc, repo: felangel/bloc, categories: [state] }
  - { id: app, kind: project, repo: me/app, sdk: Flutter, platforms: [iOS, Web], categories: [state] }
hall_of_fame:
  year: 2026
  projects:
    - { id: bloc, category: Most Influential, reason: Shaped architecture. }
  developers:
    - { handle: felangel, name: Felix, category: Most Influential, tagline: Bloc., projects: [bloc] }
''';

const _roadmap =
    '{"dart":{"name":"Dart","intro":"Hi","stages":[{"title":"Start","time":"1 week","blurb":"b",'
    '"build":"CLI","topics":[{"t":"Install","sub":["PATH"],"res":[["Docs","https://dart.dev"]],"pkg":"dio"}]}]}}';

void main() {
  test('parses every section', () {
    final c = parseSeeds(_yaml, roadmapJson: _roadmap);
    expect(c.categories.keys, ['networking', 'state']);
    expect(c.categoryGroups, {
      'Data': ['networking'],
    });
    expect(c.projects.map((p) => p.id), ['dio', 'bloc', 'app']);
    expect(c.projects.first.name, 'dio', reason: 'name defaults to the id');
    expect(c.projects.first.related, ['bloc']);
    expect(c.projects.last.kind, ProjectKind.project);
    expect(c.projects.last.platforms, ['iOS', 'Web']);
    expect(c.hallOfFame!.year, 2026);
    expect(c.hallOfFame!.developers.single.handle, 'felangel');
    final topic = c.roadmap['dart']!.stages.single.topics.single;
    expect(topic.resources.single, ('Docs', 'https://dart.dev'));
    expect(topic.project, 'dio');
    expect(validateCatalog(c), isEmpty);
  });

  test('reports semantic problems', () {
    final c = parseSeeds('''
categories: {state: State}
category_groups: {G: [ghost-cat]}
projects:
  - {id: Bad Id, pub: x, categories: [state]}
  - {id: dup, pub: a, categories: [nope], related: [missing]}
  - {id: dup, categories: [state]}
  - {id: r, repo: not-a-repo, categories: [], sdk: Kotlin, platforms: [Fuchsia]}
hall_of_fame:
  year: 2026
  projects: [{id: ghost, category: X, reason: Y}]
''');
    final errors = validateCatalog(c);
    for (final expected in [
      '"Bad Id": id must match',
      'unknown category "nope"',
      '"dup": duplicate id',
      'needs `pub`, `repo` or both',
      'repo must be "owner/name"',
      'needs at least one category',
      'sdk must be Dart or Flutter',
      'unknown platform "Fuchsia"',
      'unknown related project "missing"',
      'unknown category "ghost-cat"',
      'unknown project "ghost"',
    ]) {
      expect(errors, contains(contains(expected)));
    }
  });

  test('the real seeds keep full editorial text', () {
    final c = parseSeeds(File('../../config/seeds.yaml').readAsStringSync());
    expect(validateCatalog(c), isEmpty);
    for (final p in c.hallOfFame!.projects) {
      expect(p.reason, endsWith('.'), reason: 'reason for ${p.id} looks truncated — quote it in seeds.yaml');
    }
    for (final d in c.hallOfFame!.developers) {
      expect(d.tagline, endsWith('.'), reason: 'tagline for ${d.handle} looks truncated — quote it in seeds.yaml');
    }
  });
}
