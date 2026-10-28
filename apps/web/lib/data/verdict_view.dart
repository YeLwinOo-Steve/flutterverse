import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The `.verdict` modifier for a status.
String statusClass(DoctorStatus s) => switch (s) {
  DoctorStatus.replaceNow => 'replace',
  DoctorStatus.atRisk => 'risk',
  DoctorStatus.watch => 'watch',
  DoctorStatus.healthy => 'healthy',
  DoctorStatus.stable => 'stable',
  _ => 'none',
};

/// What each status means, in a sentence: the legend and the About page.
String statusMeaning(DoctorStatus s) => switch (s) {
  DoctorStatus.replaceNow => 'Discontinued on pub.dev, or its GitHub repo is archived.',
  DoctorStatus.atRisk => 'Low activity, and not finished enough to call Stable.',
  DoctorStatus.watch => 'Activity is slowing, and not finished enough to call Stable.',
  DoctorStatus.healthy => 'Committed to within 30 days and released within 120.',
  DoctorStatus.stable =>
    'Quiet, but finished: $stablePoints+ pub points, a release within 3 years, and downloads not falling.',
  DoctorStatus.notEnoughData => 'Tracked, but a date a rule needs is missing, so no verdict is given.',
  DoctorStatus.notTracked => 'Not among the packages Flutterverse tracks, so there’s nothing to judge it on.',
  DoctorStatus.notChecked => 'A git, path or private-registry dependency: only pub.dev packages are checked.',
};

/// The colored status pill.
Component statusPill(DoctorStatus s) => span(classes: 'verdict ${statusClass(s)}', [.text(s.label)]);

/// The pill for a [Verdict], as on a package page.
Component verdictPill(VerdictResult r) =>
    statusPill(r.verdict == null ? DoctorStatus.notEnoughData : DoctorStatus.of(r.verdict!));

/// `+ Rising`, for Healthy or Stable packages with a high momentum.
Component risingTag() => span(
  classes: 'rising-tag',
  attributes: {'title': 'High momentum: fast recent growth'},
  [.text('↑ Rising')],
);
