import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';

/// PostHog's global, present only in release builds (see `analytics.dart`).
@JS('posthog')
external _PostHog? get _posthog;

extension type _PostHog._(JSObject _) implements JSObject {
  external void capture(String event, JSAny? properties);
}

/// Sends a product event to PostHog. Does nothing on the server, and in
/// preview and local builds, where PostHog isn't loaded.
///
/// Never put package names or pasted text in [props]: people paste private
/// pubspecs, so events carry counts only.
void track(String event, [Map<String, Object> props = const {}]) {
  if (!kIsWeb) return;
  try {
    _posthog?.capture(event, props.jsify());
  } on Object {
    // Analytics must never break the page.
  }
}
