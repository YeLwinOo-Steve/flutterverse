import 'package:fv_core/fv_core.dart';

import '../../components/layout/site_header.dart' show sourceUrl;
import '../../data/fold.dart';

/// What the Jobs filters are set to.
typedef JobsQuery = ({bool remoteOnly, bool titleOnly, String text});

const emptyJobsQuery = (remoteOnly: false, titleOnly: false, text: '');

/// The text a role matches on: its title, company and location, folded.
String jobSearchText(Job j) => foldForSearch([j.title, j.company, ?j.location].join(' '));

/// The roles that pass [q], in [compareJobs] order. Every word of the search
/// text has to appear, in any order, so "senior remote berlin" works.
List<Job> filterJobs(List<Job> jobs, JobsQuery q) {
  final words = foldForSearch(q.text).split(' ').where((w) => w.isNotEmpty).toList();
  return [
    for (final j in jobs)
      if ((!q.remoteOnly || j.remote == true) &&
          (!q.titleOnly || j.match == JobMatch.title) &&
          (words.isEmpty || words.every(jobSearchText(j).contains)))
        j,
  ]..sort(compareJobs);
}

/// A link to the "Report or remove a job" issue form
/// (`.github/ISSUE_TEMPLATE/jobs-remove.yml`) with this role's company, title,
/// link and location already filled in. GitHub fills form fields from query
/// parameters named after their `id`.
String jobReportUrl(Job j) {
  final repo = Uri.parse(sourceUrl);
  return repo
      .replace(
        path: '${repo.path}/issues/new',
        queryParameters: {
          'template': 'jobs-remove.yml',
          'title': 'Jobs: remove "${j.title}" at ${j.company}',
          'company': j.company,
          'job-title': j.title,
          'job-link': j.url,
          'location': ?j.location,
        },
      )
      .toString();
}
