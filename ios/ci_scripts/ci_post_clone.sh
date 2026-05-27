#!/bin/bash
set -euo pipefail

# Xcode Cloud invokes this script after cloning the repository.
# Prepare Flutter artifacts and CocoaPods before the archive step.
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
FLUTTER_DIR="$HOME/flutter"

if [[ ! -d "$FLUTTER_DIR" ]]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

cd "$REPO_ROOT"
flutter --version
# Force CocoaPods plugin integration for iOS in CI.
# Swift Package Manager mode can omit Pods for Firebase plugins and break GeneratedPluginRegistrant imports.
flutter config --no-enable-swift-package-manager
flutter precache --ios
flutter pub get

# Generate iOS build configuration and plugin integration before xcodebuild archive.
# This runs CocoaPods with the same Flutter-managed settings used by local flutter build flows.
flutter build ios --config-only --no-codesign
