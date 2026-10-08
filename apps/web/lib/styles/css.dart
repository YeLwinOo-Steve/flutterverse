import 'package:jaspr/dom.dart';

/// A style rule from plain CSS properties. The design is specified in CSS,
/// so mapping it 1:1 keeps it pixel-accurate and easy to compare.
StyleRule rule(String selector, Map<String, String> props) => css(selector).styles(raw: props);

/// A `@media (max-width: …)` block.
StyleRule below(int px, List<StyleRule> rules) => css.media(MediaQuery.raw('(max-width: ${px - 1}px)'), rules);

/// A `@media (min-width: …)` block.
StyleRule above(int px, List<StyleRule> rules) => css.media(MediaQuery.raw('(min-width: ${px}px)'), rules);

/// The design's monospace shorthand, e.g. `mono(12)` → `500 12px 'Geist Mono',monospace`.
String mono(num size, {int weight = 500}) => "$weight ${size}px 'Geist Mono',monospace";

/// The design's sans shorthand.
String sans(num size, {int weight = 400}) => "$weight ${size}px 'Geist',sans-serif";
