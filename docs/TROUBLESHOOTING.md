# Troubleshooting catalog

Start with the exact symptom. Run `scripts/doctor.sh` before clearing caches or
changing source.

## Node reports impossible JavaScript errors

Examples:

```text
Unexpected end of JSON input
... is not a function
SyntaxError in a dependency that is known to be valid
```

Likely cause: the checkout is in an iCloud/FileProvider-backed directory and
asynchronous reads are returning incomplete contents.

Diagnosis:

- compare repeated checksums or byte counts for the reported file;
- inspect the checkout path;
- clone the same commit into a plain local directory and retry there.

Remedy: use a fresh checkout under a path such as `~/Developer/client`. Warming
files or repeatedly reinstalling dependencies is not a reliable fix.

## pnpm cannot apply `patches/cipher-base.patch`

On upstream commit `b6922e24036cac6f5e6d51904a59ff7cfcdd8483`, pnpm 10.8.1 can
warn that `patches/cipher-base.patch` does not match the installed
`cipher-base@1.0.7` source while still exiting `0`. The credential-free
onboarding release was built and verified with that dependency unpatched.

This is a recorded limitation, not a general instruction to ignore patch
failures. Confirm the exact upstream commit, dependency version, warning path,
and successful install exit before continuing. Treat a different patch warning,
a nonzero install, or any credentialed/cryptographic behavior as unverified and
reopen the guide rather than deleting or rewriting the upstream patch.

## Watchman hangs or Metro never starts

Diagnosis:

```bash
watchman version
watchman watch-list
curl --max-time 3 http://127.0.0.1:8081/status
```

Remedies, in order:

1. move the checkout out of a synchronized directory;
2. ensure the repository is readable and stable;
3. restart Watchman for this project only;
4. as a fallback, set `config.resolver.useWatchman = false` in Metro config and
   accept the slower built-in crawler.

Disabling Watchman should not be the default workaround for an unhealthy
filesystem.

## CocoaPods or Expo build phases break at a path segment

Symptoms reference a truncated path, `No such file or directory`, or an Expo
script path ending before a space.

Likely cause: the checkout path contains spaces and a generated shell phase
does not quote a path correctly.

Remedy: move or reclone into a path without spaces, reinstall pods, and rebuild.
Editing `Pods.xcodeproj` is generated, fragile, and should be a last-resort
diagnostic—not the documented happy path.

## No compatible iOS Simulator runtime

Symptoms:

```text
Unable to find a destination
runtime is not available
Ineligible destinations
```

Diagnosis:

```bash
xcodebuild -version
xcode-select -p
xcrun simctl list runtimes
xcrun simctl list devices available
```

Remedy: select the intended Xcode and install an iOS runtime from Xcode Settings
> Components. Do not download a runtime for a different Xcode major version.

## Build succeeds, app crashes immediately in Firebase

Symptoms mention invalid `GOOGLE_APP_ID`, invalid API key, or Firebase configure
exceptions. The committed plist contains `REPLACE_ME`.

Remedies:

- for a fully functional client, obtain the correct plist; or
- for credential-free onboarding, apply `scripts/apply-placeholder-guard.sh`
  and rebuild the native app.

Do not initialize Firebase with fabricated values.

## Development client says it cannot connect

First verify the server from the host:

```bash
curl --fail --silent http://127.0.0.1:8081/status
lsof -nP -iTCP:8081 -sTCP:LISTEN
```

If nothing is listening, restart Metro. A stale Expo terminal process may exist
without an active HTTP listener.

Prefer:

```bash
./scripts/start-ios.sh /path/to/client --metro-only --host lan
```

If LAN discovery fails, manually enter the URL shown by Expo. If a VPN or
Cloudflare WARP is active, disable it temporarily and retry.

## Metro belongs to another checkout

`verify-ios.sh` compares the port 8081 listener's working directory with the
target mobile directory. If they differ, a healthy status response is stale or
belongs to another project. Preserve the reported path, stop that exact Metro
process from its owning terminal, then start Metro from the intended checkout.
Do not accept `packager-status:running` alone as proof of ownership.

## Metro appears frozen during the first bundle

The mobile bundle contains thousands of modules. Watch the transformed-module
count for forward progress. Do not restart while it is increasing. Completion
is the `iOS Bundled` line, not a particular percentage.

## Onboarding appears with Firebase or Privy errors

If the process remains alive and the onboarding buttons render, the build and
launch milestone succeeded. Read [`CREDENTIALS.md`](CREDENTIALS.md). The public
snapshot lacks the configuration needed for integrity-protected and wallet
features.

## `Secondary Privy client init failed`

The primary and secondary Privy IDs are placeholders in the public snapshot.
This error is not resolved by reinstalling pods, clearing Metro, or changing a
simulator. Obtain the corresponding Privy project IDs or accept the
credential-free UI boundary.

## Disk fills during the native build

Diagnosis:

```bash
df -h .
du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null
du -sh "$HOME/Library/Developer/CoreSimulator" 2>/dev/null
```

Safe recovery requires exact targets. Remove only generated DerivedData for the
known project or unused simulator runtimes through Xcode. Preserve the built
`.app` first if you want to avoid another full native build.

## Expo warns that no shared URI scheme was found

This can prevent automatic QR/terminal launching while manual development-client
connection still works. Confirm the actual scheme in the target’s Expo config
and installed app. Do not run `expo prebuild` automatically against a committed
native project; it can rewrite many files.

## When to clear caches

Clear only the layer implicated by evidence:

- Metro transform corruption: start Expo once with `--clear`.
- Changed pods or Podfile: rerun `pod install`.
- Native build graph corruption: remove the specific project’s DerivedData.
- Dependency graph mismatch: reinstall using the frozen lockfile.

Deleting all caches at once destroys diagnostic evidence and repeats the most
expensive work.
