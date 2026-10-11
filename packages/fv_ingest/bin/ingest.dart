import 'dart:io';

import 'package:args/args.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('seeds', defaultsTo: 'config/seeds.yaml', help: 'Curated seeds file.')
    ..addOption('roadmap', defaultsTo: 'config/roadmap.json', help: 'Learning roadmap content.')
    ..addOption('out', defaultsTo: 'apps/web/web/data', help: 'Where to write the JSON the site serves.')
    ..addOption('history', defaultsTo: '.history', help: 'Where the per-project NDJSON history lives.')
    ..addOption(
      'activity',
      defaultsTo: '.history/activity.json',
      help: 'Where commit activity is kept between runs.',
    )
    ..addOption('activity-budget', defaultsTo: '600', help: 'Max commit activity REST calls per run.')
    ..addOption('concurrency', defaultsTo: '4', help: 'Max parallel pub.dev requests.')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults opts;
  try {
    opts = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(64);
  }
  if (opts.flag('help')) {
    stdout.writeln('Usage: dart run fv_ingest:ingest [options]\n\n${parser.usage}');
    return;
  }

  final seedsFile = File(opts.option('seeds')!);
  if (!seedsFile.existsSync()) {
    stderr.writeln('Seeds file not found: ${seedsFile.path} (run from the repo root or pass --seeds)');
    exit(66);
  }
  final roadmapFile = File(opts.option('roadmap')!);
  final catalog = parseSeeds(
    seedsFile.readAsStringSync(),
    roadmapJson: roadmapFile.existsSync() ? roadmapFile.readAsStringSync() : null,
  );
  final problems = validateCatalog(catalog);
  if (problems.isNotEmpty) {
    stderr.writeln('seeds.yaml is invalid:\n${problems.map((p) => '  - $p').join('\n')}');
    exit(65);
  }

  final client = http.Client();
  final token = Platform.environment['GITHUB_TOKEN'];
  try {
    final result = await runIngest(
      catalog: catalog,
      pub: PubDevClient(client),
      github: token == null || token.isEmpty ? null : GithubClient(client, token: token),
      history: HistoryStore(opts.option('history')!),
      writer: JsonWriter(opts.option('out')!),
      now: DateTime.now().toUtc(),
      activity: ActivityStore(opts.option('activity')!),
      activityBudget: int.parse(opts.option('activity-budget')!),
      concurrency: int.parse(opts.option('concurrency')!),
      log: stdout.writeln,
    );
    stdout.writeln(
      result.written
          ? 'Wrote ${result.projects} projects to ${opts.option('out')} (${result.warnings.length} warnings)'
          : 'Nothing written.',
    );
    if (!result.written) exitCode = 1;
  } finally {
    client.close();
  }
}
