# Quick start

This path targets a fresh public checkout on macOS and an iOS Simulator. Budget
at least 20 GB of free disk space for JavaScript dependencies, CocoaPods, the
simulator runtime, and Xcode build products.

The expected result is the Farcaster onboarding screen backed by the checkout
you just built. Missing-credential warnings are expected at this milestone;
sign-in and protected integrations are not part of this quick start.

## 1. Choose a safe checkout location

Use a local, non-synced path without spaces, for example:

```bash
mkdir -p "$HOME/Developer"
cd "$HOME/Developer"
git clone https://github.com/farcasterxyz/client.git
git clone https://github.com/danromero/farcaster-client-agent-guide.git
```

Avoid iCloud/FileProvider-backed folders. They can make Node or Watchman return
partial reads, stalls, and misleading JavaScript parse errors. Paths containing
spaces can also expose quoting bugs in generated CocoaPods build phases.

## 2. Inspect the machine and checkout

```bash
cd "$HOME/Developer/farcaster-client-agent-guide"
./scripts/preflight.sh ../client
```

Resolve every `FAIL` before continuing. `WARN` items identify conditions that
bootstrap will repair, optional integrations, or risky environmental
conditions. In particular, missing Watchman or `vips` is expected to be repaired
by the next step's `brew bundle`.

Common first-machine fixes:

- If Homebrew is missing, install it from [brew.sh](https://brew.sh), open a new
  shell, and verify `brew --version` before rerunning preflight.
- If Node does not match the target's `.node-version`, use the Node version
  manager already installed on the machine. For example, run
  `nvm install "$(cat ../client/.node-version)"` followed by
  `nvm use "$(cat ../client/.node-version)"`, or use the equivalent `fnm`
  commands. Do not install a second version manager merely because these
  examples name one. If none is installed, choose one version manager and
  follow its official installation instructions.
- If `pod` is missing and Homebrew is available, run `brew install cocoapods`,
  then confirm `pod --version` succeeds.
- If Xcode, its command-line tools, or an iOS runtime is missing, install/select
  them in Xcode, open Xcode once, accept the license, and rerun preflight.

Do not continue in the same shell after switching Node until `node --version`
exactly matches `.node-version` and a new preflight exits `0`.

## 3. Install and prepare

```bash
./scripts/bootstrap-ios.sh ../client --apply-placeholder-guard
```

This performs the stable first-run work:

1. installs the Brewfile dependencies;
2. activates the pnpm version declared by the client;
3. installs the frozen JavaScript dependency graph;
4. builds shared workspace packages; and
5. installs CocoaPods.

The optional guard prevents placeholder Firebase configuration from crashing
the public snapshot. Review [`CREDENTIALS.md`](CREDENTIALS.md) before applying
it in a credentialed environment.

## 4. Build and launch

Open Xcode once, accept its license, and ensure an iOS Simulator runtime is
installed. Then, in terminal A:

```bash
./scripts/start-ios.sh ../client --build
```

Select a simulator if Expo prompts. The first native build and first Metro
bundle are expensive; do not restart them merely because the splash screen is
still visible. Leave this terminal running while Metro serves the app. Open a
second terminal for verification; do not wait for terminal A to return to a
shell prompt.

For later JavaScript-only runs:

```bash
./scripts/start-ios.sh ../client --metro-only --host lan
```

Use `--host localhost` only when the simulator can reach the host loopback
reliably. LAN mode is the safer default for a development client.

## 5. Verify in terminal B

```bash
./scripts/verify-ios.sh ../client
```

If more than one simulator is booted, the script stops rather than guessing.
List them with `xcrun simctl list devices booted`, then repeat both the build and
verification with the same UDID:

```bash
./scripts/start-ios.sh ../client --build --device SIMULATOR_UDID
./scripts/verify-ios.sh ../client --udid SIMULATOR_UDID
```

The command captures a screenshot and exits `2` because visual inspection is a
required checkpoint. Open the exact image path it prints. Success is Farcaster
onboarding or an authenticated screen—not merely the Expo development-client
home screen. After inspection, record the observed state explicitly:

```bash
./scripts/verify-ios.sh ../client --visual-status onboarding
# Or, if visibly signed in:
./scripts/verify-ios.sh ../client --visual-status authenticated
```

Exit `0` means all automated checks and the explicit visual checkpoint passed.
Exit `1` means an automated check failed; exit `2` means the visual checkpoint
is still pending. Expected credential warnings are cataloged in
[`CREDENTIALS.md`](CREDENTIALS.md).

This is runtime verification, not a substitute for the earlier checkpoints.
Before reporting completion, retain the successful dependency, package-build,
CocoaPods, native-build, and `iOS Bundled` output from the current checkout.
The verifier rejects a Metro listener whose working directory belongs to a
different checkout, but it cannot recreate terminal evidence that has scrolled
away.

If a step fails, capture focused diagnostics:

```bash
./scripts/doctor.sh ../client
```

Then match the signature in [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).
