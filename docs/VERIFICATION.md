# Verification contract

An agent should not report “running” until it can support each required
checkpoint with recent evidence.

`verify-ios.sh` checks the live runtime. It deliberately does not claim that a
dependency install, package build, pod install, or native build happened in the
current session. Its exit `0` is necessary but not sufficient unless the agent
also retained those earlier checkpoints.

## Required checkpoints

### 1. Repository and dependency state

- The target path is the intended `farcasterxyz/client` checkout.
- `corepack pnpm install --frozen-lockfile` exited zero.
- `corepack pnpm --filter './packages/**' build` exited zero.
- `pod install` exited zero.

### 2. Native application

- Xcode printed `BUILD SUCCEEDED` or Expo reported a successful iOS build.
- The simulator contains bundle ID `com.farcaster.mobile-client`, unless the
  target snapshot has deliberately changed it.
- The app process is present after launch and does not immediately terminate.

### 3. Metro

```bash
curl --fail --silent http://127.0.0.1:8081/status
```

must return:

```text
packager-status:running
```

Metro must also print a completed iOS bundle. A QR code or “Waiting on” line is
not enough.

### 4. Rendered application

The simulator visibly shows one of:

- Farcaster onboarding with `Create account` and `Sign in`; or
- an authenticated Farcaster screen.

The following are not completion:

- the Expo development-client server list;
- a permanent splash screen;
- a blank screen;
- the developer menu covering an unknown underlying state;
- a red JavaScript error overlay; or
- an app that has crashed back to the home screen.

### 5. Credential boundary reported

The handoff must say whether real Firebase/App Check and Privy configuration was
present. If not, state that onboarding launches but protected and wallet-backed
features are not expected to work.

## Verification commands

Run:

```bash
./scripts/verify-ios.sh /path/to/client
```

With multiple booted simulators, the script refuses to guess. Select the same
device used for the build with `--udid SIMULATOR_UDID`.

This intentionally exits `2` after capturing a screenshot. Inspect the exact
image it reports, then rerun with the state actually visible:

```bash
./scripts/verify-ios.sh /path/to/client --visual-status onboarding
# or
./scripts/verify-ios.sh /path/to/client --visual-status authenticated
```

The exit-code contract is:

| Code | Meaning |
| --- | --- |
| `0` | Live runtime checks passed and a valid visual state was explicitly confirmed; earlier build evidence is still required. |
| `1` | One or more automated checks failed. |
| `2` | Automated checks passed, but visual confirmation is still required. |

For visual evidence independent of UI automation:

```bash
UDID="$(xcrun simctl list devices booted -j | python3 -c \
  'import json,sys; d=json.load(sys.stdin)["devices"]; print(next(x["udid"] for xs in d.values() for x in xs))')"
xcrun simctl io "$UDID" screenshot /tmp/farcaster-ios.png
```

For focused recent native errors:

```bash
xcrun simctl spawn "$UDID" log show --last 2m --style compact \
  --predicate 'process == "Farcaster" AND (messageType == error OR messageType == fault)'
```

Do not treat every simulator subsystem warning as an app failure. Correlate the
timestamp, process, JavaScript logs, and visible screen.
