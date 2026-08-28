#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: ./scripts/doctor.sh /path/to/farcaster-client"
  exit 0
fi

CLIENT_DIR="$(resolve_client_dir "${1:-}")"
assert_client_checkout "$CLIENT_DIR"

section() { printf '\n## %s\n' "$1"; }
show_command() {
  local label="$1"
  shift
  printf '%s: ' "$label"
  if command_exists python3; then
    python3 - "$@" <<'PY' 2>&1 | head -n 20 || true
import subprocess
import sys

try:
    result = subprocess.run(
        sys.argv[1:],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=5,
    )
    print(result.stdout, end="")
except subprocess.TimeoutExpired as exc:
    output = exc.stdout or ""
    if isinstance(output, bytes):
        output = output.decode(errors="replace")
    print(output, end="")
    print("timed out after 5 seconds")
except OSError as exc:
    print(f"unavailable: {exc}")
PY
  else
    "$@" 2>&1 | head -n 20 || true
  fi
}

echo "Farcaster client iOS doctor"
echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Target: $CLIENT_DIR"

section "Repository"
show_command "Commit" git -C "$CLIENT_DIR" rev-parse HEAD
show_command "Changed paths (names only)" git -C "$CLIENT_DIR" status --short --untracked-files=normal
echo "Declared Node: $(recommended_node_version "$CLIENT_DIR")"
echo "Declared package manager: $(root_package_manager "$CLIENT_DIR")"

section "Host tools"
for tool in node corepack pnpm brew pod watchman vips ruby python3; do
  if command_exists "$tool"; then
    case "$tool" in
      node|corepack|pnpm|pod|watchman|ruby|python3) show_command "$tool" "$tool" --version ;;
      brew) show_command "$tool" "$tool" --version ;;
      vips) show_command "$tool" "$tool" --version ;;
    esac
  else
    echo "$tool: missing"
  fi
done
show_command "Xcode" xcodebuild -version
show_command "Developer directory" xcode-select -p

section "Disk"
df -h "$CLIENT_DIR" 2>/dev/null || true
du -sh "$CLIENT_DIR/node_modules" "$CLIENT_DIR/apps/farcaster-mobile/ios/Pods" 2>/dev/null || true

section "Simulator"
xcrun simctl list runtimes 2>/dev/null | sed -n '1,50p' || true
xcrun simctl list devices booted 2>/dev/null | sed -n '1,30p' || true

section "Metro"
if command_exists lsof; then
  lsof -nP -iTCP:8081 -sTCP:LISTEN 2>/dev/null || echo "No listener on 8081"
  if metro_pid="$(tcp_listener_pid 8081)" && [[ -n "$metro_pid" ]]; then
    echo "Listener working directory: $(process_cwd "$metro_pid" || echo unknown)"
  fi
fi
curl --silent --show-error --max-time 3 http://127.0.0.1:8081/status 2>&1 || true

section "Placeholder inventory"
for pair in \
  "Firebase plist|apps/farcaster-mobile/ios/Farcaster/GoogleService-Info.plist" \
  "Privy IDs|apps/farcaster-mobile/src/constants/Privy.ts" \
  "Expo config|apps/farcaster-mobile/app.json" \
  "Datadog|apps/farcaster-mobile/src/contexts/DatadogProvider.tsx" \
  "Alchemy|apps/farcaster-mobile/src/contexts/PayUserProvider.tsx"; do
  label="${pair%%|*}"
  relative="${pair#*|}"
  if contains_placeholder "$CLIENT_DIR/$relative"; then
    echo "$label: placeholders present"
  else
    echo "$label: no REPLACE_ME marker detected"
  fi
done

section "Privacy note"
echo "This report intentionally omits environment values and credential contents."
