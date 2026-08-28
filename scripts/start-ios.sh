#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/start-ios.sh CLIENT_DIR [options]

Options:
  --build                 Build/install the native app (default).
  --metro-only            Start only Metro for an already installed dev client.
  --device NAME_OR_UDID   Build mode only: select a simulator.
  --host MODE             Metro-only: lan, localhost, or tunnel (default: lan).
  --clear                 Metro-only: clear the transform cache once.
  -h, --help              Show this help.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

[[ $# -gt 0 ]] || { usage; exit 1; }
CLIENT_ARG="$1"
shift
MODE="build"
DEVICE=""
HOST_MODE="lan"
HOST_EXPLICIT=0
CLEAR_CACHE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) MODE="build" ;;
    --metro-only) MODE="metro" ;;
    --device)
      shift
      [[ $# -gt 0 ]] || die "--device requires a name or UDID."
      DEVICE="$1"
      ;;
    --host)
      shift
      [[ $# -gt 0 ]] || die "--host requires lan, localhost, or tunnel."
      HOST_MODE="$1"
      HOST_EXPLICIT=1
      ;;
    --clear) CLEAR_CACHE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

case "$HOST_MODE" in
  lan|localhost|tunnel) ;;
  *) die "Unsupported host mode: $HOST_MODE" ;;
esac

if [[ "$MODE" == "build" ]]; then
  [[ "$HOST_EXPLICIT" -eq 0 ]] || die "--host applies only with --metro-only."
  [[ "$CLEAR_CACHE" -eq 0 ]] || die "--clear applies only with --metro-only."
else
  [[ -z "$DEVICE" ]] || die "--device applies only with --build."
fi

CLIENT_DIR="$(resolve_client_dir "$CLIENT_ARG")"
assert_client_checkout "$CLIENT_DIR"
command_exists corepack || die "Corepack is required."
export PATH="$GUIDE_ROOT/scripts/shims:$PATH"

MOBILE_DIR="$CLIENT_DIR/apps/farcaster-mobile"

if metro_pid="$(tcp_listener_pid 8081)" && [[ -n "$metro_pid" ]]; then
  metro_cwd="$(process_cwd "$metro_pid" || true)"
  if [[ "$metro_cwd" == "$MOBILE_DIR" ]]; then
    if [[ "$MODE" == "metro" ]]; then
      die "Metro is already running for this checkout on port 8081; keep using that process."
    fi
    info "Reusing Metro already running for this checkout on port 8081."
  else
    die "Port 8081 belongs to another process (${metro_cwd:-unknown cwd}); confirm and stop it before continuing."
  fi
fi

if [[ "$MODE" == "metro" ]]; then
  args=(expo start --dev-client --host "$HOST_MODE")
  [[ "$CLEAR_CACHE" -eq 1 ]] && args+=(--clear)
  info "Starting Metro in $HOST_MODE mode. Keep this process running."
  cd "$MOBILE_DIR"
  exec corepack pnpm exec "${args[@]}"
fi

args=(expo run:ios -d)
[[ -n "$DEVICE" ]] && args+=("$DEVICE")
info "Building and launching the native app. Expo may prompt for a simulator."
cd "$MOBILE_DIR"
exec corepack pnpm exec "${args[@]}"
