# iOS Simulator runbook

## Supported path

- Host: macOS
- Target: iOS Simulator
- Package manager: the exact pnpm version in the target root `packageManager`
- Node: the target root `.node-version`
- Native project: `apps/farcaster-mobile/ios/Farcaster.xcworkspace`

Do not substitute globally installed Node or pnpm versions when the repository
declares them.

## Phase 0: repository and path

Clone the public snapshot; a GitHub fork is unnecessary:

```bash
git clone https://github.com/farcasterxyz/client.git
```

Use a path without spaces and outside folders synchronized by iCloud, Dropbox,
OneDrive, or another FileProvider. A path such as `~/Developer/client` avoids
two classes of nondeterministic failure before setup begins.

Record the upstream commit:

```bash
git -C /path/to/client rev-parse HEAD
```

The upstream repository is an automatically replaced snapshot. A later clone
may not match the commit against which this guide was verified.

## Phase 1: host tools

The target Brewfile currently installs Watchman and `vips`. The native build
also requires Xcode, an iOS Simulator runtime, Ruby, and CocoaPods.

```bash
cd /path/to/client
brew bundle
xcodebuild -version
xcrun simctl list runtimes
pod --version
```

Important checks:

- Open Xcode at least once and accept the license.
- `xcode-select -p` should point at the intended Xcode installation.
- At least one available iOS runtime must appear in `simctl list runtimes`.
- The runtime must be supported by the selected Xcode. Install it from Xcode’s
  Settings > Components when none is available.
- Keep roughly 20 GB free before a clean build; simulator runtimes and
  DerivedData are large.

If `pod` is absent, install CocoaPods before rerunning preflight (for example,
`brew install cocoapods`). If Node differs from `.node-version`, activate that
exact version with the machine's existing Node version manager; Corepack pins
pnpm, not Node itself.

The simulator does not require an Apple Developer team or code-signing identity.

## Phase 2: JavaScript dependencies

Use Corepack to dispatch to the pnpm version in `package.json`:

```bash
cd /path/to/client
corepack pnpm install --frozen-lockfile
corepack pnpm --filter './packages/**' build
```

The provided bootstrap also prepends `scripts/shims/pnpm` so nested package
scripts that invoke plain `pnpm` cannot accidentally resolve a different global
version. Prefer the bootstrap script when the machine has a global pnpm.

Why build shared packages explicitly: the mobile app imports workspace package
outputs. A native build may succeed while Metro later fails on missing or stale
`dist` files if this phase is skipped.

Expected checkpoints:

- installation exits zero;
- the lockfile is not rewritten;
- patch warnings are absent or match the documented `cipher-base` limitation
  in [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md); and
- every package build exits zero.

Use `pnpm watch` only after the first successful build and only when editing
shared packages. It is not required to prove the app launches.

## Phase 3: CocoaPods

```bash
cd /path/to/client/apps/farcaster-mobile/ios
pod install
```

Open and build the `.xcworkspace`, never the `.xcodeproj`. CocoaPods generates
the workspace integration and build phases.

Checkpoint: `pod install` ends with a successful integration message and
`Farcaster.xcworkspace` exists.

## Phase 4: public-snapshot placeholders

Run preflight again. If the committed Firebase plist still contains
`REPLACE_ME` and `AppDelegate.swift` configures it unconditionally, the app can
build and then abort at launch.

For a credentials-free UI milestone, review and apply the bundled guard:

```bash
cd /path/to/farcaster-client-agent-guide
./scripts/apply-placeholder-guard.sh /path/to/client
```

This requires another native build. It intentionally disables Firebase and
App Check initialization when the plist is a placeholder. It does not provide
authentication, wallet, telemetry, or production API integrity credentials.

## Phase 5: native build

```bash
cd /path/to/farcaster-client-agent-guide
./scripts/start-ios.sh /path/to/client --build
```

Run this in a terminal that can remain in the foreground. The command normally
keeps Metro alive after building; use a second terminal for status checks and
verification rather than waiting for the first prompt to return.

Equivalent direct command:

```bash
cd /path/to/client/apps/farcaster-mobile
corepack pnpm exec expo run:ios -d
```

Select an installed simulator. The first build can take many minutes. A native
rebuild is needed after changes to Swift, pods, native dependencies, Expo SDK,
app configuration, or plist/entitlement files.

When multiple simulators are booted, use a UDID so build and verification target
the same one:

```bash
./scripts/start-ios.sh /path/to/client --build --device SIMULATOR_UDID
./scripts/verify-ios.sh /path/to/client --udid SIMULATOR_UDID
```

Checkpoint: Xcode reports `BUILD SUCCEEDED`, the app is installed, and the app
process stays alive.

## Phase 6: Metro and development-client connection

The build command normally starts Metro. If starting it separately:

```bash
./scripts/start-ios.sh /path/to/client --metro-only --host lan
```

Confirm Metro before interacting with the development client:

```bash
curl --fail --silent http://127.0.0.1:8081/status
```

Expected response:

```text
packager-status:running
```

The Expo development client may advertise a LAN URL or require manual entry.
Do not assume a displayed server entry proves port 8081 is still listening.

The first JavaScript bundle is large. Watch Metro until it prints `iOS Bundled`.
Restarting near completion discards useful work.

## Phase 7: visual completion

Dismiss Expo’s first-run development tips and developer menu. The actual app
should show Farcaster’s purple onboarding screen with `Create account` and
`Sign in`, or an authenticated screen.

From the guide repository in a second terminal, capture and inspect the current
screen, then record the state you actually observed:

```bash
./scripts/verify-ios.sh /path/to/client
./scripts/verify-ios.sh /path/to/client --visual-status onboarding
```

Use `--visual-status authenticated` instead only when the screenshot visibly
shows a signed-in screen. The first command exits `2` by design; only the
confirmed command may exit `0`.

Run the verification script and use [`VERIFICATION.md`](VERIFICATION.md) for the
evidence contract.

## Subsequent runs

- JavaScript-only changes: keep Metro running; Fast Refresh should update.
- Shared package changes: run `corepack pnpm watch` at the workspace root.
- Native changes: rerun `--build`.
- Changed pods: rerun `pod install`, then rebuild.
- Corrupt Metro cache: use `--clear` once; do not clear it routinely.
