import 'package:fv_core/fv_core.dart';

/// Currency markers a stated range may use, and the ISO code each means.
/// `$` alone is taken as USD; the prefixed dollars name their own.
const _currencies = {
  r'US$': 'USD',
  r'CA$': 'CAD',
  r'C$': 'CAD',
  r'A$': 'AUD',
  r'AU$': 'AUD',
  r'S$': 'SGD',
  r'NZ$': 'NZD',
  r'HK$': 'HKD',
  r'R$': 'BRL',
  r'$': 'USD',
  '€': 'EUR',
  '£': 'GBP',
  '₹': 'INR',
  '¥': 'JPY',
  'zł': 'PLN',
};

const _codes = {
  'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR', 'CHF', 'SGD', 'PLN', 'SEK', 'NOK', 'DKK', 'BRL', //
  'MXN', 'JPY', 'NZD', 'HKD', 'AED', 'ZAR', 'PHP', 'IDR', 'MYR', 'VND', 'THB', 'NGN', 'KES', 'PKR', 'TRY',
  'CZK', 'HUF', 'RON', 'UAH', 'ILS', 'KRW', 'TWD', 'ARS', 'COP', 'CLP', 'EGP', 'BDT', 'LKR',
};

final _sym = [
  for (final k in _currencies.keys.toList()..sort((a, b) => b.length - a.length)) RegExp.escape(k),
].join('|');
final _cur = '(?:$_sym|\\b(?:${_codes.join('|')})\\b)';

/// A figure: `150,000`, `150.000`, `150 000`, `62.5k`, `120K`.
const _num = r'\d{1,3}(?:[,.   ]\d{3})+(?:\.\d+)?|\d+(?:[.,]\d+)?';

/// `$120k – $160k`, `€60.000-80.000`, `USD 5,000 to 7,000`, `90-110K EUR`.
final _range = RegExp(
  '(?<c1>$_cur)?\\s?(?<lo>$_num)\\s?(?<k1>[kK])?\\s?(?<c2>$_cur)?'
  '\\s?(?:-|–|—|to|TO)\\s?'
  '(?<c3>$_cur)?\\s?(?<hi>$_num)\\s?(?<k2>[kK])?(?:\\s?(?<c4>$_cur))?',
);

/// Words that put a range on pay rather than on something else.
final _payWord = RegExp(
  r'\b(salary|salaries|compensation|pay|paid|base|range|remuneration|wage|rate|ote|income|earn\w*|gross|ctc|brutto)\b',
  caseSensitive: false,
);

/// Words just before a range that put it on money that isn't pay.
final _notPayBefore = RegExp(
  r'\b(raised|funding|funded|series [a-e]|revenue|arr|valuation|budget|stipend|allowance|bonus|grant|investors?)\b',
  caseSensitive: false,
);

/// A noun right after a range (`$2,000 learning budget`) that makes it
/// something other than pay. `$150K + bonus` stays pay: the `+` breaks it.
final _notPayAfter = RegExp(
  r'^\s?(?:[a-z]+\s){0,2}?(budget|stipend|allowance|bonus|grant|funding|revenue|arr|valuation)\b',
  caseSensitive: false,
);

final _negotiable = RegExp(
  r'\b(salary|compensation|pay|remuneration|rate|wage)\b[^.\n|;,]{0,40}?\bnegotiable\b'
  r'|\bnegotiable\s+(salary|compensation|pay|rate|remuneration)\b',
  caseSensitive: false,
);

final _periods = <PayPeriod, RegExp>{
  PayPeriod.hour: RegExp(r'^\s*(/\s?(hr|hour|h)\b|per hour|an hour|hourly|p/h)', caseSensitive: false),
  PayPeriod.day: RegExp(r'^\s*(/\s?day\b|per day|a day|daily)', caseSensitive: false),
  PayPeriod.week: RegExp(r'^\s*(/\s?(wk|week)\b|per week|a week|weekly)', caseSensitive: false),
  PayPeriod.month: RegExp(r'^\s*(/\s?(mo|month)\b|per month|a month|monthly|p\.?m\.?(?!\w))', caseSensitive: false),
  PayPeriod.year: RegExp(
    r'^\s*(/\s?(yr|year|y|annum)\b|per year|a year|per annum|annual\w*|yearly|p\.?a\.?(?!\w))',
    caseSensitive: false,
  ),
};

/// A period word leading into a range: "the gross monthly salary ranges
/// from", "an annual base of", "hourly rate:".
final _periodsBefore = <PayPeriod, RegExp>{
  PayPeriod.hour: RegExp(r'\b(hourly|per hour)\b', caseSensitive: false),
  PayPeriod.day: RegExp(r'\b(daily|day) rate\b', caseSensitive: false),
  PayPeriod.month: RegExp(r'\b(monthly|per month)\b', caseSensitive: false),
  PayPeriod.year: RegExp(r'\b(annual|annually|yearly|per year|per annum)\b', caseSensitive: false),
};

/// Pay stated in free text: the first currency range that reads as pay, or
/// [Salary.negotiable] when the text says pay is negotiable; null when it
/// says neither.
///
/// A range counts when it names a currency, isn't next to words about other
/// money (funding, budgets, bonuses), and either follows a pay word
/// ("salary", "compensation", "base"…) within [_lookBack] characters or
/// states its period ("/yr", "per month"). With [lenient], used for a Hacker
/// News post's one-line header, no pay word or period is needed: a currency
/// range there is the salary.
///
/// The period is only what the text says, right after the range or in the
/// few words leading into it; a range without one has none.
Salary? salaryFromText(String? text, {bool lenient = false}) {
  if (text == null || text.isEmpty) return null;
  for (final m in _range.allMatches(text)) {
    if (_salaryAt(text, m, lenient: lenient) case final s?) return s;
  }
  return _negotiable.hasMatch(text) ? const Salary.negotiable() : null;
}

const _lookBack = 80;

Salary? _salaryAt(String text, RegExpMatch m, {required bool lenient}) {
  final marker = [m.namedGroup('c1'), m.namedGroup('c2'), m.namedGroup('c3'), m.namedGroup('c4')].nonNulls.firstOrNull;
  if (marker == null) return null;
  final currency = _currencyOf(marker);
  if (currency == null) return null;

  final before = text.substring((m.start - _lookBack).clamp(0, m.start), m.start);
  final after = text.substring(m.end, (m.end + 30).clamp(m.end, text.length));
  if (_notPayBefore.hasMatch(text.substring((m.start - 30).clamp(0, m.start), m.start))) return null;
  if (_notPayAfter.hasMatch(after)) return null;
  // `$5M–$10M` is never a salary here.
  if (RegExp(r'^\s?(m|mm|bn|b|million|billion)\b', caseSensitive: false).hasMatch(after)) return null;

  final lead = text.substring((m.start - 50).clamp(0, m.start), m.start);
  final per =
      [
        for (final e in _periods.entries)
          if (e.value.hasMatch(after)) e.key,
      ].firstOrNull ??
      [
        for (final e in _periodsBefore.entries)
          if (e.value.hasMatch(lead)) e.key,
      ].firstOrNull;
  if (!lenient && per == null && !_payWord.hasMatch(before)) return null;

  final k2 = m.namedGroup('k2') != null;
  final k1 = m.namedGroup('k1') != null;
  final hi = _figure(m.namedGroup('hi')!, k: k2);
  var lo = _figure(m.namedGroup('lo')!, k: k1);
  if (lo == null || hi == null) return null;
  // `$120–150K`: the K on the second figure covers the first.
  if (k2 && !k1 && lo < 1000 && hi >= 1000) lo *= 1000;
  if (lo <= 0 || lo > hi || hi > lo * 5) return null;
  // Without a period, a small figure is likely a count or an age, not pay.
  if (per == null && hi < 1000) return null;
  return Salary(min: lo.round(), max: hi.round(), currency: currency, per: per);
}

String? _currencyOf(String marker) {
  final upper = marker.toUpperCase();
  if (_codes.contains(upper)) return upper;
  return _currencies[marker] ?? _currencies[upper];
}

/// `150,000` and `150.000` → 150000, `62.5` with [k] → 62500, `3,5` with
/// [k] → 3500.
double? _figure(String s, {required bool k}) {
  final t = s.replaceAll(RegExp('[   ]'), '');
  // A separator followed by exactly three digits groups thousands.
  final grouped = RegExp(r'^\d{1,3}([,.]\d{3})+$').hasMatch(t);
  final v = grouped ? double.tryParse(t.replaceAll(RegExp('[,.]'), '')) : double.tryParse(t.replaceAll(',', '.'));
  if (v == null) return null;
  return k ? v * 1000 : v;
}
