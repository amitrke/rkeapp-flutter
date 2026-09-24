# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RkeApp is the Roorkee.org community app, built with Flutter for Android and iOS on Firebase (project `rkeorg`). The bundle ID and package name are both `org.roorkee`.

## Commands

```bash
flutter pub get
flutter run
flutter analyze                      # lints: package:flutter_lints/flutter.yaml
flutter test                         # all tests
flutter test test/widget_test.dart   # single file
flutter test --plain-name "App builds"   # single test by name
```

Build-time `--dart-define` values:
- `APP_CHECK_DEBUG_TOKEN=<uuid>`: the App Check debug token for iOS debug builds. Register it in Firebase Console → App Check → RkeApp (iOS) → Manage debug tokens.
- `APPLE_ACCOUNT_REVOCATION_URL=<url>`: a backend endpoint that deletion POSTs to (`userId`, `email`, `authorizationCode`, `identityToken`) so it can revoke Sign in with Apple tokens.

The test suite is basically a placeholder. `MyApp` can't be pumped without Firebase, and no Firebase mocks are set up.

## Architecture

The app is a flat `lib/` with one file per screen and no router. `main.dart` sets up Firebase and App Check, then shows `MyStatefulWidget`. That widget keeps an index for four pages (Home, Account, Gallery, Weather) that are switched from a drawer. All other screens are pushed with `Navigator.push`.

State is managed with Provider and two global singletons, each exposing a `ChangeNotifier`:
- `authService` (`auth.dart`) owns `RkeUser`. It handles Google sign-in (plus Apple sign-in on iOS through a bottom sheet), sign-out and full account deletion. Deletion removes the user's Firestore profile, posts, albums, notifications, moderation queue entries and Storage images, then the Auth account.
- `appDataService` (`posts.dart`) owns `AppData`. On construction it loads posts (joined with `users`), news, events, albums and weather.

Models are in `models.dart`. Firestore collection names are constants in `collections.dart`. Use `Collections.x` rather than string literals.

Screens that belong to the current user (`myposts.dart`, the Account tab) query Firestore directly with streams and don't go through `AppData`. New posts are written to `posts`, and an entry with `status: 'pending'` is added to `moderationQueue` for admin review. The user sees the outcome through `notifications`.

Images are resized and compressed in `image_utils.dart` (`image` package) before they're uploaded to Firebase Storage.

`package.json` (the Firebase JS SDK) isn't part of the Flutter app.

## Release / store tooling

- **Android release**: `.github/workflows/main.yml` runs on a `v*` tag or manually. The build name comes from the tag, and the build number is the GitHub run number. It signs the build with keystore secrets and uploads to Play. Other workflows handle metadata, screenshots, production promotion and iOS review submission.
- **iOS** builds run on Xcode Cloud. The root `ci_scripts/ci_post_clone.sh` calls `ios/ci_scripts/ci_post_clone.sh`, which clones stable Flutter, disables Swift Package Manager and runs `flutter build ios --config-only`.
- **Fastlane** (`bundle exec fastlane <android|ios> <lane>`) handles `upload_metadata`, `upload_screenshots`, `submit_for_review`, `promote_to_production` and `diagnose_play_state`. Store text lives in `fastlane/metadata/`. `./scripts/run-fastlane.sh <action>` wraps these lanes, and iOS lanes read `.env.fastlane`.
- **Screenshots** are taken with Maestro flows in `.maestro/`. Run `./run-maestro-test.sh <device-id> <flow>.yaml` against a running app; output goes to `screenshots/<device-id>/`. See `.maestro/README.md` and `screenshots/README.md`.
