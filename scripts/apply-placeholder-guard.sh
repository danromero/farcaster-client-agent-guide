#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/apply-placeholder-guard.sh /path/to/farcaster-client

Applies the reviewed iOS Firebase placeholder guard. This modifies the target
checkout and requires a native rebuild. It refuses credentialed plists and
source contexts that do not match the verified patch.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

CLIENT_DIR="$(resolve_client_dir "${1:-}")"
assert_client_checkout "$CLIENT_DIR"

plist="$CLIENT_DIR/apps/farcaster-mobile/ios/Farcaster/GoogleService-Info.plist"
delegate="$CLIENT_DIR/apps/farcaster-mobile/ios/Farcaster/AppDelegate.swift"
patch_file="$GUIDE_ROOT/patches/skip-placeholder-firebase-ios.patch"

if grep -q 'googleAppID != "REPLACE_ME"' "$delegate"; then
  pass "Placeholder guard is already present."
  exit 0
fi

contains_placeholder "$plist" || die "Firebase plist is not a public placeholder; refusing to alter initialization."
[[ -f "$patch_file" ]] || die "Missing bundled patch: $patch_file"
git -C "$CLIENT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || \
  die "Target must be a Git checkout for guarded patch application."

if ! git -C "$CLIENT_DIR" apply --check "$patch_file"; then
  die "Patch context does not match this snapshot. Inspect current AppDelegate.swift; do not force the patch."
fi

git -C "$CLIENT_DIR" apply "$patch_file"
pass "Applied credentials-free Firebase launch guard. Rebuild the native app."
