import '../json.dart';

/// How strongly a role is about Flutter. See `flutterMatch`.
enum JobMatch {
  /// Flutter or Dart is a whole word in the title.
  title,

  /// Flutter is a whole word in the description only.
  mentions;

  static JobMatch? parse(String? s) => s == null ? null : values.asNameMap()[s];
}

/// Where a role came from: a company's hiring system, or Hacker News.
enum JobSource {
  greenhouse('Greenhouse'),
  lever('Lever'),
  ashby('Ashby'),
  workable('Workable'),
  hn('Hacker News');

  const JobSource(this.label);

  final String label;

  static JobSource? parse(String? s) => s == null ? null : values.asNameMap()[s];
}

/// One open role in `jobs.json`.
///
/// Only link-out fields are kept: the description is read to find Flutter
/// and then dropped, and salary and recruiter details are never stored.
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.companyId,
    required this.url,
    required this.source,
    required this.match,
    required this.firstSeen,
    this.companyUrl,
    this.location,
    this.remote,
  });

  /// `<source>:<company id>:<posting id>`, stable from day to day.
  final String id;
  final String title;

  /// The company's display name.
  final String company;

  /// The company's id in `config/jobs.yaml` (`hn` for Hacker News rows).
  final String companyId;

  /// The company's own careers page, when known.
  final String? companyUrl;

  /// The posting, on the company's site or hiring system. Unchanged.
  final String url;

  /// Location as the feed wrote it; null when it gives none.
  final String? location;

  /// True only when the feed says the role is remote; null when it doesn't
  /// say. Never a default `false`.
  final bool? remote;

  final JobSource source;
  final JobMatch match;

  /// The UTC day (`YYYY-MM-DD`) the role first appeared.
  final String firstSeen;

  Job copyWith({String? firstSeen, String? location, bool? remote}) => Job(
    id: id,
    title: title,
    company: company,
    companyId: companyId,
    companyUrl: companyUrl,
    url: url,
    location: location ?? this.location,
    remote: remote ?? this.remote,
    source: source,
    match: match,
    firstSeen: firstSeen ?? this.firstSeen,
  );

  factory Job.fromJson(Json json) => Job(
    id: json['id'] as String,
    title: json['title'] as String,
    company: json['company'] as String,
    companyId: json['companyId'] as String,
    companyUrl: json['companyUrl'] as String?,
    url: json['url'] as String,
    location: json['location'] as String?,
    remote: json['remote'] as bool?,
    source: JobSource.parse(json['source'] as String?) ?? JobSource.greenhouse,
    match: JobMatch.parse(json['match'] as String?) ?? JobMatch.mentions,
    firstSeen: json['firstSeen'] as String,
  );

  Json toJson() => compact({
    'id': id,
    'title': title,
    'company': company,
    'companyId': companyId,
    'companyUrl': companyUrl,
    'url': url,
    'location': location,
    'remote': remote == true ? true : null,
    'source': source.name,
    'match': match.name,
    'firstSeen': firstSeen,
  });
}

/// The page order: title matches first, then newest first, then by title so
/// the order is stable.
int compareJobs(Job a, Job b) {
  final m = a.match.index.compareTo(b.match.index);
  if (m != 0) return m;
  final d = b.firstSeen.compareTo(a.firstSeen);
  if (d != 0) return d;
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

/// `jobs.json`: open Flutter roles, refreshed daily by `fv_ingest:jobs`.
class JobsFile {
  const JobsFile({this.generatedAt, this.companies = 0, this.failed = const [], this.jobs = const []});

  final DateTime? generatedAt;

  /// How many distinct companies have a role in [jobs].
  final int companies;

  /// Ids of companies whose fetch failed on this run.
  final List<String> failed;

  /// Sorted by [compareJobs].
  final List<Job> jobs;

  factory JobsFile.fromJson(Json json) => JobsFile(
    generatedAt: asDate(json['generatedAt']),
    companies: asInt(json['companies']) ?? 0,
    failed: asStrings(json['failed']),
    jobs: asList(json['jobs'], Job.fromJson),
  );

  Json toJson() => compact({
    'generatedAt': isoDate(generatedAt),
    'companies': companies,
    'failed': failed.isEmpty ? null : failed,
    'jobs': [for (final j in jobs) j.toJson()],
  });
}
