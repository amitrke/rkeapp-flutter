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
flutter test test/widgets_test.dart  # single file
flutter test --plain-name "clockLabel"   # single test or group by name
```

Build-time `--dart-define` values:
- `APP_CHECK_DEBUG_TOKEN=<uuid>`: the App Check debug token for iOS debug builds. Register it in Firebase Console → App Check → RkeApp (iOS) → Manage debug tokens.
- `APPLE_ACCOUNT_REVOCATION_URL=<url>`: a backend endpoint that deletion POSTs to (`userId`, `email`, `authorizationCode`, `identityToken`) so it can revoke Sign in with Apple tokens.

Tests cover the pure helpers in `widgets.dart` (`test/widgets_test.dart`). `MyApp` can't be pumped without Firebase, and no Firebase mocks are set up, so there are no screen tests.

## Architecture

The app is a flat `lib/` with one file per screen and no router. `main.dart` sets up Firebase and App Check, then shows `MyStatefulWidget`, the root shell. It keeps an index for four tabs (Home, Gallery, Weather, You) switched by a bottom `NavigationBar`, builds a per-tab `AppBar`, and shows the "New post" extended FAB on Home and You when signed in. All other screens are pushed with `Navigator.push`; `settings.dart` (Contact, Sign out, Delete account) opens from the gear on You.

### Theme and shared widgets

- `theme.dart`: `buildTheme(Brightness)` gives the light and dark `ThemeData` (seeded from canal teal, marigold secondary for dates and festivals, brick tertiary; Mukta via `google_fonts`). It also defines the `Space` and `Radii` scales and an `AppColors` extension on `ColorScheme` for `success` colors. `google_fonts` is pinned to `^8`: 9.x is built on `material_ui`, whose `TextTheme` is a different type from Flutter's.
- `widgets.dart`: `SectionHeader`, `NetworkThumb`, `DateTile`, `StatusBadge`, `EmptyState`, `ErrorState` (with retry), `InlineEmpty`, plus helpers (`relativeTime`, `eventWhen`, `shortDate`, `clockLabel` for en-IN times, `weatherIcon` mapping OpenWeatherMap codes, `openLink` for in-app browser tabs).
- `sign_in.dart`: `startSignIn(context)`, Google everywhere plus an Apple option on iOS.

Take colors from `Theme.of(context).colorScheme` and spacing from `Space`/`Radii` rather than literals; the app runs in dark mode when the system does. The only intentional literals are the black full-screen photo viewer and the dark overlay on image remove buttons.

State is managed with Provider and two global singletons, each exposing a `ChangeNotifier`:
- `authService` (`auth.dart`) owns `RkeUser`. It handles Google sign-in (plus Apple sign-in on iOS through a bottom sheet), sign-out and full account deletion. Deletion removes the user's Firestore profile, posts, albums, notifications, moderation queue entries and Storage images, then the Auth account.
- `appDataService` (`posts.dart`) owns `AppData`. On construction it loads posts (joined with `users`), news, events, albums and weather (`weather/roorkee-in`, written hourly by `rke-firebase-functions`). `reload()` re-fetches everything and backs pull-to-refresh and "Try again".

Models are in `models.dart`. Firestore collection names are constants in `collections.dart`. Use `Collections.x` rather than string literals.

Screens that belong to the current user (`myposts.dart`, the You tab) query Firestore directly with streams and don't go through `AppData`. Those streams are created once per user ID and cached, so switching between Posts, Albums and Alerts doesn't resubscribe. New posts are written to `posts`, and an entry with `status: 'pending'` is added to `moderationQueue` for admin review. The user sees the outcome through `notifications`.

Images are resized and compressed in `image_utils.dart` (`image` package) before they're uploaded to Firebase Storage.

`package.json` (the Firebase JS SDK) isn't part of the Flutter app.

## Release / store tooling

The full flow and one-time setup are in `docs/RELEASING.md`.

- **Build** (`build.yml`, manual): debug-signed APKs for sideloading. It needs no secrets: without `android/key.properties`, `build.gradle` falls back to the debug key.
- **Release to testers** (`release.yml`): on push to `develop`, a `v*` tag, or manually. It sends a signed AAB to the Play internal track and an IPA to TestFlight with the same build number, `github.run_number + 100`. Don't rename or recreate this file, or the run number restarts and both stores reject the repeats. The version comes from `pubspec.yaml` (`1.2.3`), and an already-tagged version is refused. iOS uses cloud-managed signing with the App Store Connect API key: the archive is built unsigned and signed on export, using export options the job writes itself because `ios/ExportOptions.plist` is gitignored. It refuses a debug-signed bundle.
- **Promote to production** (`promote.yml`, manual, `master` only, waits on the `production` environment): takes a build number testers already have. It promotes that build from internal to production on Play (with a rollout %) and submits it for App Review (released automatically once approved), then tags `v<version>`. Nothing is rebuilt.
- **Secrets**: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `PLAYSTORE_SERVICE_ACCOUNT_JSON`, plus `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` and `APP_STORE_CONNECT_API_KEY` (a base64 `.p8`, Admin role). The metadata and screenshot workflows share the same App Store Connect secrets.
- **Xcode Cloud** scripts are still present: the root `ci_scripts/ci_post_clone.sh` calls `ios/ci_scripts/ci_post_clone.sh`, which clones stable Flutter, disables Swift Package Manager and runs `flutter build ios --config-only`.
- **Fastlane** (`bundle exec fastlane <android|ios> <lane>`) handles `promote build:<n>` (Android also takes `rollout:<percent>`), `upload_metadata`, `upload_screenshots` and `diagnose_play_state`. Store text and release notes live in `fastlane/metadata/` (iOS in `en-US/`, Android in `android/en-US/`). `./scripts/run-fastlane.sh <action>` (or `.ps1`) wraps these lanes; `ios-submit <build>` calls `ios promote`. iOS lanes read `.env.fastlane`.
- **Screenshots** are taken with Maestro flows in `.maestro/`. Run `./run-maestro-test.sh <device-id> <flow>.yaml` against a running app; output goes to `screenshots/<device-id>/`. See `.maestro/README.md` and `screenshots/README.md`.
