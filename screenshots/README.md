# rkeapp-flutter Screenshot Management

This directory separates generated test screenshots from curated store screenshots.

## Structure

```text
screenshots/
├── store/                           # Commit this (curated, review-ready)
│   ├── android/
│   │   ├── phone/
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
cp screenshots/iphone-65/*.png screenshots/store/ios/iphone-6.5/
```

## Tips

- Keep stable test data for consistent screenshots.
- Use portrait orientation for both Android and iOS store assets.
- Number files (`01_`, `02_`, etc.) to preserve ordering.
