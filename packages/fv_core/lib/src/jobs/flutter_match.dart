import '../models/job.dart';

final _titleWord = RegExp(r'\b(flutter|dart)\b', caseSensitive: false);
final _textWord = RegExp(r'\bflutter\b', caseSensitive: false);

/// A title that names client-side app work.
final _appRole = RegExp(
  r'\b(mobile|apps?|ios|android|cross[- ]platform|front[- ]?end|client|desktop)\b',
  caseSensitive: false,
);

/// A title that isn't an engineering role, whatever else it says.
final _nonEngineering = RegExp(
  r'\b(sales|marketing|recruit\w*|support|success|account|product (manager|owner)|designer)\b',
  caseSensitive: false,
);

/// Whether a role is a Flutter role, and how strongly.
///
/// - [JobMatch.title]: "Flutter" or "Dart" is a whole word in [title].
/// - [JobMatch.mentions]: "Flutter" is a whole word in [text] (the plain-text
///   description), *and* the title names app work (mobile, iOS, Android,
///   app, front end, desktop…) and isn't a sales, support or product role.
///   The title check exists because companies put "we build with Flutter"
///   in the boilerplate of every posting, backend and sales ones included.
///   A bare "Dart" in the description never counts.
/// - null: neither.
///
/// Whole words only, so "Dartmouth" and "FlutterFlow" don't match.
JobMatch? flutterMatch(String title, String? text) {
  if (_titleWord.hasMatch(title)) return JobMatch.title;
  if (text == null || !_textWord.hasMatch(text)) return null;
  if (!_appRole.hasMatch(title) || _nonEngineering.hasMatch(title)) return null;
  return JobMatch.mentions;
}
