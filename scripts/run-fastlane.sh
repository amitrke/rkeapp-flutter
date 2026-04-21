#!/usr/bin/env bash
set -euo pipefail

# Local helper to run Fastlane lanes for Play Store / App Store actions.
# Usage:
#   ./scripts/run-fastlane.sh android-screenshots /absolute/path/to/play_store_key.json
#   ./scripts/run-fastlane.sh android-metadata /absolute/path/to/play_store_key.json [track]
#   ./scripts/run-fastlane.sh android-diagnose /absolute/path/to/play_store_key.json
#   ./scripts/run-fastlane.sh ios-metadata
#   ./scripts/run-fastlane.sh ios-submit
#
# On Windows PowerShell, use .\scripts\run-fastlane.ps1 instead.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ANDROID_PACKAGE_NAME_DEFAULT="org.roorkee"
IOS_APP_IDENTIFIER_DEFAULT="org.roorkee"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run-fastlane.sh android-screenshots <play_store_key_json_path>
  ./scripts/run-fastlane.sh android-metadata <play_store_key_json_path> [track]
  ./scripts/run-fastlane.sh android-diagnose <play_store_key_json_path>
  ./scripts/run-fastlane.sh ios-metadata
  ./scripts/run-fastlane.sh ios-submit

Windows PowerShell:
  .\scripts\run-fastlane.ps1 android-screenshots <play_store_key_json_path>
  .\scripts\run-fastlane.ps1 android-metadata <play_store_key_json_path> [track]
  .\scripts\run-fastlane.ps1 android-diagnose <play_store_key_json_path>
  .\scripts\run-fastlane.ps1 ios-metadata
  .\scripts\run-fastlane.ps1 ios-submit

Actions:
  android-screenshots  Upload Android screenshots (Fastlane lane: android upload_screenshots)
  android-metadata     Upload Android store listing metadata (lane: android upload_metadata)
  android-diagnose     Diagnose Android Play app state (lane: android diagnose_play_state)
  ios-metadata         Upload iOS metadata (lane: ios upload_metadata)
  ios-submit           Submit iOS app for review (lane: ios submit_for_review)

Required env vars for iOS actions:
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID
  APP_STORE_CONNECT_API_KEY   (base64-encoded p8 content)

Optional env vars:
  ANDROID_PACKAGE_NAME (default: org.roorkee)
  PLAY_STORE_VERSION_CODE (required only to upload Android changelogs)
  IOS_APP_IDENTIFIER   (default: org.roorkee)
EOF
}

require_file() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]]; then
    echo "Error: File not found: $file_path"
    exit 1
  fi
}

resolve_absolute_path() {
  local file_path="$1"
  local target_dir
  local target_name

  target_dir="$(cd "$(dirname "$file_path")" && pwd)"
  target_name="$(basename "$file_path")"
  printf '%s/%s\n' "$target_dir" "$target_name"
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Error: Required environment variable is missing: $name"
    exit 1
  fi
}

add_gem_user_bin_to_path() {
  if ! command -v ruby >/dev/null 2>&1; then
    return
  fi

  local gem_user_bin
  gem_user_bin="$(ruby -e 'print Gem.user_dir')/bin"
  if [[ -d "$gem_user_bin" && ":$PATH:" != *":$gem_user_bin:"* ]]; then
    export PATH="$gem_user_bin:$PATH"
  fi
}

ensure_bundle() {
  add_gem_user_bin_to_path

  if ! command -v bundle >/dev/null 2>&1; then
    if ! command -v gem >/dev/null 2>&1; then
      echo "Error: RubyGems (gem) is not installed or not in PATH."
      exit 1
    fi

    echo "Bundler not found. Installing bundler..."
    gem install bundler --no-document
    add_gem_user_bin_to_path
    hash -r
  fi

  if ! command -v bundle >/dev/null 2>&1; then
    echo "Error: bundler installed but still not in PATH."
    echo "Try restarting the shell, then re-run this script."
    exit 1
  fi

  bundle install
}

run_android_screenshots() {
  local key_path="$1"
  require_file "$key_path"

  export SUPPLY_JSON_KEY="$(resolve_absolute_path "$key_path")"
  export ANDROID_PACKAGE_NAME="${ANDROID_PACKAGE_NAME:-$ANDROID_PACKAGE_NAME_DEFAULT}"

  ensure_bundle
  bundle exec fastlane android upload_screenshots
}

run_android_metadata() {
  local key_path="$1"
  local track="${2:-internal}"
  require_file "$key_path"

  export SUPPLY_JSON_KEY="$(resolve_absolute_path "$key_path")"
  export ANDROID_PACKAGE_NAME="${ANDROID_PACKAGE_NAME:-$ANDROID_PACKAGE_NAME_DEFAULT}"
  export PLAY_STORE_TRACK="$track"

  ensure_bundle
  bundle exec fastlane android upload_metadata
}

run_android_diagnose() {
  local key_path="$1"
  require_file "$key_path"

  export SUPPLY_JSON_KEY="$(resolve_absolute_path "$key_path")"
  export ANDROID_PACKAGE_NAME="${ANDROID_PACKAGE_NAME:-$ANDROID_PACKAGE_NAME_DEFAULT}"

  ensure_bundle
  bundle exec fastlane android diagnose_play_state
}

run_ios_metadata() {
  require_env APP_STORE_CONNECT_KEY_ID
  require_env APP_STORE_CONNECT_ISSUER_ID
  require_env APP_STORE_CONNECT_API_KEY

  export IOS_APP_IDENTIFIER="${IOS_APP_IDENTIFIER:-$IOS_APP_IDENTIFIER_DEFAULT}"

  ensure_bundle
  bundle exec fastlane ios upload_metadata
}

run_ios_submit() {
  require_env APP_STORE_CONNECT_KEY_ID
  require_env APP_STORE_CONNECT_ISSUER_ID
  require_env APP_STORE_CONNECT_API_KEY

  export IOS_APP_IDENTIFIER="${IOS_APP_IDENTIFIER:-$IOS_APP_IDENTIFIER_DEFAULT}"

  ensure_bundle
  bundle exec fastlane ios submit_for_review
}

action="${1:-}"

case "$action" in
  android-screenshots)
    if [[ $# -lt 2 ]]; then
      usage
      exit 1
    fi
    run_android_screenshots "$2"
    ;;
  android-metadata)
    if [[ $# -lt 2 ]]; then
      usage
      exit 1
    fi
    run_android_metadata "$2" "${3:-internal}"
    ;;
  android-diagnose)
    if [[ $# -lt 2 ]]; then
      usage
      exit 1
    fi
    run_android_diagnose "$2"
    ;;
  ios-metadata)
    run_ios_metadata
    ;;
  ios-submit)
    run_ios_submit
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
