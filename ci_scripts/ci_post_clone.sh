#!/bin/bash
set -euo pipefail

# Xcode Cloud auto-detects scripts only from repo-root ci_scripts/.
# Delegate to the existing iOS setup script so CocoaPods and Flutter plugins are prepared.
"$(cd "$(dirname "$0")/.." && pwd)"/ios/ci_scripts/ci_post_clone.sh
