# Agent instructions

## Purpose

This repository is an execution guide for a separate checkout of
`farcasterxyz/client`. Do not mistake this repository for the application.

Default objective: get the specified public client checkout to visible
Farcaster onboarding in an iOS Simulator on macOS, then provide evidence tying
that screen to the current checkout and build. Do not expand the task into
production credentials, authenticated features, Android, or release engineering
unless the user explicitly requests that broader scope.

## Invocation model

- Start the agent from this guide repository so these instructions are loaded.
- Treat the client as a sibling target repository, normally `../client`.
- If the agent started from the client repository, it must explicitly read this
  file; sibling-repository instructions are not discovered automatically.
- Paths in guide commands are relative to this guide repository unless stated
  otherwise.

## Required workflow

1. Resolve the target client directory from the user's instruction, the first
   script argument, or `FARCASTER_CLIENT_DIR`.
2. Read `guide-manifest.json` and `docs/QUICKSTART.md`.
3. Run `./scripts/preflight.sh <client-dir>` before changing either repository.
4. Load only the documentation routed by the preflight result:
   - setup details: `docs/IOS_SIMULATOR.md`
   - placeholders or authentication: `docs/CREDENTIALS.md`
   - a matching error signature: `docs/TROUBLESHOOTING.md`
5. Prefer the provided scripts. Review an opt-in patch before applying it.
6. Run `./scripts/verify-ios.sh <client-dir>`. Inspect the exact screenshot path
   it prints, then rerun with `--visual-status onboarding` or
   `--visual-status authenticated`. Exit `0` proves the live runtime checks but
   is not sufficient by itself: also retain successful bootstrap, native-build,
   and iOS bundle evidence from the current target checkout. Exit `2` means
   visual confirmation is still pending.

## Safety

- Never add real credentials to this guide or the client checkout.
- Never print `.env`, plist, JSON credential contents, tokens, or keychain data.
- Do not replace `REPLACE_ME` values with fabricated strings.
- Do not push, fork, create cloud resources, or alter signing unless the user
  explicitly requests it.
- Preserve unrelated changes in the target checkout.
- Treat generated `Pods/`, DerivedData, and Metro caches as disposable, but do
  not delete them without first identifying the exact target and need.

## Source-change policy

The default path is diagnostic and non-mutating. The only bundled target-source
change is the credentials-free Firebase launch guard. Apply it only when:

- the user wants the credential-free onboarding milestone;
- the public plist still contains placeholders;
- preflight confirms the current AppDelegate does not already guard them; and
- `scripts/apply-placeholder-guard.sh` passes its version/context check.

If the patch no longer applies, inspect the current upstream implementation and
update this guide rather than forcing it.

## Completion contract

“Running” means all of the following are evidenced:

- dependencies and shared packages built successfully;
- CocoaPods installation and native simulator build succeeded;
- the app process remains alive;
- Metro reports `packager-status:running`;
- an iOS JavaScript bundle completes; and
- the simulator renders Farcaster onboarding or an authenticated screen.

Credential warnings alone do not invalidate launch success. A blank splash,
development-client home screen, red error overlay, or crashed process is not
completion.

## Changes to this guide

Read `RELEASE_STATUS.md` before proposing guide changes. When its state is
`FROZEN`, do not perform open-ended polish or another speculative review. Reopen
only for a trigger listed in `docs/RELEASE_CHECKLIST.md`, record that trigger,
and rerun the complete finite checklist before freezing a new release.

Run these before committing:

```bash
python3 scripts/validate-guide.py
bash -n scripts/*.sh scripts/lib/*.sh scripts/shims/*
shellcheck -x scripts/*.sh scripts/lib/*.sh scripts/shims/*
```

Keep root instructions concise. Put explanations and failure catalogs in
`docs/` so agents can load them progressively.
