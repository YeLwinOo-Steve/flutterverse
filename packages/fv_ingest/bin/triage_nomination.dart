import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:fv_ingest/fv_ingest.dart';
import 'package:http/http.dart' as http;

/// Checks a newly opened nomination issue (see `.github/workflows/nominations.yml`).
///
/// Writes the bot's reply to `--comment-out` and `outcome=accept|duplicate|reject`
/// plus `label=…` to `$GITHUB_OUTPUT`; the workflow applies them. Lookup
/// failures exit non-zero and leave the issue untouched for a human.
Future<void> main(List<String> args) async {
  final opts =
      (ArgParser()
            ..addOption('event', defaultsTo: Platform.environment['GITHUB_EVENT_PATH'])
            ..addOption('repo', defaultsTo: Platform.environment['GITHUB_REPOSITORY'])
            ..addOption('seeds', defaultsTo: 'config/seeds.yaml')
            ..addOption('comment-out', defaultsTo: 'triage-comment.md'))
          .parse(args);
  final token = Platform.environment['GITHUB_TOKEN'];
  if (opts.option('event') == null || opts.option('repo') == null || token == null || token.isEmpty) {
    stderr.writeln('Needs --event, --repo and GITHUB_TOKEN (all set automatically in GitHub Actions).');
    exitCode = 64;
    return;
  }

  final event = jsonDecode(File(opts.option('event')!).readAsStringSync()) as Map<String, Object?>;
  final issue = event['issue'] as Map<String, Object?>;
  final number = (issue['number'] as num).toInt();
  final author = (issue['user'] as Map<String, Object?>)['login'] as String;
  final nomination = parseNomination(issue['body'] as String? ?? '');
  final catalog = parseSeeds(File(opts.option('seeds')!).readAsStringSync());

  final client = http.Client();
  final TriageResult result;
  try {
    final gh = GithubClient(client, token: token);
    final (authorAccount, open, developer, repo) = await (
      gh.account(author),
      gh.openNominations(opts.option('repo')!),
      nomination is DeveloperNomination ? gh.account(nomination.handle) : Future<GhAccount?>.value(),
      nomination is ProjectNomination ? gh.repoInfo(nomination.repo) : Future<GhRepoInfo?>.value(),
    ).wait;
    result = triageNomination(
      nomination,
      NominationFacts(
        number: number,
        author: author,
        authorCreatedAt: authorAccount?.createdAt,
        openNominations: open,
        developer: developer,
        repo: repo,
      ),
      catalog: catalog,
      now: DateTime.now().toUtc(),
    );
  } on Object catch (e) {
    stderr.writeln('Triage of #$number failed, leaving it for a human: $e');
    exitCode = 1;
    return;
  } finally {
    client.close();
  }

  File(opts.option('comment-out')!).writeAsStringSync(result.comment);
  final output = Platform.environment['GITHUB_OUTPUT'];
  final lines = 'outcome=${result.outcome.name}\nlabel=${result.outcome.label}\n';
  if (output != null) File(output).writeAsStringSync(lines, mode: FileMode.append);
  stdout.write('#$number: $lines');
}
