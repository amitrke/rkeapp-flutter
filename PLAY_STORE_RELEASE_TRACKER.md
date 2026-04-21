# Play Store Release Tracker

This file tracks the Android release pipeline work for the first Play Store internal test release.

## Status

- [x] Generate Android release keystore and store a secure backup
- [x] Create local Android key properties and keep it git-ignored
- [x] Update Android release signing in `android/app/build.gradle`
- [x] Verify local signed AAB and APK builds
- [x] Add GitHub Actions secrets for keystore alias and passwords
- [x] Upgrade the Android release workflow in `.github/workflows/main.yml`
- [x] Configure CI to decode keystore and generate `android/key.properties`
- [x] Configure CI to build signed AAB and APK artifacts
- [ ] Trigger the workflow from version tags and verify generated artifacts
- [x] Create Play Console service account for CI upload
- [x] Add Play Store service account JSON as a GitHub secret
- [ ] Extend the workflow to upload the AAB to internal testing
- [ ] Grant the CI service account release permissions in Play Console
- [ ] Push a test tag and confirm the build appears in internal testing
- [ ] Install the release build on a device and verify startup, auth, data loading, and storage flows
- [ ] Decide the release branching and tagging convention

## Reference

- Reference workflow: `reference/getspot/.github/workflows/deploy-android.yml`
- Reuse the base64 keystore secret pattern from getspot
- Keep Android scope first; do not expand to iOS until the Android release path is stable

## Required GitHub Secrets

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `KEY_ALIAS`
- `PLAYSTORE_SERVICE_ACCOUNT_JSON`

## Notes

- `android/key.properties` must stay local and must not be committed.
- The release keystore must be backed up safely before the first store upload.
- The workflow builds both an AAB for Play Store and an APK for direct device verification.