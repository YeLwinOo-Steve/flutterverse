/// How actively a project is maintained, from its last commit and release.
enum Maintenance {
  active('Active'),
  slowing('Slowing'),
  low('Low activity');

  const Maintenance(this.label);
  final String label;

  static Maintenance? parse(String? s) => s == null ? null : Maintenance.values.byName(s);
}

/// Classifies maintenance from days since the last commit and last release.
///
/// - [Maintenance.active]: committed within 30 days and released within 120.
/// - [Maintenance.slowing]: any activity within 120 days.
/// - [Maintenance.low]: neither.
///
/// When there's no commit date (e.g. a package in a shared monorepo), the
/// release date stands in for it. Null when both are unknown.
Maintenance? maintenance({DateTime? lastCommit, DateTime? lastRelease, required DateTime now}) {
  int? days(DateTime? t) => t == null ? null : now.difference(t).inDays;
  final release = days(lastRelease);
  final activity = days(lastCommit) ?? release;
  if (activity == null) return null;
  if (activity <= 30 && (release ?? 0) <= 120) return Maintenance.active;
  if (activity <= 120) return Maintenance.slowing;
  return Maintenance.low;
}
