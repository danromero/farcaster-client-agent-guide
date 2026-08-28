#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/verify-ios.sh CLIENT_DIR [--udid SIMULATOR_UDID] [--visual-status STATE]

STATE must be "onboarding" or "authenticated" and may be supplied only after
inspecting the screenshot captured by this command. Without it, successful
automated checks exit 2 to signal that visual confirmation is pending.

When multiple simulators are booted, --udid is required so the script does not
verify a different device from the one used for the build.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

[[ $# -gt 0 ]] || { usage; exit 1; }
CLIENT_ARG="$1"
shift
VISUAL_STATUS=""
REQUESTED_UDID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --udid)
      shift
      [[ $# -gt 0 ]] || die "--udid requires a booted simulator UDID."
      REQUESTED_UDID="$1"
      ;;
    --visual-status)
      shift
      [[ $# -gt 0 ]] || die "--visual-status requires onboarding or authenticated."
      VISUAL_STATUS="$1"
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

case "$VISUAL_STATUS" in
  ""|onboarding|authenticated) ;;
  *) die "Unsupported visual status: $VISUAL_STATUS" ;;
esac

CLIENT_DIR="$(resolve_client_dir "$CLIENT_ARG")"
assert_client_checkout "$CLIENT_DIR"

failures=0
expected_metro_cwd="$(cd "$CLIENT_DIR/apps/farcaster-mobile" && pwd -P)"

info "This script verifies the live runtime only; retain bootstrap and native-build evidence separately."

if metro_status="$(curl --fail --silent --max-time 3 http://127.0.0.1:8081/status 2>/dev/null)" && \
   [[ "$metro_status" == *"packager-status:running"* ]]; then
  pass "Metro reports packager-status:running."
  if metro_pid="$(tcp_listener_pid 8081)" && [[ -n "$metro_pid" ]]; then
    metro_cwd="$(process_cwd "$metro_pid" || true)"
    if [[ "$metro_cwd" == "$expected_metro_cwd" ]]; then
      pass "Metro belongs to the target checkout: $metro_cwd"
    else
      fail "Metro belongs to ${metro_cwd:-an unknown directory}, not $expected_metro_cwd."
      failures=$((failures + 1))
    fi
  else
    fail "Could not identify the process listening on Metro port 8081."
    failures=$((failures + 1))
  fi
else
  fail "Metro is not responding on http://127.0.0.1:8081/status."
  failures=$((failures + 1))
fi

if ! command_exists xcrun || ! command_exists python3; then
  fail "xcrun and python3 are required for simulator verification."
  exit 1
fi

BOOTED_UDIDS=()
while IFS= read -r candidate; do
  [[ -n "$candidate" ]] && BOOTED_UDIDS+=("$candidate")
done < <(booted_simulator_udids)

if [[ -n "$REQUESTED_UDID" ]]; then
  udid=""
  for candidate in "${BOOTED_UDIDS[@]}"; do
    if [[ "$candidate" == "$REQUESTED_UDID" ]]; then
      udid="$candidate"
      break
    fi
  done
  [[ -n "$udid" ]] || die "Requested simulator is not booted: $REQUESTED_UDID"
elif [[ "${#BOOTED_UDIDS[@]}" -eq 1 ]]; then
  udid="${BOOTED_UDIDS[0]}"
elif [[ "${#BOOTED_UDIDS[@]}" -gt 1 ]]; then
  fail "Multiple simulators are booted; rerun with --udid and one of:"
  printf '  %s\n' "${BOOTED_UDIDS[@]}"
  exit 1
else
  fail "No booted iOS Simulator found."
  exit 1
fi
pass "Booted simulator: $udid"

bundle_id="$(python3 - "$CLIENT_DIR/apps/farcaster-mobile/app.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle).get("expo", {}).get("ios", {}).get("bundleIdentifier", "com.farcaster.mobile-client"))
PY
)"

if app_container="$(xcrun simctl get_app_container "$udid" "$bundle_id" app 2>/dev/null)"; then
  pass "Installed app: $app_container"
  if xcrun simctl spawn "$udid" launchctl list 2>/dev/null | grep -Fq "$bundle_id"; then
    pass "App process is registered and alive for $bundle_id."
  else
    fail "Bundle $bundle_id is installed but its app process is not alive."
    failures=$((failures + 1))
  fi
else
  fail "Bundle $bundle_id is not installed on the booted simulator."
  failures=$((failures + 1))
fi

temp_root="${TMPDIR:-/tmp}"
screenshot_path="${temp_root%/}/farcaster-verification-${udid}.png"
if xcrun simctl io "$udid" screenshot "$screenshot_path" >/dev/null 2>&1; then
  pass "Captured visual evidence: $screenshot_path"
else
  fail "Could not capture the required simulator screenshot."
  failures=$((failures + 1))
fi

if contains_placeholder "$CLIENT_DIR/apps/farcaster-mobile/ios/Farcaster/GoogleService-Info.plist"; then
  warn "Firebase plist is still a placeholder; verify only the credential-free milestone."
fi
if contains_placeholder "$CLIENT_DIR/apps/farcaster-mobile/src/constants/Privy.ts"; then
  warn "Privy IDs are placeholders; wallet initialization warnings are expected."
fi

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi

if [[ -z "$VISUAL_STATUS" ]]; then
  printf '\nVisual confirmation pending. Inspect %s after dismissing any Expo developer UI.\n' "$screenshot_path"
  printf 'Then rerun with --visual-status onboarding or --visual-status authenticated.\n'
  exit 2
fi

pass "Visual state explicitly confirmed: $VISUAL_STATUS."
