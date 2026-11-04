import 'dart:io';

import 'package:args/args.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;

/// The daily jobs step: polls `config/jobs.yaml`'s companies, Workable's
/// official job feed and the Hacker News hiring thread, and writes
/// `jobs.json`. Separate from `ingest` so a
/// jobs failure never blocks the daily data commit.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('config', defaultsTo: 'config/jobs.yaml', help: 'The company list.')
    ..addOption('out', defaultsTo: 'apps/web/web/data', help: 'Where to write jobs.json.')
    ..addOption('state', defaultsTo: '.history/jobs.json', help: 'State kept between runs.')
    ..addOption('concurrency', defaultsTo: '4', help: 'Max parallel feed requests.')
    ..addFlag('hn', defaultsTo: true, help: 'Also read the Hacker News "Who is hiring?" thread.')
    ..addFlag('workable', defaultsTo: true, help: "Also read Workable's official job feed (about 670 MB).")
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults opts;
  try {
    opts = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(64);
  }
  if (opts.flag('help')) {
    stdout.writeln('Usage: dart run fv_ingest:jobs [options]\n\n${parser.usage}');
    return;
  }

  final configFile = File(opts.option('config')!);
  if (!configFile.existsSync()) {
    stderr.writeln('Jobs config not found: ${configFile.path} (run from the repo root or pass --config)');
    exit(66);
  }
  final List<JobCompany> companies;
  try {
    companies = parseJobsConfig(configFile.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('jobs.yaml is malformed: ${e.message}');
    exit(65);
  }
  final exclude = parseJobsExclude(configFile.readAsStringSync());
  final problems = validateJobsConfig(companies);
  if (problems.isNotEmpty) {
    stderr.writeln('jobs.yaml is invalid:\n${problems.map((p) => '  - $p').join('\n')}');
    exit(65);
  }

  final client = PoliteClient(http.Client());
  try {
    final result = await runJobs(
      companies: companies,
      boards: defaultJobBoards(client),
      hn: opts.flag('hn') ? HnHiring(client) : null,
      searches: [if (opts.flag('workable')) WorkableFeed(client, now: DateTime.now().toUtc())],
      exclude: exclude,
      store: JobsStore(opts.option('state')!),
      writer: JsonWriter(opts.option('out')!),
      now: DateTime.now().toUtc(),
      concurrency: int.parse(opts.option('concurrency')!),
      log: stdout.writeln,
    );
    stdout.writeln('Wrote ${result.jobs} jobs to ${opts.option('out')} (${result.warnings.length} warnings)');
  } finally {
    client.close();
  }
}
