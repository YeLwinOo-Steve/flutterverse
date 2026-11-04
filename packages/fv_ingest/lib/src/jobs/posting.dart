/// An open role as a hiring system lists it, before matching. Lives only in
/// memory: [text] is read to find Flutter and then dropped.
class Posting {
  const Posting({
    required this.id,
    required this.title,
    required this.url,
    this.text,
    this.location,
    this.remote,
    this.company,
  });

  /// The system's own id for the posting.
  final String id;
  final String title;
  final String url;

  /// Plain-text description.
  final String? text;
  final String? location;

  /// True only when the feed says remote; null otherwise.
  final bool? remote;

  /// The company name, for sources that aren't per-company (Hacker News).
  final String? company;
}

/// A feed answered with something other than a usable list.
class JobFeedException implements Exception {
  const JobFeedException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _entities = {'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' '};

/// Decodes the HTML entities feeds use (`&amp;`, `&#39;`, `&#x2F;`…).
String decodeEntities(String s) => s.replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'), (m) {
  final e = m[1]!;
  if (e.startsWith('#x')) return String.fromCharCode(int.parse(e.substring(2), radix: 16));
  if (e.startsWith('#')) return String.fromCharCode(int.parse(e.substring(1)));
  return _entities[e] ?? m[0]!;
});

/// HTML to plain text: tags become spaces and entities are decoded.
/// Greenhouse escapes its HTML once more, so entities are decoded first too.
String htmlToText(String html) =>
    decodeEntities(decodeEntities(html).replaceAll(RegExp(r'<[^>]*>'), ' ')).replaceAll(RegExp(r'\s+'), ' ').trim();

/// Trims [s] and turns blank into null.
String? nonBlank(Object? s) {
  final t = (s as String?)?.trim();
  return t == null || t.isEmpty ? null : t;
}
