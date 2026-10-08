# Contributing to Flutterverse

## Add or change a tracked project

Most contributions are a one-file pull request to [`config/seeds.yaml`](config/seeds.yaml):

```yaml
projects:
  - { id: my_package, pub: my_package, repo: me/my_package, categories: [ui], related: [flutter_animate] }
```

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Lowercase, URL-safe (`[a-z0-9_-]`), unique. Use the pub package name for packages. Used in `/p/<id>`. |
| `name` | no | Display name. Defaults to the id. |
| `kind` | no | `package` (default) or `project` for apps, tools and frameworks. |
| `pub` | one of `pub`/`repo` | pub.dev package name. |
| `repo` | one of `pub`/`repo` | GitHub `owner/name`. Derived from the pubspec when omitted. |
| `categories` | yes | One or more keys from the `categories:` map at the top of the file. |
| `related` | no | Ids of projects commonly used together with this one. |
| `sdk`, `platforms` | no | Only for unpublished projects; published packages get these from pub.dev. |
| `description` | no | Overrides the pub.dev/GitHub description. |

Quote any free text that contains a comma. In a `{ … }` mapping an unquoted
comma silently cuts the text short (CI catches this for Hall of Fame entries).

The Hall of Fame edition lives under `hall_of_fame:` in the same file, and the
learning roadmap's content is in [`config/roadmap.json`](config/roadmap.json).

Packages that live in a shared monorepo (such as `flutter/packages`) show
GitHub stars, forks and issues as N/A, because those numbers belong to the
whole repo rather than to the package.

Before opening the PR, check your change:

```bash
dart pub get
dart run fv_ingest:validate_seeds           # offline checks
dart run fv_ingest:validate_seeds --remote  # also checks pub.dev/GitHub (set GITHUB_TOKEN)
```

CI runs the same checks on every pull request.

## Hall of Fame nominations

Anyone with a GitHub account can nominate a developer or project, from the
**Propose** buttons on the site or the issue forms in
[`.github/ISSUE_TEMPLATE`](.github/ISSUE_TEMPLATE). The `nominations`
workflow checks each new issue automatically and closes it with an
explanation if:

- the form is incomplete, or the author's account is under 30 days old;
- the author already has 3 open nominations;
- the account or repository doesn't exist, the account is an organization, or
  the repository is archived, a fork or has fewer than 50 stars;
- it's already in the current Hall of Fame, or duplicates an earlier open
  nomination (people are asked to 👍 that one instead).

Valid nominations get the `needs-review` label. Anyone with write access can
then comment:

- `/shortlist` to mark it for the next edition, or
- `/decline <optional reason>` to close it with a polite reply.

Inductees are still added by hand to `hall_of_fame:` in `config/seeds.yaml`,
since each entry needs an editorial category and tagline. The limits live in
`NominationRules` (`packages/fv_ingest/lib/src/nominations.dart`).

## Working on the code

See the [README](README.md) for the layout and local commands, and
[GUIDELINES.md](GUIDELINES.md) for code conventions (including keeping
components small). Keep the dependency rules in mind
(`dart run tool/check_imports.dart` enforces them):

- `fv_core` is pure Dart: no `dart:io`, and nothing else from this repo.
- `fv_ingest` and `apps/web` depend on `fv_core`, never on each other.

Run `dart analyze --fatal-infos` and the package tests before sending a PR.
