#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE=".env.fastlane"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-fastlane-ios.sh metadata
  ./scripts/run-fastlane-ios.sh screenshots
  ./scripts/run-fastlane-ios.sh submit

What it does:
  - Loads variables from .env.fastlane (if present)
  - Verifies required App Store Connect variables
  - Runs the matching Fastlane iOS lane

Required variables in .env.fastlane or current shell:
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_API_KEY   (base64-encoded .p8 key content)

Optional:
  IOS_APP_IDENTIFIER          (defaults to org.roorkee in Fastlane config)
EOF
}

load_env_file() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    echo "Warning: $file_path not found. Using current shell env only."
    return
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    local key="${line%%=*}"
    local value="${line#*=}"

    key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if [[ -n "$key" ]]; then
      export "$key=$value"
    fi
  done < "$file_path"

  echo "Loaded $file_path"
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Error: Missing required environment variable: $name"
    exit 1
  fi
}

ensure_bundle() {
  if ! command -v bundle >/dev/null 2>&1; then
    echo "Error: bundler is not installed or not in PATH"
    echo "Install with: gem install bundler"
    exit 1
  fi

  bundle install >/dev/null
}

run_lane() {
  local lane="$1"

  require_env APP_STORE_CONNECT_KEY_ID
  require_env APP_STORE_CONNECT_ISSUER_ID
  require_env APP_STORE_CONNECT_API_KEY

  ensure_bundle
  bundle exec fastlane ios "$lane"
}

action="${1:-}"

case "$action" in
  metadata)
    load_env_file "$ENV_FILE"
    run_lane "upload_metadata"
    ;;
  screenshots)
    load_env_file "$ENV_FILE"
    run_lane "upload_screenshots"
    ;;
  submit)
    load_env_file "$ENV_FILE"
    run_lane "submit_for_review"
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    echo "Error: Unknown action '$action'"
    usage
    exit 1
    ;;
esac
