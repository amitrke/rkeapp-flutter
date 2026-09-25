# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RkeApp is the Roorkee.org community app, built with Flutter for Android and iOS on Firebase (project `rkeorg`). The bundle ID and package name are both `org.roorkee`.

## Commands

```bash
flutter pub get
flutter run
flutter analyze lib test             # lints; plain `flutter analyze` also scans build/ and ios/ (hundreds of unrelated issues)
flutter test                         # all tests
flutter test test/widget_test.dart   # single file
flutter test --plain-name "App builds"   # single test by name
```

Build-time `--dart-define` values:
- `APP_CHECK_DEBUG_TOKEN=<uuid>`: the App Check debug token for iOS debug builds. Register it in Firebase Console → App Check → RkeApp (iOS) → Manage debug tokens.
- `RKE_API_BASE_URL=<url>`: the rke-nextjs site whose `/api` routes the app calls. It defaults to `https://www.roorkee.org`; use `https://preview.roorkee.org` to test against the `develop` branch.
- `APPLE_ACCOUNT_REVOCATION_URL=<url>`: a backend endpoint that deletion POSTs to (`userId`, `email`, `authorizationCode`, `identityToken`) so it can revoke Sign in with Apple tokens.

The test suite is basically a placeholder. `MyApp` can't be pumped without Firebase, and no Firebase mocks are set up.

## Architecture

The app is a flat `lib/` with one file per screen and no router. `main.dart` sets up Firebase and App Check, then shows `MyStatefulWidget`. That widget keeps an index for four pages (Home, Account, Gallery, Weather) that are switched from a drawer. All other screens are pushed with `Navigator.push`.

State is managed with Provider and global singletons, each exposing a `ChangeNotifier` (`blockList` is described below):
- `authService` (`auth.dart`) owns `RkeUser`. It handles Google sign-in (plus Apple sign-in on iOS through a bottom sheet), sign-out and account deletion. For deletion it re-authenticates, then calls `/api/deleteAccount`, which removes the user's data, Storage files and Auth account on the server.
- `appDataService` (`posts.dart`) owns `AppData`. On construction it loads posts (joined with `users`), news, events, albums and weather.

Models are in `models.dart`. Firestore collection names are constants in `collections.dart`. Use `Collections.x` rather than string literals.

Screens that belong to the current user (`myposts.dart`, the Account tab) query Firestore directly with streams and don't go through `AppData`.

The backend is the sibling `rke-nextjs` repo. It holds `firestore.rules` and the Next.js `/api` routes; there are no Cloud Functions for this app. The rules block client writes to `moderationQueue`, `notifications` and the `approved` field, so those go through `/api` routes via `postWebApi` in `web_api.dart`. The app saves posts and albums itself, then calls `/api/submitForReview`. An admin approves or rejects them on the website's `/account/moderation` page, and the author sees the result in `notifications`.

`content_safety.dart` covers App Store Guideline 1.2 (user-generated content). `ContentActionsMenu` lets users report a post or album (writes to `reports`) and block its author (writes to `users/{uid}/blocked`). Any screen that lists other users' content must filter it through `BlockList.isBlocked`. Admins handle reports on the website's moderation page.

Images are resized and compressed in `image_utils.dart` (`image` package) before they're uploaded to Firebase Storage.

`package.json` (the Firebase JS SDK) isn't part of the Flutter app.

## Release / store tooling

- **Android release**: `.github/workflows/main.yml` runs on a `v*` tag or manually. The build name comes from the tag, and the build number is the GitHub run number. It signs the build with keystore secrets and uploads to Play. Other workflows handle metadata, screenshots, production promotion and iOS review submission.
- **iOS** builds run on Xcode Cloud. The root `ci_scripts/ci_post_clone.sh` calls `ios/ci_scripts/ci_post_clone.sh`, which clones stable Flutter, disables Swift Package Manager and runs `flutter build ios --config-only`.
- **Fastlane** (`bundle exec fastlane <android|ios> <lane>`) handles `upload_metadata`, `upload_screenshots`, `submit_for_review`, `promote_to_production` and `diagnose_play_state`. Store text lives in `fastlane/metadata/`. `./scripts/run-fastlane.sh <action>` wraps these lanes, and iOS lanes read `.env.fastlane`.
- **Screenshots** are taken with Maestro flows in `.maestro/`. Run `./run-maestro-test.sh <device-id> <flow>.yaml` against a running app; output goes to `screenshots/<device-id>/`. See `.maestro/README.md` and `screenshots/README.md`.
