#!/usr/bin/env bash

GUIDE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
export GUIDE_ROOT

color_enabled() {
  [[ -t 1 && -z "${NO_COLOR:-}" ]]
}

print_label() {
  local label="$1"
  local color="$2"
  shift 2
  if color_enabled; then
    printf '\033[%sm%s\033[0m %s\n' "$color" "$label" "$*"
  else
    printf '%s %s\n' "$label" "$*"
  fi
}

info() { print_label "INFO" "36" "$@"; }
pass() { print_label "PASS" "32" "$@"; }
warn() { print_label "WARN" "33" "$@"; }
fail() { print_label "FAIL" "31" "$@"; }

die() {
  fail "$@"
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

resolve_client_dir() {
  local requested="${1:-${FARCASTER_CLIENT_DIR:-}}"
  [[ -n "$requested" ]] || die "Pass the Farcaster client directory or set FARCASTER_CLIENT_DIR."
  [[ -d "$requested" ]] || die "Client directory does not exist: $requested"
  (cd "$requested" && pwd -P)
}

assert_client_checkout() {
  local client_dir="$1"
  [[ -f "$client_dir/package.json" ]] || die "Missing root package.json in $client_dir"
  [[ -f "$client_dir/apps/farcaster-mobile/package.json" ]] || \
    die "Missing apps/farcaster-mobile/package.json in $client_dir"
  [[ -d "$client_dir/apps/farcaster-mobile/ios" ]] || \
    die "Missing committed iOS project in $client_dir"
}

pnpm_command() {
  if command_exists corepack; then
    printf '%s\n' "corepack pnpm"
  elif command_exists pnpm; then
    printf '%s\n' "pnpm"
  else
    return 1
  fi
}

root_package_manager() {
  local client_dir="$1"
  sed -nE 's/.*"packageManager"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' \
    "$client_dir/package.json" | head -n 1
}

recommended_node_version() {
  local client_dir="$1"
  if [[ -f "$client_dir/.node-version" ]]; then
    tr -d '[:space:]' < "$client_dir/.node-version"
  fi
}

contains_placeholder() {
  local path="$1"
  [[ -f "$path" ]] && grep -q 'REPLACE_ME' "$path"
}

tcp_listener_pid() {
  local port="$1"
  command_exists lsof || return 1
  lsof -nP -t "-iTCP:${port}" -sTCP:LISTEN 2>/dev/null | sed -n '1p'
}

process_cwd() {
  local pid="$1"
  command_exists lsof || return 1
  lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'
}

booted_simulator_udids() {
  xcrun simctl list devices booted -j 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin).get("devices", {})
for devices in data.values():
    for device in devices:
        if device.get("state") == "Booted":
            print(device["udid"])
' 2>/dev/null
}
