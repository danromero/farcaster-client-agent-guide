#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap-ios.sh CLIENT_DIR [options]

Options:
  --apply-placeholder-guard  Apply the reviewed credentials-free Firebase guard.
  --skip-brew                Do not run brew bundle.
  --skip-pods                Do not run pod install.
  --dry-run                  Print commands without executing them.
  -h, --help                 Show this help.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

[[ $# -gt 0 ]] || { usage; exit 1; }

CLIENT_ARG="$1"
shift
APPLY_GUARD=0
SKIP_BREW=0
SKIP_PODS=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply-placeholder-guard) APPLY_GUARD=1 ;;
    --skip-brew) SKIP_BREW=1 ;;
    --skip-pods) SKIP_PODS=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

CLIENT_DIR="$(resolve_client_dir "$CLIENT_ARG")"
assert_client_checkout "$CLIENT_DIR"
PINNED_PATH="$GUIDE_ROOT/scripts/shims:$PATH"

run() {
  printf '+ '
  printf '%q ' "$@"
  printf '\n'
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@"
  fi
}

if [[ "$DRY_RUN" -eq 0 ]]; then
  "$SCRIPT_DIR/preflight.sh" "$CLIENT_DIR"
else
  info "Dry run: preflight execution skipped."
fi

if [[ "$APPLY_GUARD" -eq 1 ]]; then
  run "$SCRIPT_DIR/apply-placeholder-guard.sh" "$CLIENT_DIR"
fi

if [[ "$SKIP_BREW" -eq 0 ]]; then
  command_exists brew || die "Homebrew is required unless --skip-brew is used."
  run brew bundle "--file=$CLIENT_DIR/Brewfile"
fi

command_exists corepack || die "Corepack is required to honor the repository's pinned pnpm version."

info "Installing the frozen JavaScript dependency graph."
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "+ (cd $CLIENT_DIR && PATH=$GUIDE_ROOT/scripts/shims:\$PATH HUSKY=0 corepack pnpm install --frozen-lockfile)"
else
  (cd "$CLIENT_DIR" && PATH="$PINNED_PATH" HUSKY=0 corepack pnpm install --frozen-lockfile)
fi

info "Building shared workspace packages."
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "+ (cd $CLIENT_DIR && PATH=$GUIDE_ROOT/scripts/shims:\$PATH corepack pnpm --filter './packages/**' build)"
else
  (cd "$CLIENT_DIR" && PATH="$PINNED_PATH" corepack pnpm --filter './packages/**' build)
fi

if [[ "$SKIP_PODS" -eq 0 ]]; then
  command_exists pod || die "CocoaPods is required unless --skip-pods is used."
  info "Installing iOS pods."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "+ (cd $CLIENT_DIR/apps/farcaster-mobile/ios && pod install)"
  else
    (cd "$CLIENT_DIR/apps/farcaster-mobile/ios" && pod install)
  fi
fi

pass "Bootstrap complete. Next: $SCRIPT_DIR/start-ios.sh '$CLIENT_DIR' --build"
