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

/// How often a [Salary] is paid.
enum PayPeriod {
  hour('hr'),
  day('day'),
  week('wk'),
  month('mo'),
  year('yr');

  const PayPeriod(this.short);

  /// `yr`, as in `$150K–$220K/yr`.
  final String short;

  static PayPeriod? parse(String? s) => s == null ? null : values.asNameMap()[s];
}

/// A role's pay as the posting states it: a range (either end may be
/// missing), or only that it is negotiable.
class Salary {
  const Salary({this.min, this.max, this.currency, this.per}) : negotiable = false;

  const Salary.negotiable() : min = null, max = null, currency = null, per = null, negotiable = true;

  /// Whole units of [currency], not cents.
  final int? min;
  final int? max;

  /// ISO 4217 code, `USD`; null when the posting doesn't say.
  final String? currency;

  /// Null when the posting doesn't say. Never guessed as yearly.
  final PayPeriod? per;

  /// The posting says pay is negotiable and gives no figure.
  final bool negotiable;

  factory Salary.fromJson(Json json) => json['negotiable'] == true
      ? const Salary.negotiable()
      : Salary(
          min: asInt(json['min']),
          max: asInt(json['max']),
          currency: json['currency'] as String?,
          per: PayPeriod.parse(json['per'] as String?),
        );

  Json toJson() =>
      negotiable ? {'negotiable': true} : compact({'min': min, 'max': max, 'currency': currency, 'per': per?.name});

  /// `$150K–$220K/yr`, `€3,500–€4,200/mo`, `CAD 35–38/hr`, `From £60K`,
  /// `Negotiable`.
  String get label {
    if (negotiable) return 'Negotiable';
    // A symbol goes on every figure, a code only on the first: `CAD 35–38`.
    final sym = _symbols[currency];
    final lead = sym ?? (currency == null ? '' : '$currency ');
    String first(int n) => '$lead${_amount(n)}';
    String second(int n) => '${sym ?? ''}${_amount(n)}';
    final range = switch ((min, max)) {
      (final lo?, final hi?) when lo == hi => first(lo),
      (final lo?, final hi?) => '${first(lo)}–${second(hi)}',
      (final lo?, null) => 'From ${first(lo)}',
      (null, final hi?) => 'Up to ${first(hi)}',
      (null, null) => '',
    };
    return '$range${per == null ? '' : '/${per!.short}'}';
  }

  @override
  bool operator ==(Object other) =>
      other is Salary &&
      other.min == min &&
      other.max == max &&
      other.currency == currency &&
      other.per == per &&
      other.negotiable == negotiable;

  @override
  int get hashCode => Object.hash(min, max, currency, per, negotiable);

  @override
  String toString() => 'Salary($label)';
}

const _symbols = {'USD': r'$', 'EUR': '€', 'GBP': '£', 'INR': '₹', 'JPY': '¥'};

/// `150000` → `150K`, `62500` → `62.5K`, `1200000` → `1.2M`, `3500` →
/// `3,500` (monthly pay reads better whole), `38` → `38`.
String _amount(int n) {
  String trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  if (n >= 1000000) return '${trim(n / 1000000)}M';
  if (n >= 10000) return '${trim(n / 1000)}K';
  return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');
}

/// One open role in `jobs.json`.
///
/// Only link-out fields and the stated pay are kept: the description is
/// read to find Flutter and pay, then dropped. Recruiter details are never
/// stored.
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
    this.salary,
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

  /// Pay as the posting states it; null when it states none.
  final Salary? salary;

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
    salary: salary,
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
    salary: switch (json['salary']) {
      final Json s => Salary.fromJson(s),
      _ => null,
    },
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
    'salary': salary?.toJson(),
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
