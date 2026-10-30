# Releasing

Three workflows, adapted from amitrke/voice-notes:

| Workflow | Runs on | Does |
|---|---|---|
| **Build** (`build.yml`) | Manual | Debug-signed APKs to sideload. Needs no secrets. |
| **Release to testers** (`release.yml`) | Push to `develop`, `v*` tags, manual | Signed AAB to the Play **internal testing** track and IPA to **TestFlight**, with the same build number on both. |
| **Promote to production** (`promote.yml`) | Manual, from `master` only | Moves a build testers already have to production. Play goes from internal to production, at a rollout percentage you choose. iOS is submitted to App Review and released automatically when approved. Then it tags `v<version>`. |

Promotion never builds anything, so what ships is the binary that was tested.

The store listing and screenshot workflows (`upload-*-metadata.yml`,
`upload-*-screenshots.yml`) are unchanged.

## Shipping a version

1. Set `version:` in `pubspec.yaml` (for example `1.1.0`; the `+N` part is ignored).
   A version that already has a `v` tag is refused.
2. Merge to `develop`. **Release to testers** runs and both stores show
   `1.1.0 (N)`.
3. Test it. Every further push to `develop` ships a new `(N)` of the same version.
4. Write release notes in `fastlane/metadata/en-US/release_notes.txt` (iOS) and
   `fastlane/metadata/android/en-US/changelogs/default.txt`, or `<N>.txt` for
   one build (Android).
5. Merge `develop` into `master`. Run **Promote to production** from `master`
   with the build number `N`. Approve the run when the `production`
   environment asks.
6. To widen a staged Play rollout, run it again with a higher `rollout` (100 completes it).

Build numbers are `github.run_number` of `release.yml` + 100. The old
`main.yml` used its run number directly and reached 17. Renaming or
recreating `release.yml` restarts the count, and both stores would reject the
repeated numbers.

## One-time setup

### Secrets (Settings → Secrets and variables → Actions)

Already set:

- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD`: the Play upload key.
- `PLAYSTORE_SERVICE_ACCOUNT_JSON`: service account with release rights on
  `org.roorkee`. Without it, bundles are built and kept as artifacts only.

Needed for iOS (not set yet):

- `APP_STORE_CONNECT_KEY_ID` and `APP_STORE_CONNECT_ISSUER_ID`: from App Store
  Connect → Users and Access → Integrations → App Store Connect API.
- `APP_STORE_CONNECT_API_KEY`: the `.p8` file, **base64-encoded**
  (`base64 -i AuthKey_XXXX.p8 | pbcopy`). The key needs the **Admin** role,
  because cloud-managed signing creates the distribution certificate and
  profile with it.

Until those are set, the iOS job only compiles, unsigned, to prove the build works.

### Optional variables

- `RELEASE_ANDROID` = `false` or `RELEASE_IOS` = `false` skips that store on push.

### The `production` environment

`promote.yml` creates it on first use, but with no protection. Under
Settings → Environments → production, add yourself as a **required reviewer**
and limit deployment branches to `master`. Then every promotion waits for an
explicit approval.

### Testers

- Play: add testers to the internal testing track's email list in Play Console.
- TestFlight: add internal testers in App Store Connect. `Info.plist` declares
  `ITSAppUsesNonExemptEncryption = false`, so builds reach them without a manual
  export-compliance answer.
