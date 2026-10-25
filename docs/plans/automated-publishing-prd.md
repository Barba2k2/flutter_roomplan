# PRD: automated publishing of `roomplan_flutter` (and future siblings) to pub.dev

Date: 2026-10-24. Status: implemented 2026-10-24 (publish via tag push proven; auto-tag flow not yet run). Convention: lives in `docs/plans/`, same format as `object-capture-package-plan.md`. Facts below were checked on 2026-10-24 against the sources linked inline; anything not found in a source is marked **UNVERIFIED**.

## 1. Goal

Publish a package version to pub.dev by merging a version bump to `master`, from GitHub Actions (the workflow creates the tag itself, no approval, no manual step), with no interactive Google login and no long-lived secret. The workflow refuses to publish when the tag, `pubspec.yaml`, `CHANGELOG.md`, analyzer or tests disagree. The same setup must scale to more packages in `packages/` by copying one small workflow file.

## 2. Non-goals

- Publishing the first version of a new package (not automatable, see 3).
- Auto-bumping versions or generating changelogs from CI (melos `version` stays a local, manual tool). Tagging IS automated (see 5.2).
- Running the iOS example build or any macOS job in CI.
- Publishing from branch runs, schedules or PR events. Publishing only ever runs on a tag ref (see 6).
- Fixing unrelated repo oddities (see 11).

## 3. Current state and pain

- Publishing is manual `flutter pub publish` with interactive Google login.
- `0.3.0` shipped with a stale README snippet (`^0.1.1`), fixed by `0.3.0+1` (CHANGELOG entry confirms). pub.dev versions cannot be republished or deleted, so each such slip costs a permanent version number.
- No `.github/` directory: no CI at all. Repo `Barba2k2/flutter_roomplan` is public, default branch `master` (GitHub API).
- Remote has no tags (GitHub API `tags` returned empty); local has only `v0.1.4`. So no existing remote tag conflicts with a new scheme.
- pub.dev limitation: "Today, you can only automate publishing of existing packages. To create a new package, you must publish the first version using `dart pub publish`." `roomplan_flutter` already exists, so it is eligible. Every future sibling needs one manual first publish. Source: [dart.dev automated publishing](https://dart.dev/tools/pub/automated-publishing).

## 4. What the docs and pub.dev source say (verified)

| Topic | Fact | Source |
|---|---|---|
| Auth | Short-lived OIDC token signed by GitHub; no secret to store. Job needs `permissions: id-token: write`. | [dart.dev](https://dart.dev/tools/pub/automated-publishing) |
| Trigger | pub.dev accepts publishing only from workflows started by a tag push; "rejects publishing from GitHub Actions triggered without a tag". | [dart.dev](https://dart.dev/tools/pub/automated-publishing) |
| `workflow_dispatch` | pub.dev admin page has this checkbox (default off). Server code requires `refType == 'tag'` for both `push` and `workflow_dispatch`, so a dispatch only works when run on a tag ref. | pub.dev source: [`backend.dart`](https://github.com/dart-lang/pub-dev/blob/master/app/lib/package/backend.dart) (`refType != 'tag'` check), [`admin_page.dart`](https://github.com/dart-lang/pub-dev/blob/master/app/lib/frontend/templates/views/pkg/admin_page.dart) |
| Tag pattern | Must contain exactly one `{{version}}`. Allowed literal characters: `a-z 0-9 - . _ /` (case-insensitive). Plain character match, no regex. | pub.dev source `backend.dart` (`_validGitHubVersionPattern`, `verifyTagPattern`), `package_api.dart` |
| Tag check | pub.dev builds the expected ref as `refs/tags/` + pattern with `{{version}}` replaced by the **exact version being uploaded**, and requires an exact string match. | pub.dev source `backend.dart` (`verifyTagPatternWithRef`) |
| Build metadata | So version `0.3.0+1` needs tag `<prefix>0.3.0+1`. `+` is legal in a git tag name. The pattern's allowed-character list does not apply to the substituted version. | derived from the two rows above; **tag name `+` handling by `git push` not tested here** |
| Monorepo | Docs: "If your repository contains multiple packages, give each a separate tag-pattern", e.g. `my_package_name-v{{version}}`. | [dart.dev](https://dart.dev/tools/pub/automated-publishing) |
| GitHub tag filter | In `on.push.tags`, `*` matches zero or more chars except `/`; `+` means "one or more of the preceding character"; `.` is literal in the cheat sheet examples. pub.dev's own generated example workflow expands `{{version}}` to `[0-9]+.[0-9]+.[0-9]+*` (trailing `*` tolerates `+1` and prerelease suffixes). | [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), pub.dev source `admin_page.dart` (`_exampleGitHubWorkflow`) |
| Reusable workflow (not used) | **Verified 2026-10-24:** `dart-lang/setup-dart/.github/workflows/publish.yml` @ `6afc89df` accepts ONLY the inputs `environment` and `working-directory`. It has no `test-run` and no `use-flutter`; passing `test-run` made the first run end in `startup_failure`. It always runs `dart pub get`, `dart pub publish --dry-run`, `dart pub publish -f`, so a dry run through it is impossible. The own `publish` job in section 5.2 replaced it. | [source @ 6afc89df](https://github.com/dart-lang/setup-dart/blob/6afc89df92d6eb3834022f73cd65adc8cdfcb92d/.github/workflows/publish.yml) |
| Environment | Optional "Require GitHub Actions environment": publishing only works if the job declares `environment: <name>`; the name is baked into the OIDC token, so editing the workflow cannot bypass it. GitHub environment protection rules (required reviewers) then hold the run until approved. | [dart.dev](https://dart.dev/tools/pub/automated-publishing) |
| Hardening | Docs: without extra controls "anyone with push access to your repository can publish"; use tag protection rules or deployment environments. | [dart.dev](https://dart.dev/tools/pub/automated-publishing) |
| Retraction | A version can be retracted within 7 days of publication (restorable within 7 days of retraction). Retraction is not deletion. | [dart.dev publishing](https://dart.dev/tools/pub/publishing) |
| Manual publishing toggle | Admin page has "Enable manual publishing"; its help text: "It is recommended to disable when automated publishing is enabled." | pub.dev source `admin_page.dart` |

Pinned action versions (latest releases, all older than 2 weeks; today is 2026-10-24; resolved via GitHub API):

- `dart-lang/setup-dart` v1.8.1, published 2026-08-28, commit `6afc89df92d6eb3834022f73cd65adc8cdfcb92d` (the `v1` tag points to the same commit). Its `action.yml` runs `createPubOIDCToken` in `lib/main.dart`: when `ACTIONS_ID_TOKEN_REQUEST_URL` is set (job has `id-token: write`) it exports `PUB_TOKEN` and runs `dart pub token add https://pub.dev --env-var PUB_TOKEN` (verified in source).
- `actions/checkout` v7.0.1, published 2026-07-20, commit `3d3c42e5aac5ba805825da76410c181273ba90b1`.
- `subosito/flutter-action` v2.23.0, published 2026-03-25, commit `1a449444c387b1966244ae4d4f8c696479add0b2`.

Pin by commit SHA with a version comment. Re-check versions on the day the workflow is written (owner rule: latest).

## 5. Requirements

### 5.1 Tag pattern (monorepo)

- pub.dev pattern: `roomplan_flutter-v{{version}}`. Tag example: `roomplan_flutter-v0.3.1`, `roomplan_flutter-v0.3.0+1`.
- Rationale: one tag namespace per package, so a tag for package A can never trigger or authorize publishing package B; the name equals the pubspec `name`, matching the pattern the docs suggest; `_` and `-` are allowed characters.
- GitHub trigger filter in the workflow: `roomplan_flutter-v[0-9]+.[0-9]+.[0-9]+*`. The trailing `*` is required: without it `…v0.3.0+1` does not match, because `+` in a GitHub filter is a quantifier, not a literal. Matches pub.dev's own generated example.
- Each future package gets its own workflow file with its own prefix and `working-directory`.
- Existing tags: remote has none; local `v0.1.4` does not match and is left alone (no retagging; old versions on pub.dev are already published). First automated release is the next version after `0.3.0+1`. Nothing is back-filled.

### 5.2 Workflow (`.github/workflows/publish-roomplan-flutter.yml`)

Triggers: `push` to `master` limited to `paths: [packages/roomplan_flutter/pubspec.yaml]`, `push` of tags matching 5.1, and `workflow_dispatch` (dry run on a branch ref, publish on a tag ref).

Release mechanism (owner decision 2026-10-24: everything automated, no approval gate, no manual tag):

1. A PR bumping `version` merges to `master`; the `master` push starts job `tag`.
2. `tag` (`contents: write`, `actions: write`, default `GITHUB_TOKEN`) reads the version from `pubspec.yaml`, builds `roomplan_flutter-v<version>`, exits successfully if that tag already exists on the remote, otherwise creates it at the pushed commit and pushes it.
3. Tag pushes made with `GITHUB_TOKEN` do NOT trigger push workflows (GitHub rule), so `tag` then runs `gh workflow run publish-roomplan-flutter.yml --ref <tag>`; `workflow_dispatch` via `GITHUB_TOKEN` is allowed. That run has `github.ref_type == 'tag'`, so `verify` and `publish` run for real.
4. `verify` and `publish` are skipped on the `master` push event itself (`github.event_name != 'push' || github.ref_type == 'tag'`). A manually pushed tag still triggers them directly.
5. A `workflow_dispatch` on a branch stays a dry run (no tag ref: no environment, no `pub publish`).

Status: publishing via tag push is **verified** (tag `roomplan_flutter-v0.3.0+2` published through OIDC). Auto-tag plus dispatch-on-tag is **UNVERIFIED** until the first merge runs it end to end. The `paths` filter combined with the `tags` filter in one `push` is also unverified (GitHub documents that path filters are not evaluated for tag pushes).

Jobs:

0. `tag` (master push only): see above.
1. `verify` (ubuntu, `contents: read`): checkout, Flutter stable via `subosito/flutter-action` (with cache), then gates:
   - tag version equals `pubspec.yaml` `version` (tag with the `roomplan_flutter-v` prefix stripped). pub.dev also enforces this, but failing here gives a clearer error before any approval is requested;
   - `CHANGELOG.md` has a `## <version>` heading;
   - `flutter analyze`;
   - `flutter test` in `packages/roomplan_flutter`.
2. `publish`: own job (the dart-lang reusable workflow was dropped, see section 3: it has no `test-run`/`use-flutter` inputs, so it caused `startup_failure`, and it cannot dry-run). `needs: verify`, `permissions: contents: read, id-token: write`, `environment` only on tag runs (`github.ref_type == 'tag' && 'pub.dev' || null`; the environment has no required reviewers, so nothing waits for approval, and branch dry runs skip it). Steps: checkout, `dart-lang/setup-dart` (provisions the OIDC token), `subosito/flutter-action`, `flutter pub get`, `flutter pub publish --dry-run`, then on tags only `flutter pub publish --force`.

Draft (simplified; the file `.github/workflows/publish-roomplan-flutter.yml` is the source of truth, the `tag` job and the `if:` guards are only there):

```yaml
name: Publish roomplan_flutter
on:
  push:
    tags: ['roomplan_flutter-v[0-9]+.[0-9]+.[0-9]+*']
  workflow_dispatch:
jobs:
  verify:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - name: Tag matches pubspec and CHANGELOG
        if: github.ref_type == 'tag'
        working-directory: packages/roomplan_flutter
        run: |
          v="${GITHUB_REF_NAME#roomplan_flutter-v}"
          grep -qx "version: $v" pubspec.yaml
          grep -qx "## $v" CHANGELOG.md
      - run: flutter analyze
      - run: flutter test
        working-directory: packages/roomplan_flutter
  publish:
    needs: verify
    permissions:
      contents: read
      id-token: write
    runs-on: ubuntu-latest
    environment: ${{ github.ref_type == 'tag' && 'pub.dev' || null }}
    defaults:
      run:
        working-directory: packages/roomplan_flutter
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: dart-lang/setup-dart@6afc89df92d6eb3834022f73cd65adc8cdfcb92d # v1.8.1
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter pub publish --dry-run
      - name: Publish
        if: github.ref_type == 'tag'
        run: flutter pub publish --force
```

**UNVERIFIED, must be proven in rollout R1:**
- `flutter pub publish` picks up the setup-dart OIDC token: setup-dart stores it with `dart pub token add` (user-level pub config, not `PUB_CACHE`) and exports `PUB_TOKEN`; the reusable workflow's own comment says Flutter's `dart` shadows the setup-dart one, yet it publishes with it. Source-verified, but only proven end to end in R1/R3 (**UNVERIFIED** at runtime). A plugin inside a pub workspace member (`resolution: workspace`) was not tested either.
- `flutter test` passes headless on Linux (looks pure Dart: `mapper_test`, `models_test`, `floor_ceiling_test`; not run here).
- `flutter analyze` at the workspace root is clean today (not run here).
- Whether the caller job needs `contents: read` for a private repo (repo is public; irrelevant today).

## 6. pub.dev admin page settings

Page: `pub.dev/packages/roomplan_flutter/admin`, section Automated publishing > Publishing from GitHub Actions.

| Field | Value | Why |
|---|---|---|
| Enable publishing from GitHub Actions | checked | feature switch |
| Repository | `Barba2k2/flutter_roomplan` | exact `<owner>/<repository>`; pub.dev rejects other repos |
| Tag pattern | `roomplan_flutter-v{{version}}` | see 5.1 |
| Enable publishing from `push` events | **checked** | the only trigger the flow uses |
| Enable publishing from `workflow_dispatch` events | **checked** | the `tag` job starts the publish run with `gh workflow run --ref <tag>` because `GITHUB_TOKEN` tag pushes do not trigger push workflows; pub.dev still requires a tag ref for dispatch (source above), so branch dispatches cannot publish |
| Require GitHub Actions environment | **checked**, name `pub.dev` | token-bound control that a workflow edit cannot bypass; the GitHub environment has NO required reviewers (no approval gate, owner decision) and its deployment policy allows tags `roomplan_flutter-v*` and branch `master` |
| Enable manual publishing (separate section) | **unchecked, but only after the first successful automated release** | pub.dev recommends disabling it; keep it on until R3 proves the pipeline, otherwise a broken CI locks out releases |

## 7. Release flow (per version)

1. Branch; bump `version` in `packages/roomplan_flutter/pubspec.yaml`; add `## <version>` to `CHANGELOG.md`; update README snippet if it names a version. Open PR.
2. CI gates run on the PR (see 9: a cheap PR workflow is optional; the tag run re-runs the same gates anyway).
3. Squash merge to `master` (repo rule: squash only).
4. Nothing else. The `master` push runs job `tag`, which creates `roomplan_flutter-v<version>` at the merge commit and dispatches the workflow on it; `verify` then `publish` run with no approval.
5. Check the pub.dev audit log (links to the run) and the package page; confirm README/changelog render as intended.

The rest of the loop (delete nothing, branch kept after merge) follows the owner's standing git rules.

## 8. Security

- OIDC only; no pub.dev credentials, tokens or service-account keys in GitHub secrets.
- Who can publish = who can merge to `master` (or push a matching tag). There is no approval gate by owner decision. The GitHub environment `pub.dev` exists only to bind the OIDC token to it; its deployment policy allows tags `roomplan_flutter-v*` and branch `master`. Configure:
  - Restrict tag creation for `roomplan_flutter-v*` to admins. GitHub's older "tag protection rules" may be superseded by repository rulesets (**UNVERIFIED**, not checked); use whichever the repo settings offer. dart.dev names tag protection and environments as the two hardening options.
- Actions pinned by commit SHA, so a moved tag upstream cannot change what runs. Dependabot for `github-actions` can bump them (optional, not part of this PRD).
- `verify` job has `contents: read` only; only `publish` has `id-token: write`.
- Fork PRs cannot publish: pub.dev only accepts tag-triggered tokens for the configured repository.

## 9. Cost (GitHub Actions minutes)

- The workflow runs on a `master` push touching `packages/roomplan_flutter/pubspec.yaml` (only the cheap `tag` job), the resulting tag run, and manual dry runs. No PR trigger in v1.
- Expected run: Linux runner, roughly 5 to 8 minutes (analyze + test + dry-run + archive; estimate, not measured). Linux only, no macOS (macOS minutes cost far more on private repos, **UNVERIFIED** multiplier).
- Repo is public; standard GitHub-hosted runners are free for public repositories per GitHub billing docs (**UNVERIFIED**, not re-fetched today). The owner's concern about minutes on other (private) repos does not apply here, but the design stays cheap anyway.
- Optional later: a PR workflow running `verify` only. Not in scope; add only if a bad PR slips through.

## 10. Failure modes and rollback

| Failure | Behavior | Action |
|---|---|---|
| Tag does not match filter | no run | check glob (trailing `*`), recreate tag |
| Tag version differs from pubspec | `verify` fails (or pub.dev rejects with "Expected tag …") | fix on `master`; delete the wrong **tag** and retag (the tag, not a branch) |
| Gate fails (analyze/test/CHANGELOG) | nothing published | fix via PR, move tag to the new commit: delete remote tag, retag, push |
| `tag` job fails to dispatch | tag exists but nothing published | `gh workflow run publish-roomplan-flutter.yml --ref <tag>` by hand (or Actions UI, Run workflow on the tag) |
| OIDC/permission error from pub.dev | run fails at publish, nothing published | read log; confirm repo, pattern, environment name, push-events checkbox |
| Own `publish` job fails on the Flutter plugin/workspace or the OIDC token | `publish` fails at dry run or publish | read log; confirm `id-token: write`, setup-dart before flutter-action, pub.dev admin settings |
| Bad version already published | cannot be republished or deleted | publish a fixed version (`+1` or patch); retract the bad one within 7 days (restorable within 7 days) |
| Automation broken and urgent release needed | n/a | manual publishing still enabled until R3; afterwards re-enable the checkbox on the admin page |

Rule: if `verify` is green, the failure is almost always in pub.dev settings, not the code.

## 11. Rollout plan

- **R0 (settings, no code):** create GitHub environment `pub.dev` without required reviewers (deployment policy: tags `roomplan_flutter-v*` and branch `master`); apply the tag-creation restriction; set pub.dev admin fields per section 6 except leave manual publishing on.
- **R1 (dry run, no publish):** merge the workflow file; run it via `workflow_dispatch` (no tag, so no environment approval and no publish). Must show: `verify` green, `publish` green through `flutter pub publish --dry-run`. Fix the UNVERIFIED items in 5.2 here.
- **R2 (guarded negative test):** push a deliberately wrong tag on a throwaway commit (for example `roomplan_flutter-v9.9.9` where pubspec says otherwise) and confirm `verify` fails before `publish`, nothing published. Delete the tag afterwards. `verify` fails before `publish`, so a mistake cannot publish.
- **R3 (real release):** next real version goes through the flow in section 7. Verify the pub.dev audit log entry and package page. Then uncheck "Enable manual publishing".
- **R4:** document the release steps in `CONTRIBUTING.md` (3 lines) and copy the workflow for the next package when it exists (after its manual first publish).

## 12. Acceptance criteria

- Merging a version bump to `master` publishes exactly that version to pub.dev with no approval, no manual tag and no local login.
- A wrong-version, missing-CHANGELOG, analyze-failing or test-failing tag publishes nothing and fails before the approval step.
- Branch pushes and branch `workflow_dispatch` runs can never publish (the `master` push only creates the tag).
- No secret exists in the repo settings for pub.dev.
- The pub.dev audit log entry links to the Actions run.
- A `+1` build-metadata version (for example `0.3.1+1`) is covered by the filter and the pattern (verify with one dry-run tag name against the glob; a real `+1` publish is not required to accept this PRD).
- Typical run is under about 10 minutes of Linux time (measured in R1).

## 13. Decisions that belong to the owner

1. **Approval gate:** DECIDED 2026-10-24: none. Everything automated; merging a version bump publishes. Risk accepted: anyone who can merge to `master` can publish permanently.
2. **Disable manual `flutter pub publish` after the first good automated release:** recommend YES, after R3. Removes the interactive path that produced the `0.3.0` stale-README slip.
3. **Tag prefix per package (`roomplan_flutter-v…`) instead of plain `v…`:** recommend per-package prefix, because the repo is a workspace meant to hold more packages. Cost: the old `v0.1.4` style is abandoned.

Everything else in this document (gates, pins, file names, job layout) is an engineering choice made here.

## 14. Notes outside scope

- `melos.yaml` section in the root `pubspec.yaml` sets `command.version.branch: main`, but the default branch is `master`. Irrelevant to this flow while versions are bumped by hand; flag only if melos `version` is adopted later.
- `SURFACE_SELECTION_IMPLEMENTATION_PLAN.md` at the repo root is untracked and unrelated.

## Sources

- https://dart.dev/tools/pub/automated-publishing
- https://dart.dev/tools/pub/publishing
- https://github.com/dart-lang/setup-dart/blob/v1/.github/workflows/publish.yml
- https://github.com/dart-lang/pub-dev/blob/master/app/lib/package/backend.dart
- https://github.com/dart-lang/pub-dev/blob/master/app/lib/frontend/templates/views/pkg/admin_page.dart
- https://github.com/dart-lang/pub-dev/blob/master/pkg/_pub_shared/lib/data/package_api.dart
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- GitHub REST API: releases and tag refs of `dart-lang/setup-dart`, `actions/checkout`, `subosito/flutter-action`; repo metadata and tags of `Barba2k2/flutter_roomplan`.
