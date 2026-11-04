/// Lowercases [s], drops accents and punctuation, and collapses spaces, so
/// "hracek" finds Hráček and "osullivan" finds O'Sullivan.
String foldForSearch(String s) {
  final out = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final c = _plain[ch] ?? ch;
    if (RegExp(r'[a-z0-9 ]').hasMatch(c)) {
      out.write(c);
    } else if (RegExp(r'[\s/_.-]').hasMatch(c)) {
      out.write(' ');
    }
  }
  return out.toString().replaceAll(RegExp(' +'), ' ').trim();
}

const _plain = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'å': 'a', 'ã': 'a', 'ç': 'c', 'č': 'c', 'ć': 'c', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ñ': 'n', 'ń': 'n', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'ø': 'o', 'õ': 'o', 'ř': 'r', //
  'š': 's', 'ś': 's', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ý': 'y', 'ž': 'z', 'ł': 'l',
};
