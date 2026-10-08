import 'package:fv_core/fv_core.dart';

/// Brand-palette fallbacks for project logos without an avatar.
const _logoColors = ['#0468D7', '#02569B', '#042B59', '#0175C2', '#1B4F8A', '#0B7FAB', '#2D5C9E'];

/// The design's string hash, so logo colors match it exactly.
int designHash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) % 2147483647;
  }
  return h == 0 ? 1 : h;
}

/// Display helpers shared by every surface that shows a project.
extension ProjectView on ProjectRow {
  /// Two letters for the logo fallback: `flutter_bloc` → `FL`.
  String get initials => initialsOf(id);

  String get logoColor => logoColorOf(id);

  /// The owner's GitHub avatar, or null to show [initials].
  String? get avatarUrl => repo == null ? null : 'https://github.com/${repo!.split('/').first}.png?size=96';

  String get kindPlural => kind == ProjectKind.package ? 'packages' : 'projects';

  String get path => '/p/$id';

  /// The CSS modifier for the maintenance pill.
  String get healthClass => this.maintenance?.name ?? 'unknown';

  String get healthLabel => '● ${this.maintenance?.label ?? notAvailable}';

  /// `MOM 72` or `MOM N/A`.
  String get momentumLabel => 'MOM ${momentum ?? notAvailable}';
}

String initialsOf(String id) {
  final letters = id.replaceAll(RegExp('[^a-zA-Z]'), '');
  return (letters.length >= 2 ? letters.substring(0, 2) : letters).toUpperCase();
}

String logoColorOf(String id) => _logoColors[designHash(id) % _logoColors.length];

/// Category slug → label, falling back to the slug.
String categoryLabel(Map<String, String> categories, String slug) => categories[slug] ?? slug;
