# Code Guidelines

These build on [Effective Dart](https://dart.dev/effective-dart). Where this file is silent, follow Effective Dart and match the code around you.

## 1. Tooling is the baseline

- Run `dart format .` before committing. Line width is **120**, set in `analysis_options.yaml`.
- `dart analyze --fatal-infos` must pass. Don't silence a lint with `// ignore:` unless you explain why on the same line.
- `strict-casts` and `strict-raw-types` are on. Cast JSON explicitly (`json['x'] as String?`) and never use `dynamic` to get around the type system.

## 2. Respect the package boundaries

| Package | May import |
|---|---|
| `fv_core` | Only `dart:` libraries other than `dart:io`/`dart:html`. Nothing else from this repo. |
| `fv_ingest` | `fv_core`, plus `http`, `yaml`, `args`, `path` |
| `apps/web` | `fv_core` only |

- `dart run tool/check_imports.dart` enforces this in CI.
- Shared logic (models, metrics, formatting) goes in `fv_core`, so the site and the ingest job can never disagree on a number.
- Inside a package, use relative imports in `lib/`. Use `package:` imports across packages and from `test/` and `bin/`.

## 3. Naming and style

- `UpperCamelCase` for types, `lowerCamelCase` for members and constants, `snake_case.dart` for files.
- Prefer `final` locals and `const` constructors. Make a field mutable only when it needs to change.
- Use Dart 3 features where they make code clearer: records, patterns, switch expressions, `if-case`, and null-aware elements (`?value`).
- Keep functions small and pure where you can. Pass time in (`now:`) instead of calling `DateTime.now()` deep inside logic, so it stays testable.
- Use UTC for every stored date. Days are `YYYY-MM-DD` strings (`Snapshot.dayOf`).

## 4. Models and JSON

- Models are immutable and hand-written, with a `factory X.fromJson(Json)` and a `Json toJson()`.
- Wrap `toJson` in `compact()` so null fields are left out, and leave out empty lists and `false` flags where the reader has defaults.
- Changing the shape of a generated file is a breaking change. Bump `schemaVersion` in `fv_core/lib/src/json.dart` and update both the writer and the readers in the same PR.
- `index.json` stays slim. Anything that's only needed on one page goes in that page's file (`p/<id>.json` and so on).

## 5. Missing data is `null`, never a fake value

- If a number is unknown because a source failed or history is too short, it's `null` and the UI shows **N/A** (`notAvailable`). Never substitute `0`.
- If a metric doesn't apply (e.g. pub.dev numbers for an unpublished project), show **—** (`notApplicable`).
- Format with the `fv_core` helpers (`compactNumber`, `signedNumber`, `percent`, `ago`, `fullDate`). They already handle null.
- Sorting puts nulls last (`sortedBy`).
- Free text in `config/seeds.yaml` that contains a comma must be quoted. In a `{ … }` flow mapping, an unquoted comma silently cuts the text short.

## 6. Error handling (ingest)

- One failing package or source must never fail the run. Catch the error at the per-package or per-source level, record it with `warn(...)`, and continue with `null`.
- Every network call goes through `withRetry`. Concurrency stays at about 4 (`mapPool`).
- Only `throw` for programmer errors or invalid input such as a malformed `seeds.yaml`. In `bin/`, report failures with a message and a non-zero exit code, not a stack trace.
- Catch specific exceptions where you can. `on Object catch (e)` is fine at an isolation boundary such as a per-package `try`.

## 7. Small, digestible components

- **One component, one job.** If a component renders two distinct things (a header and a table, a chart and its controls), split it.
- **Keep `build` short.** Aim for a `build` method that fits on one screen (about 60 lines). Pull repeated or nested markup into a private widget or a small helper.
- **Keep files small.** A component file should hold its component plus at most a few private helpers it alone uses. Around 250 lines is a signal to split.
- **Group by feature.** Each page has its own folder (`pages/detail/`, `pages/roadmap/`…) with one file per piece. Components used by more than one page go in `components/` (`ui/` primitives, `layout/` site chrome, `project/` project displays).
- **Push logic out of components.** Sorting, filtering, geometry and formatting live in plain Dart (`data/`, `pages/<page>/*_data.dart` or `*_layout.dart`, or `fv_core`), so they can be unit-tested without rendering. See `metro_layout.dart` and `chart_data.dart`.
- **Pass data down, events up.** Components take only what they render plus callbacks (`onSelect`, `onToggle`). State lives in the nearest island that needs it.

## 8. Jaspr web app

- **Pre-render by default.** Use `@client` only for the smallest piece that needs browser state or interaction, such as a filterable table, a chart or a toggle. Static markup stays server-only.
- A `@client` file, and everything it imports, must compile for the browser. No `dart:io` and no `data/site_data.dart`.
- `@client` parameters must be primitive or have a codec. `fv_core` models get codecs from the extension types in `data/codecs.dart`, so islands can take an `IndexFile`, `ProjectDetail` or `RoadmapFile` directly and pre-render with real data.
- Guard browser-only work with `if (kIsWeb)` in `initState`. Read browser APIs through `package:universal_web` (`web.dart`, `js_interop.dart`), and wrap storage access in `try`/`catch` because it can be blocked.
- Static buttons open shared dialogs through data attributes (`data-open-palette`, `data-open-modal="…"`) rather than becoming islands themselves.
- Lazy client data goes through `DataRepo`, which caches it. Never call `http.get` from a component.
- **Styling.** Port the design's CSS 1:1 with `rule(selector, {...})` in a `@css static List<StyleRule> get styles` on the component class (not its `State`). Use `var(--token)` for every color; tokens and dark-mode values live in `styles/theme.dart`. Classes reused across pages belong in `styles/shared.dart`. Inline `styles:` are only for per-instance values such as a logo color or a computed position.
- Keep CSS-animated markup (such as the intro splash) out of islands. Hydration re-inserts nodes it can't line up with the pretty-printed server HTML, which restarts their animations. Render the markup statically and drive it from a small island that renders nothing (`IntroController`).
- Never pass the whole index to an island: its props are embedded in every page that renders it, and the catalog has thousands of projects. Pass only the rows the first render needs (`previewOf`, with a static `previewRows` on the island) and mix in `FullIndex` to load `index.json` in the browser when more is needed. When a bounded set covers every state, such as each tab's top 8, pass just that and skip the download.
- Never use `href="#"`: the document's `<base href="/">` turns it into a link to the home page.
- Read pointer positions with `event.x` / `event.y`, never `clientX` / `clientY`. `package:web` types those as `int`, browsers report fractional pixels, and debug builds throw on every move.
- Every interactive element needs an accessible name (`aria-label` when it has no text label).

## 9. Testing

- Every metric and formatter in `fv_core` needs unit tests, including edge cases: empty history, gaps, null counters, negative growth.
- Ingest code is tested with `MockClient` from `package:http/testing.dart`. Tests never hit the real network.
- Tests that touch the filesystem use a temporary directory created in `setUp` and deleted in `tearDown`.
- A bug fix comes with a test that fails without the fix.

## 10. Documentation

- Write `///` doc comments on public APIs, and explain *why* or *what it means* rather than restating the signature. Start with a one-sentence summary.
- Any formula (Momentum, maintenance) must have its exact definition in its doc comment. If the formula changes, update the About page copy too.
- Comment non-obvious decisions, such as "static generation can't use path params, so emit one route per project". Don't comment the obvious.
