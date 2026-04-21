#!/bin/bash

set -e

DEVICE_ID="${1:-default}"
TEST_FILE="${2:-rke_screenshots_test.yaml}"

case "$DEVICE_ID" in
  android-phone|android-tablet-7|android-tablet-10|iphone-65|ipad-13|default)
    ;;
  *)
    echo "Error: Unknown device ID '$DEVICE_ID'"
    echo "Allowed: android-phone, android-tablet-7, android-tablet-10, iphone-65, ipad-13, default"
    exit 1
    ;;
esac

if [ -f ".env" ]; then
  while IFS='=' read -r key value; do
    if [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# ]]; then
      export "$(echo "$key" | xargs)=$(echo "$value" | xargs)"
    fi
  done < .env
  echo "Loaded .env"
fi

if ! command -v maestro >/dev/null 2>&1; then
  echo "Error: Maestro CLI not found in PATH"
  echo "Install from: https://maestro.mobile.dev/getting-started/installing-maestro"
  exit 1
fi

TEST_PATH="./.maestro/$TEST_FILE"
if [ ! -f "$TEST_PATH" ]; then
  echo "Error: Test file not found: $TEST_PATH"
  exit 1
fi

SCREENSHOT_DIR="screenshots/$DEVICE_ID"
export MAESTRO_SCREENSHOT_DIR="$SCREENSHOT_DIR"
mkdir -p "$SCREENSHOT_DIR"

echo "Running Maestro test"
echo "  Device: $DEVICE_ID"
echo "  Test:   $TEST_FILE"
echo "  Output: $SCREENSHOT_DIR"

maestro test "$TEST_PATH"
