# rkeapp-flutter Screenshot Management

This directory separates generated test screenshots from curated store screenshots.

## Structure

```text
screenshots/
├── store/                           # Commit this (curated, review-ready)
│   ├── android/
│   │   ├── phone/
│   │   ├── tablet-7/
│   │   └── tablet-10/
│   └── ios/
│       ├── iphone-6.5/
│       └── ipad-12.9/
├── android-phone/                   # Auto-generated (ignored)
├── android-tablet-*/                # Auto-generated (ignored)
├── iphone-*/                        # Auto-generated (ignored)
├── ipad-*/                          # Auto-generated (ignored)
└── default/                         # Auto-generated (ignored)
```

## Capture Screenshots Automatically

PowerShell:

```powershell
.\run-maestro-test.ps1 default rke_screenshots_test.yaml
.\run-maestro-test.ps1 android-phone store_screenshots_test.yaml
```

Bash:

```bash
./run-maestro-test.sh default rke_screenshots_test.yaml
./run-maestro-test.sh ipad-13 store_screenshots_test.yaml
```

## Promote to Store Assets

1. Capture screenshots into device folders.
2. Review and pick the best images.
3. Copy curated images into `screenshots/store/...`.
4. Commit only `screenshots/store/**`.

Example:

```bash
cp screenshots/android-phone/*.png screenshots/store/android/phone/
cp screenshots/android-tablet-7/*.png screenshots/store/android/tablet-7/
cp screenshots/android-tablet-10/*.png screenshots/store/android/tablet-10/
cp screenshots/iphone-65/*.png screenshots/store/ios/iphone-6.5/
```

## Upload Android Screenshots to Play Store

GitHub Actions now uploads curated Android screenshots automatically on pushes to `main` that touch `screenshots/store/android/**`, or you can trigger the workflow manually.

Required secret:

- `PLAYSTORE_SERVICE_ACCOUNT_JSON`: raw JSON content for a Google Play service account with Play Console release access.

Optional local upload:

```bash
bundle install
bundle exec fastlane android upload_screenshots
```

The Fastlane lane copies screenshots from `screenshots/store/android/{phone,tablet-7,tablet-10}` into the Play Store metadata structure and uploads only screenshots.

## Tips

- Keep stable test data for consistent screenshots.
- Use portrait orientation for both Android and iOS store assets.
- Number files (`01_`, `02_`, etc.) to preserve ordering.
