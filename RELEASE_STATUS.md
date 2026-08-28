# Release status

- **Release ID:** `ios-simulator-guide-2026-08-28`
- **State:** `FROZEN`
- **Accepted:** August 28, 2026
- **Guide candidate reviewed:** `2a73014cb59035e6aac491da9141e87ed1c0cfb5`
- **Release-control baseline:** the commit containing this status file
- **Upstream client:** `b6922e24036cac6f5e6d51904a59ff7cfcdd8483`
- **Milestone:** credential-free Farcaster onboarding in iOS Simulator

This record applies the finite [`release checklist`](docs/RELEASE_CHECKLIST.md).
The guide is frozen at this baseline. Maintenance resumes only for a listed
reopen trigger, not for another unbounded review pass.

## Acceptance results

| IDs | Result | Evidence |
| --- | --- | --- |
| `RC-01`–`RC-05` | PASS | Separate-repository layout, root instructions, manifest routing, and local links were reviewed; `AGENTS.md` is approximately 3.5 KiB. |
| `RC-06`–`RC-08` | PASS | Guide validator, Bash parser, ShellCheck, JSON parser, diff check, secret scan, and guarded patch behavior passed. |
| `RC-09`–`RC-13` | PASS | Prepared-host, wrong-Node, FileProvider timeout avoidance, bootstrap-installed Brew dependencies, and foreign-Metro ownership paths were exercised. |
| `RC-14`–`RC-18` | PASS | Frozen install, shared packages, pods, native build, completed iOS bundle, live app process, screenshot, exit `2`, and confirmed onboarding exit `0` succeeded against the recorded snapshot. |
| `RC-19`–`RC-23` | PASS | Multiple, explicit, and invalid simulator cases; wrong-checkout Metro rejection; correct-checkout acceptance; runtime-proof boundary; and bounded doctor output were exercised. |
| `RC-24`–`RC-27` | PASS | Credential boundary, exit-code consistency, handoff fields, scope, and limitations are explicit in tracked documentation and the manifest. |

The repository validation workflow must also be green on the release-control
commit. Its durable entrypoint is [`.github/workflows/validate.yml`](.github/workflows/validate.yml).

## Recorded environment

The acceptance run used:

- macOS with Xcode 26.6;
- iOS Simulator runtime 26.5;
- the target’s Node `v20.19.5` and pnpm `10.8.1` contract;
- CocoaPods 1.17.0; and
- bundle ID `com.farcaster.mobile-client`.

Machine-specific absolute paths and ephemeral screenshot/build-log locations are
intentionally omitted. The upstream commit and observable command outcomes are
the portable evidence identifiers.

## Known limitations

- Only macOS and iOS Simulator are supported. Android, physical devices,
  signing, releases, EAS/cloud builds, and backend development are unverified.
- The client repository is an automatically replaced public snapshot. A new
  upstream commit requires a new release, even if scripts still appear to work.
- Credential-free onboarding does not prove sign-in, Firebase/App Check,
  Privy wallets, Alchemy-backed behavior, notifications, telemetry, or other
  protected production integrations.
- Runtime verification proves Metro ownership, the simulator process, and the
  visible screen. It cannot reconstruct dependency, CocoaPods, native-build, or
  bundle evidence from an earlier terminal session.
- Metro ownership relies on macOS `lsof`, port 8081, and the listener process’s
  working directory. A future Expo architecture that proxies or relocates Metro
  requires revalidation.
- Visual state is explicitly asserted after screenshot inspection; the script
  does not perform semantic image recognition itself.
- FileProvider detection is path-based and conservative. Unusual synchronized
  folders outside the recognized locations may require human diagnosis.
- The Firebase placeholder patch is snapshot-specific and intentionally refuses
  changed source context rather than attempting a fuzzy application.
- At the recorded upstream commit, pnpm 10.8.1 warns that
  `patches/cipher-base.patch` cannot be applied to `cipher-base@1.0.7` but exits
  `0`. Credential-free onboarding was verified with that dependency unpatched;
  credentialed or cryptographic behavior is not covered by this acceptance.

## Freeze policy

Do not modify the frozen guide for open-ended polish. Reopen it only when:

1. upstream or a declared toolchain changes;
2. a reproducible uncovered failure is supplied;
3. a security or credential-handling issue is found;
4. supported scope is intentionally expanded; or
5. this checklist or evidence record is demonstrably inaccurate.

When reopened, change the state to `REOPENED`, record the trigger, create a new
release ID, rerun all `RC-01`–`RC-27` items, and freeze only after every required
item passes again.
