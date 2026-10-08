import 'dart:io';

import 'package:args/args.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;

/// Validates `config/seeds.yaml`. With `--remote`, also checks that every pub
/// package exists and every GitHub repo resolves (used as a PR check).
Future<void> main(List<String> args) async {
  final opts =
      (ArgParser()
            ..addOption('seeds', defaultsTo: 'config/seeds.yaml')
            ..addOption('roadmap', defaultsTo: 'config/roadmap.json')
            ..addFlag('remote', help: 'Also check pub.dev and GitHub.'))
          .parse(args);

  final roadmap = File(opts.option('roadmap')!);
  final catalog = parseSeeds(
    File(opts.option('seeds')!).readAsStringSync(),
    roadmapJson: roadmap.existsSync() ? roadmap.readAsStringSync() : null,
  );
  final problems = validateCatalog(catalog);

  if (opts.flag('remote') && problems.isEmpty) {
    final client = http.Client();
    try {
      final pub = PubDevClient(client);
      await mapPool(catalog.projects.where((p) => p.pub != null), 4, (p) async {
        if (await pub.fetch(p.pub!, now: DateTime.now().toUtc()) == null) {
          problems.add('project "${p.id}": pub package "${p.pub}" not found');
        }
      });
      final token = Platform.environment['GITHUB_TOKEN'];
      final repos = {for (final p in catalog.projects) ?p.repo};
      if (token == null || token.isEmpty) {
        stdout.writeln('GITHUB_TOKEN not set; skipping repo checks');
      } else if (repos.isNotEmpty) {
        final found = await GithubClient(client, token: token).fetchAll(repos);
        for (final r in repos.difference(found.keys.toSet())) {
          problems.add('repo "$r" does not resolve on GitHub');
        }
      }
    } finally {
      client.close();
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('seeds.yaml OK: ${catalog.projects.length} projects, ${catalog.categories.length} categories');
  } else {
    stderr.writeln('seeds.yaml has ${problems.length} problem(s):\n${problems.map((p) => '  - $p').join('\n')}');
    exitCode = 1;
  }
}
