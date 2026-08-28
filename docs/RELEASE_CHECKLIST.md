# Release checklist

This is the finite acceptance test for publishing or refreshing this guide. It
replaces open-ended requests to “take one more look.” A release passes only when
every required item is recorded as `PASS` in [`RELEASE_STATUS.md`](../RELEASE_STATUS.md).
Unknown, untested, partially tested, and “probably works” all count as `FAIL`.

## Release identity

Record before testing:

- release ID and date;
- guide candidate commit;
- exact upstream client commit and commit date;
- macOS, Xcode, iOS runtime, Node, pnpm, and CocoaPods versions; and
- whether testing targets credential-free onboarding or a credentialed client.

Do not publish one machine’s absolute paths, usernames, tokens, plist contents,
or environment values.

## A. Repository and agent entrypoint

- `RC-01` The client and guide are visibly described as separate repositories.
- `RC-02` The documented layout and every quick-start command use the guide as
  the working directory and the client as an explicit target argument.
- `RC-03` Root `AGENTS.md` is non-empty, below Codex’s default 32 KiB combined
  project-instruction limit, and routes to the manifest and quick start.
- `RC-04` The README explains that sibling `AGENTS.md` files are not discovered
  automatically when an agent starts in the client repository.
- `RC-05` Every manifest entrypoint and progressive document exists.

## B. Static and safety checks

Run from the guide root:

```bash
python3 scripts/validate-guide.py
bash -n scripts/*.sh scripts/lib/*.sh scripts/shims/*
shellcheck -x scripts/*.sh scripts/lib/*.sh scripts/shims/*
python3 -m json.tool guide-manifest.json >/dev/null
git diff --check
```

- `RC-06` Every command exits `0`.
- `RC-07` The secret-pattern scan passes, and no credential values appear in
  tracked files, diagnostics, or release evidence.
- `RC-08` The placeholder patch passes `git apply --check` against the recorded
  upstream snapshot when the guard is absent, and refuses a credentialed plist
  or mismatched source context.

## C. Preflight matrix

Run the relevant cases without weakening failures:

- `RC-09` Supported prepared host: preflight reaches its summary and every
  blocking prerequisite is either `PASS` or deliberately repaired.
- `RC-10` Wrong Node: preflight exits `1` and prints the exact pinned version.
- `RC-11` Synced/FileProvider path: preflight warns before any dirty-state scan
  and does not hang on `git status`.
- `RC-12` Missing Watchman or `vips`: preflight warns that bootstrap installs
  the Brewfile dependency rather than deadlocking bootstrap with a failure.
- `RC-13` Port 8081 owned by another checkout or a non-Metro process: preflight
  exits `1` and reports ownership without stopping an unrelated process.

## D. Clean build and runtime

Use a clean, non-synced client checkout at the recorded upstream commit:

- `RC-14` Frozen dependency installation, shared-package build, and CocoaPods
  installation exit `0`; nested package scripts resolve the pinned pnpm through
  `scripts/shims/pnpm`, the lockfile is not rewritten, and dependency-patch
  warnings either do not occur or exactly match a recorded known limitation.
- `RC-15` The reviewed placeholder guard is applied only for credential-free
  intent and the native app is rebuilt afterward.
- `RC-16` Xcode/Expo reports a successful native build, the chosen simulator
  receives the app, and Metro prints a completed `iOS Bundled` event.
- `RC-17` `verify-ios.sh` without visual status captures a screenshot and exits
  `2`; after inspecting that screenshot, the matching explicit visual status
  exits `0`.
- `RC-18` The app process remains alive and the screenshot shows Farcaster
  onboarding or an authenticated screen—not splash, developer home, or error UI.

## E. Adversarial runtime cases

- `RC-19` Multiple booted simulators: verification exits `1`, lists UDIDs, and
  passes only when the build and verifier use the same explicit UDID.
- `RC-20` Invalid or shutdown UDID: verification exits `1`.
- `RC-21` Healthy Metro from another checkout: preflight, start, and verification
  reject it; the intended checkout passes without killing the unrelated server.
- `RC-22` A stale installed app or runtime-only exit `0` is not accepted as
  substitute evidence for the current dependency, native-build, and bundle steps.
- `RC-23` `doctor.sh` completes with bounded commands on a synced checkout,
  reports timeouts as data, identifies Metro’s working directory, and emits no
  credential values.

## F. Documentation and handoff

- `RC-24` Credential-free and fully functional milestones are distinct, with
  exact missing integrations and expected limitations documented.
- `RC-25` Exit codes `0`, `1`, and `2` have one consistent meaning in the script,
  manifest, quick start, verification contract, and agent instructions.
- `RC-26` The handoff template requires upstream commit, simulator/runtime,
  build and bundle evidence, target-source changes, credential boundary, and the
  shortest subsequent-run command.
- `RC-27` Scope exclusions and known limitations are copied into the release
  status rather than treated as untested successes.

## Release decision

The release is accepted only when `RC-01` through `RC-27` are `PASS`. An item may
be `N/A` only when the checklist itself explicitly makes it conditional; explain
why in the status record. There are no severity-based waivers for required items.

After acceptance:

1. update `RELEASE_STATUS.md` with evidence and known limitations;
2. set its state to `FROZEN`;
3. run the static checks once more;
4. commit and push the release-control changes; and
5. confirm the repository’s validation workflow passes.

## Reopen triggers

A frozen release is reopened only by one of these:

1. the upstream client commit or a declared toolchain contract changes;
2. a user or agent supplies a reproducible failure signature not covered here;
3. a security or credential-handling defect is reported;
4. the supported scope expands beyond macOS and iOS Simulator; or
5. the checklist or recorded evidence is shown to be factually wrong.

“Review it again,” stylistic preference, or speculative concern without new
evidence is not a reopen trigger. Record a valid trigger, make the smallest
targeted change, rerun the full checklist, and issue a new release status.
