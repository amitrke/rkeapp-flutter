# RkeApp

Roorkee.org Flutter App

## Android

### Testing

[Internal Test Link](https://play.google.com/apps/internaltest/4701241773410141731)

## Automated Screenshots (Maestro)

This app now includes a Maestro-based screenshot system.

### Prerequisites

1. Install Maestro CLI: https://maestro.mobile.dev/getting-started/installing-maestro
2. Start the app on an emulator/device (`flutter run`)
3. Keep the app unlocked and foregrounded

### Capture screenshots

PowerShell:

```powershell
.\run-maestro-test.ps1 default rke_screenshots_test.yaml
.\run-maestro-test.ps1 android-phone store_screenshots_test.yaml
```

Bash:

```bash
./run-maestro-test.sh default rke_screenshots_test.yaml
./run-maestro-test.sh iphone-65 store_screenshots_test.yaml
```

Generated screenshots are written to `screenshots/{device-id}/`.

For details on flow files and store folder organization, see:

- `.maestro/README.md`
- `screenshots/README.md`
