#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/preflight.sh /path/to/farcaster-client

Runs read-only checks for the macOS/iOS Simulator setup path.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

CLIENT_DIR="$(resolve_client_dir "${1:-}")"
assert_client_checkout "$CLIENT_DIR"

failures=0
warnings=0
sync_risk=0

check_pass() { pass "$@"; }
check_warn() { warnings=$((warnings + 1)); warn "$@"; }
check_fail() { failures=$((failures + 1)); fail "$@"; }

info "Target: $CLIENT_DIR"

if [[ "$CLIENT_DIR" == *" "* ]]; then
  check_warn "Checkout path contains spaces; generated CocoaPods phases may misquote it."
fi

case "$CLIENT_DIR" in
  "$HOME/Documents"/*|"$HOME/Desktop"/*|*"/Mobile Documents/"*)
    sync_risk=1
    check_warn "Checkout may be FileProvider/iCloud-backed; prefer a plain local path such as ~/Developer/client."
    ;;
esac

if git -C "$CLIENT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit="$(git -C "$CLIENT_DIR" rev-parse --short=12 HEAD 2>/dev/null || true)"
  check_pass "Git checkout detected at ${commit:-unknown commit}."
  if [[ "$sync_risk" -eq 1 ]]; then
    check_warn "Skipped the dirty-state scan because git status can stall in a synced checkout; preserve any existing work."
  else
    dirty_count="$(git -C "$CLIENT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "$dirty_count" -gt 0 ]]; then
      check_warn "Target checkout has $dirty_count changed path(s); preserve unrelated work."
    fi
  fi
else
  check_warn "Target is not a Git checkout; patch/version checks will be limited."
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  check_pass "Host is macOS."
else
  check_fail "The verified iOS Simulator path requires macOS."
fi

available_kb="$(df -Pk "$CLIENT_DIR" 2>/dev/null | awk 'NR==2 {print $4}')"
if [[ "$available_kb" =~ ^[0-9]+$ ]]; then
  available_gb=$((available_kb / 1024 / 1024))
  if [[ "$available_gb" -lt 12 ]]; then
    check_fail "Only ${available_gb} GB free; a clean iOS setup can require 20 GB or more."
  elif [[ "$available_gb" -lt 20 ]]; then
    check_warn "${available_gb} GB free; clean simulator and Xcode builds may exhaust it."
  else
    check_pass "${available_gb} GB free."
  fi
fi

for required in git node corepack brew pod python3 xcodebuild xcrun curl lsof; do
  if command_exists "$required"; then
    check_pass "$required is available."
  else
    check_fail "$required is missing."
  fi
done

for brew_dependency in watchman vips; do
  if command_exists "$brew_dependency"; then
    check_pass "$brew_dependency is available."
  else
    check_warn "$brew_dependency is missing; bootstrap will install it from the target Brewfile."
  fi
done

expected_node="$(recommended_node_version "$CLIENT_DIR")"
if command_exists node && [[ -n "$expected_node" ]]; then
  actual_node="$(node --version 2>/dev/null || true)"
  if [[ "$actual_node" == "$expected_node" ]]; then
    check_pass "Node matches .node-version ($expected_node)."
  else
    check_fail "Node is ${actual_node:-unknown}; activate the target's required .node-version ($expected_node)."
  fi
fi

expected_pm="$(root_package_manager "$CLIENT_DIR")"
if command_exists corepack; then
  check_pass "Target declares ${expected_pm:-no packageManager}; bootstrap will let Corepack resolve it."
fi

if command_exists xcode-select && developer_dir="$(xcode-select -p 2>/dev/null)"; then
  check_pass "Selected developer directory: $developer_dir"
else
  check_fail "No active Xcode developer directory."
fi

if command_exists xcrun && command_exists python3; then
  runtime_count="$(xcrun simctl list runtimes -j 2>/dev/null | python3 -c '
import json, sys
try:
    runtimes = json.load(sys.stdin).get("runtimes", [])
except Exception:
    print(0); raise SystemExit
print(sum(1 for r in runtimes if r.get("isAvailable") and "iOS" in r.get("name", "")))
' 2>/dev/null || printf '0')"
  if [[ "$runtime_count" -gt 0 ]]; then
    check_pass "$runtime_count available iOS Simulator runtime(s)."
  else
    check_fail "No available iOS Simulator runtime for the selected Xcode."
  fi
fi

if metro_pid="$(tcp_listener_pid 8081)" && [[ -n "$metro_pid" ]]; then
  metro_cwd="$(process_cwd "$metro_pid" || true)"
  expected_metro_cwd="$(cd "$CLIENT_DIR/apps/farcaster-mobile" && pwd -P)"
  if curl --fail --silent --max-time 2 http://127.0.0.1:8081/status 2>/dev/null | grep -q 'packager-status:running'; then
    if [[ "$metro_cwd" == "$expected_metro_cwd" ]]; then
      check_warn "Port 8081 already has Metro for this checkout: $metro_cwd"
    else
      check_fail "Port 8081 has Metro for another checkout (${metro_cwd:-unknown cwd}); stop it before starting this client."
    fi
  else
    check_fail "Port 8081 is occupied by a process that is not responding as Metro."
  fi
else
  check_pass "Metro port 8081 is free."
fi

plist="$CLIENT_DIR/apps/farcaster-mobile/ios/Farcaster/GoogleService-Info.plist"
app_delegate="$CLIENT_DIR/apps/farcaster-mobile/ios/Farcaster/AppDelegate.swift"
if contains_placeholder "$plist"; then
  check_warn "Firebase iOS plist contains public placeholders."
  if grep -q 'googleAppID != "REPLACE_ME"' "$app_delegate" 2>/dev/null; then
    check_pass "AppDelegate skips placeholder Firebase configuration."
  else
    check_warn "AppDelegate appears to configure the placeholder plist; credential-free launch needs the reviewed guard."
  fi
else
  check_pass "Firebase iOS plist does not contain REPLACE_ME."
fi

privy_file="$CLIENT_DIR/apps/farcaster-mobile/src/constants/Privy.ts"
if contains_placeholder "$privy_file"; then
  check_warn "Privy IDs are placeholders; embedded-wallet features will not initialize."
fi

printf '\nSummary: %d failure(s), %d warning(s).\n' "$failures" "$warnings"
if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
