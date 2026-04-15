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
flutter precache --ios
flutter pub get

cd ios
pod install
