# Flutterverse

The Flutter and Dart ecosystem, measured daily: GitHub stars, pub.dev scores,
momentum and health for a curated set of projects.

It runs on $0 infrastructure. A scheduled GitHub Action fetches pub.dev and
GitHub data, writes static JSON to a `data` branch, and a static
[Jaspr](https://jaspr.site) site served from Cloudflare Pages reads it.

## Layout

```
config/seeds.yaml        tracked projects, categories, Hall of Fame (hand-edited)
config/roadmap.json      learning roadmap content (hand-edited)
packages/fv_core/        models, Momentum/maintenance metrics, formatters (pure Dart)
packages/fv_ingest/      CLI: fetch → normalise → score → write JSON
apps/web/                Jaspr static site
  lib/components/        shared UI: ui/ primitives, layout/ site chrome, project/ displays
  lib/pages/<page>/      one folder per page, one small component per file
  lib/styles/            design tokens (light/dark), shared classes, CSS helpers
tool/check_imports.dart  enforces the package dependency rules
.github/workflows/       ci.yml, ingest.yml (daily), deploy-web.yml
```

## Local development

Requires Dart 3.10+ (`.fvmrc` pins a Flutter SDK that ships it) and the Jaspr CLI
(`dart pub global activate jaspr_cli`).

```bash
dart pub get                                         # once, at the root

# Refresh data into apps/web/web/data (history goes to .history/).
# GITHUB_TOKEN is optional; without it GitHub numbers are N/A.
GITHUB_TOKEN=$(gh auth token) dart run fv_ingest:ingest

cd apps/web && jaspr serve                           # http://localhost:8080
cd apps/web && jaspr build                           # → apps/web/build/jaspr
```

Checks:

```bash
dart analyze --fatal-infos
dart run tool/check_imports.dart
(cd packages/fv_core && dart test)
(cd packages/fv_ingest && dart test)
(cd apps/web && dart test)
dart run fv_ingest:validate_seeds --remote
```

## Generated data

`fv_ingest` writes, per screen:

| File | Contents |
|---|---|
| `index.json` | Slim rows for the Listing and Rankings tables |
| `p/<id>.json` | Full detail and up to 90 days of history |
| `pub.json` | Every Flutter Favorite |
| `hof.json` | The Hall of Fame edition, with developers' GitHub stats |
| `roadmap.json` | The learning roadmap |
| `meta.json` | `generatedAt` and the schema version |

It also appends one line per project per day to `history/<id>.ndjson`. Star
growth and Momentum are computed from that history, because the APIs only
report current values (GitHub no longer exposes stargazer dates, so history
can't be backfilled). Weekly download history comes straight from pub.dev. When a source fails, its values are written as null
(shown as N/A) and the run carries on.

## Deployment setup

1. Push to GitHub (public repo, so Actions minutes are free).
2. Create a Cloudflare Pages project named `flutterverse` (direct upload).
3. Add repository secrets `CF_API_TOKEN` (Pages: Edit) and `CF_ACCOUNT_ID`.
4. Run the **ingest** workflow once by hand. It creates the `data` branch, and
   a successful run triggers **deploy-web**.

Note: GitHub disables scheduled workflows after 60 days without repository
activity. If that happens, re-enable **ingest** from the Actions tab.

## License

MIT. See [LICENSE](LICENSE).
