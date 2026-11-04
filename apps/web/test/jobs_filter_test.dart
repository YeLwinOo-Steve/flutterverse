import 'package:fv_core/fv_core.dart';
import 'package:fv_web/pages/jobs/jobs_filter.dart';
import 'package:test/test.dart';

Job job(String id, String title, {bool? remote, JobMatch match = JobMatch.title, String? location}) => Job(
  id: id,
  title: title,
  company: 'Acme Café',
  companyId: 'acme',
  url: 'https://example.com/$id',
  source: JobSource.ashby,
  match: match,
  firstSeen: '2026-11-01',
  location: location,
  remote: remote,
);

void main() {
  final jobs = [
    job('a', 'Mobile Engineer', match: JobMatch.mentions, remote: true, location: 'Berlin'),
    job('b', 'Senior Flutter Engineer', location: 'Lagos'),
    job('c', 'Flutter Developer', remote: true),
  ];

  test('no filter keeps everything, title matches first', () {
    expect(filterJobs(jobs, emptyJobsQuery).map((j) => j.id), ['c', 'b', 'a']);
  });

  test('remote only keeps roles the feed calls remote', () {
    final q = (remoteOnly: true, titleOnly: false, text: '');
    expect(filterJobs(jobs, q).map((j) => j.id), ['c', 'a']);
  });

  test('title matches only drops mentions', () {
    final q = (remoteOnly: false, titleOnly: true, text: '');
    expect(filterJobs(jobs, q).map((j) => j.id), ['c', 'b']);
  });

  test('search needs every word, across title, company and location', () {
    expect(filterJobs(jobs, (remoteOnly: false, titleOnly: false, text: 'senior lagos')).single.id, 'b');
    expect(filterJobs(jobs, (remoteOnly: false, titleOnly: false, text: 'cafe berlin')).single.id, 'a');
    expect(filterJobs(jobs, (remoteOnly: false, titleOnly: false, text: 'rust')), isEmpty);
  });

  test('jobReportUrl fills the removal form from the role', () {
    final url = Uri.parse(jobReportUrl(jobs[1]));
    expect(url.path, '/YeLwinOo-Steve/flutterverse/issues/new');
    expect(url.queryParameters, {
      'template': 'jobs-remove.yml',
      'title': 'Jobs: remove "Senior Flutter Engineer" at Acme Café',
      'company': 'Acme Café',
      'job-title': 'Senior Flutter Engineer',
      'job-link': 'https://example.com/b',
      'location': 'Lagos',
    });
    expect(Uri.parse(jobReportUrl(jobs[2])).queryParameters.containsKey('location'), isFalse);
  });
}
