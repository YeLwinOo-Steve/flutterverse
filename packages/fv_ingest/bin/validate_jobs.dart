import 'dart:io';

import 'package:args/args.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;

/// Validates `config/jobs.yaml`. With `--remote`, also checks that every
/// company's feed answers (used as a PR check, like `validate_seeds`).
Future<void> main(List<String> args) async {
  final opts =
      (ArgParser()
            ..addOption('config', defaultsTo: 'config/jobs.yaml')
            ..addFlag('remote', help: "Also fetch each company's feed."))
          .parse(args);

  final List<JobCompany> companies;
  try {
    companies = parseJobsConfig(File(opts.option('config')!).readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('jobs.yaml is malformed: ${e.message}');
    exit(1);
  }
  final problems = validateJobsConfig(companies);

  if (opts.flag('remote') && problems.isEmpty) {
    final client = PoliteClient(http.Client());
    try {
      final boards = defaultJobBoards(client);
      await mapPool(companies, 4, (c) async {
        try {
          await boards[c.ats]!.fetch(c);
        } on Object catch (e) {
          problems.add('company "${c.id}": ${c.atsName} feed for "${c.token}" failed: $e');
        }
      });
    } finally {
      client.close();
    }
  }

  if (problems.isEmpty) {
    stdout.writeln('jobs.yaml OK: ${companies.length} companies');
  } else {
    stderr.writeln('jobs.yaml has ${problems.length} problem(s):\n${problems.map((p) => '  - $p').join('\n')}');
    exitCode = 1;
  }
}
