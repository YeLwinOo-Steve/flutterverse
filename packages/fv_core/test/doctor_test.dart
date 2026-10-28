import 'package:fv_core/fv_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseDependencies: pubspec.yaml', () {
    const pubspec = '''
name: my_app
environment:
  sdk: ^3.6.0
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  dio:
  internal:
    git: https://github.com/me/internal
  local:
    path: ../local
  private:
    hosted: https://my.registry.dev
    version: ^1.0.0
  mirrored:
    hosted:
      url: https://pub.dev
dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^5.0.0
  http: ^1.2.0
''';

    test('reads direct and dev dependencies, skipping the SDK', () {
      final p = parseDependencies(pubspec);
      expect(p.format, InputFormat.pubspec);
      expect(p.project, 'my_app');
      expect(p.dependencies, [
        const Dependency('http'),
        const Dependency('dio'),
        const Dependency('internal', source: DependencySource.git),
        const Dependency('local', source: DependencySource.path),
        const Dependency('private', source: DependencySource.custom),
        const Dependency('mirrored'),
        const Dependency('lints', kind: DependencyKind.dev),
      ]);
    });

    test('a bare dependencies block is enough', () {
      expect(parseDependencies('dependencies:\n  http: ^1.0.0\n').dependencies, [const Dependency('http')]);
    });

    test('broken YAML is reported with its line', () {
      expect(
        () => parseDependencies('dependencies:\n  http: ^1.0.0\n   dio: [\n'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('line'))),
      );
    });
  });

  group('parseDependencies: pubspec.lock', () {
    const lock = '''
packages:
  async:
    dependency: transitive
    description:
      name: async
      url: "https://pub.dev"
    source: hosted
    version: "2.11.0"
  http:
    dependency: "direct main"
    description:
      name: http
      url: "https://pub.dev"
    source: hosted
    version: "1.2.0"
  lints:
    dependency: "direct dev"
    description:
      name: lints
      url: "https://pub.dev"
    source: hosted
    version: "5.0.0"
  private:
    dependency: "direct main"
    description:
      name: private
      url: "https://my.registry.dev"
    source: hosted
    version: "1.0.0"
  internal:
    dependency: "direct main"
    description:
      path: "."
      ref: main
      url: "https://github.com/me/internal"
    source: git
    version: "0.1.0"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.99"
sdks:
  dart: ">=3.6.0 <4.0.0"
''';

    test('reads kind and source for every package', () {
      final p = parseDependencies(lock);
      expect(p.format, InputFormat.lock);
      expect(p.dependencies, [
        const Dependency('async', kind: DependencyKind.transitive),
        const Dependency('http'),
        const Dependency('lints', kind: DependencyKind.dev),
        const Dependency('private', source: DependencySource.custom),
        const Dependency('internal', source: DependencySource.git),
      ]);
    });
  });

  group('parseDependencies: package list', () {
    test('splits on spaces, commas and new lines', () {
      final p = parseDependencies('http, dio\nriverpod  get_it,,');
      expect(p.format, InputFormat.names);
      expect([for (final d in p.dependencies) d.name], ['http', 'dio', 'riverpod', 'get_it']);
    });

    test('understands pub add commands and version suffixes', () {
      final p = parseDependencies('flutter pub add http dev:mocktail\ndart pub add dio:^5.0.0\nprovider: ^6.0.0');
      expect([for (final d in p.dependencies) d.name], ['http', 'mocktail', 'dio', 'provider']);
      expect(p.ignored, isEmpty);
    });

    test('drops duplicates and SDK packages, and lists what it ignored', () {
      final p = parseDependencies('Http http flutter 9lives https://x.dev');
      expect([for (final d in p.dependencies) d.name], ['http']);
      expect(p.ignored, ['9lives', 'https://x.dev']);
    });

    test('empty text has no dependencies', () {
      expect(parseDependencies('  \n').dependencies, isEmpty);
    });
  });

  group('diagnose', () {
    final now = DateTime.utc(2026, 10, 6);
    ProjectRow row(
      String pub, {
      Maintenance? m = Maintenance.active,
      int? points = 150,
      List<String> categories = const ['networking'],
      int? momentum,
      bool archived = false,
    }) => ProjectRow(
      id: pub,
      name: pub,
      pub: pub,
      sdk: 'Dart',
      categories: categories,
      maintenance: m,
      points: points,
      maxPoints: 160,
      released: now.subtract(const Duration(days: 100)),
      downloadGrowth: 0,
      momentum: momentum,
      archived: archived,
    );

    final index = IndexFile(
      categories: const {},
      projects: [
        row('http'),
        row('old_http', m: Maintenance.low, points: 40),
        row('slow_http', m: Maintenance.slowing, points: 40),
        row('dio', momentum: 60),
        row('chopper', momentum: 70),
        row('retrofit', momentum: 50),
        row('bad_net', m: Maintenance.low, points: 40, momentum: 99),
        row('unknown_dates', m: null),
        row('ui_kit', categories: const ['ui']),
        row('dead', archived: true),
      ],
    );
    const discontinued = DiscontinuedFile(packages: {'pedantic': 'lints', 'js': null});

    DoctorReport run(String text) => diagnose(parseDependencies(text), index, discontinued: discontinued, now: now);

    test('every dependency gets a status, most urgent first', () {
      final r = run('http old_http pedantic slow_http unknown_dates nope');
      expect(
        [for (final e in r.entries) (e.name, e.status)],
        [
          ('pedantic', DoctorStatus.replaceNow),
          ('old_http', DoctorStatus.atRisk),
          ('slow_http', DoctorStatus.watch),
          ('http', DoctorStatus.healthy),
          ('unknown_dates', DoctorStatus.notEnoughData),
          ('nope', DoctorStatus.notTracked),
        ],
      );
    });

    test('non-pub.dev dependencies are not checked', () {
      final r = run('dependencies:\n  http:\n  mine:\n    path: ../mine\n');
      expect(r.entries.last.status, DoctorStatus.notChecked);
    });

    test('the score counts judged direct dependencies only', () {
      final r = run('http dio old_http nope js');
      // http, dio good; old_http, js bad; nope left out.
      expect(r.score, 50);
      expect(r.counts[DoctorStatus.notTracked], 1);
      expect(run('nope also_nope').score, isNull);
    });

    test('transitive dependencies are listed but not scored', () {
      const lock = '''
packages:
  http: {dependency: "direct main", source: hosted, description: {name: http, url: "https://pub.dev"}}
  old_http: {dependency: transitive, source: hosted, description: {name: old_http, url: "https://pub.dev"}}
''';
      final r = run(lock);
      expect(r.score, 100);
      expect([for (final e in r.transitive) e.name], ['old_http']);
    });

    test('alternatives: replacedBy first, then good packages in the same category by momentum', () {
      final r = run('old_http dio pedantic');
      final old = r.entries.firstWhere((e) => e.name == 'old_http');
      // dio is already in use, bad_net is At risk, ui_kit is another category.
      expect([for (final a in old.alternatives) a.name], ['chopper', 'retrofit']);
      final ped = r.entries.firstWhere((e) => e.name == 'pedantic');
      expect(ped.alternatives.single.name, 'lints');
      expect(ped.alternatives.single.suggestedByPub, isTrue);
      expect(r.entries.firstWhere((e) => e.name == 'dio').alternatives, isEmpty);
    });
  });

  group('DiscontinuedFile', () {
    test('round-trips, keeping packages without a replacement', () {
      const f = DiscontinuedFile(packages: {'pedantic': 'lints', 'js': null});
      final back = DiscontinuedFile.fromJson(f.toJson());
      expect(back.packages, f.packages);
      expect(back.contains('js'), isTrue);
    });
  });
}
