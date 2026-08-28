# Agent workflow

This file describes how an autonomous coding agent should consume the guide
without loading unnecessary context.

## Context-loading order

1. `AGENTS.md` — operating and completion contract.
2. `guide-manifest.json` — machine-readable routing and verification baseline.
3. `QUICKSTART.md` — happy path.
4. Preflight output — determines the next document.
5. One relevant specialist document at a time.

Do not load the entire troubleshooting catalog into context before a failure
occurs. Search it for the exact error signature.

## Execution states

```text
DISCOVER -> PREFLIGHT -> BOOTSTRAP -> NATIVE_BUILD -> METRO_BUNDLE -> VERIFY
                 |             |             |
                 +--> DIAGNOSE-+-------------+
```

### DISCOVER

- Resolve the target checkout and record its commit.
- Inspect dirty state without altering it.
- Confirm the user requested local execution, not cloud deployment.

### PREFLIGHT

- Run the read-only script.
- Stop on missing platform/tool failures.
- Treat placeholders as a credential decision, not a reason to fabricate data.

### BOOTSTRAP

- Use the repository’s pinned Node and pnpm versions.
- Install with the frozen lockfile.
- Build shared packages before opening Metro.
- Install pods once; retain successful artifacts.

### NATIVE_BUILD

- Apply the placeholder guard only with explicit credentials-free intent.
- Watch for `BUILD SUCCEEDED`.
- Preserve the installed app while debugging Metro.

### METRO_BUNDLE

- Confirm port 8081 before connecting the app.
- Allow the first bundle to finish.
- Record the first actionable error, not the full warning stream.

### VERIFY

- Run the verification script once to capture current evidence.
- Inspect the exact screenshot it prints after dismissing developer UI.
- Rerun with the matching `--visual-status`; exit `2` remains incomplete.
- Treat exit `0` as runtime evidence, then combine it with retained bootstrap,
  native-build, and bundle evidence; do not substitute an old installed app.
- Report credential boundaries separately from launch status.

## Escalation rules

Ask the user only when progress requires:

- private Firebase, App Check, or Privy configuration;
- downloading a large simulator runtime when disk/network policy is unclear;
- altering Apple signing or developer-team state;
- deleting material caches or user data; or
- a choice between modifying the upstream checkout and accepting a limited
  milestone.

Routine package installation, CocoaPods integration, simulator creation, local
source builds, and read-only diagnostics are normal implementation steps when
the user asked to run the app locally.

## Handoff template

Report:

- client commit and local branch;
- simulator device/runtime;
- Metro status and launch command;
- native and JavaScript verification evidence;
- exact source changes or patches applied;
- which credentials are absent and affected features;
- generated artifacts removed or preserved; and
- the shortest command for the next run.
