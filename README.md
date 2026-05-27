# RkeApp

Roorkee.org Flutter App

## Android

### Testing

[Open Testing Link](https://play.google.com/store/apps/details?id=org.roorkee)

[Internal Test Link](https://play.google.com/apps/internaltest/4701241773410141731)

### Store Metadata

Use the fastlane lanes below to upload store listing metadata from the repository root:

```sh
bundle exec fastlane android upload_metadata
bundle exec fastlane ios upload_metadata
```

These lanes upload the title, descriptions, keywords, and release notes for Google Play and App Store Connect.

For local iOS runs, load your `.env.fastlane` file first, then run the lane. The helper script does the same lane setup with a shorter command:

```sh
set -a
source .env.fastlane
set +a
bundle exec fastlane ios upload_metadata

./scripts/run-fastlane.sh ios-metadata
```

`IOS_APP_IDENTIFIER` defaults to `org.roorkee`.

If App Store Connect returns `No data` on the first metadata upload, add a minimal file at `fastlane/metadata/review_information/notes.txt` so deliver can create the review information record.

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

Curated Android screenshots under `screenshots/store/android/**` can now be uploaded to Google Play automatically through the `Upload Android Screenshots` GitHub Actions workflow.

For details on flow files, store folder organization, and upload steps, see:

- `.maestro/README.md`
- `screenshots/README.md`

## Account Deletion

The Account tab now includes an in-app `Delete Account` action for App Store compliance. Deletion removes the signed-in user's Firestore profile, posts, albums, notifications, moderation queue entries, uploaded images in Firebase Storage, and the Firebase Auth account.

If the account was created with Sign in with Apple, configure a backend endpoint to revoke the Apple authorization token before App Store submission:

```bash
flutter run --dart-define=APPLE_ACCOUNT_REVOCATION_URL=https://your-service.example.com/apple/revoke
```

The app will POST this JSON payload to that endpoint during account deletion:

```json
{
	"userId": "firebase uid",
	"email": "user@example.com",
	"authorizationCode": "apple authorization code",
	"identityToken": "apple identity token"
}
```
