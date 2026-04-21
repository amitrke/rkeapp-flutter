# Maestro Screenshot Automation for rkeapp-flutter

This directory contains automated screenshot flows for the Roorkee Flutter app.

## Flows

- `rke_screenshots_test.yaml`: Read-only baseline screenshots for core screens.
- `store_screenshots_test.yaml`: Curated screenshots for app-store style output.

Both flows use:

- `appId: org.roorkee`
- `MAESTRO_SCREENSHOT_DIR` passed by the runner scripts

## Run

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

## Device IDs

- `default`
- `android-phone`
- `android-tablet-7`
- `android-tablet-10`
- `iphone-65`
- `ipad-13`

## Notes

- Keep `clearState: false` for realistic, populated screenshots.
- If you need a clean app session, use:

```yaml
- launchApp:
    clearState: true
```

- If a drawer tap fails on a given emulator/OS, unlock and focus the app, then rerun.
