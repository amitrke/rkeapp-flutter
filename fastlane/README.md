fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android upload_screenshots

```sh
[bundle exec] fastlane android upload_screenshots
```

Upload curated Android screenshots to Google Play

### android upload_metadata

```sh
[bundle exec] fastlane android upload_metadata
```

Upload store listing metadata (title and descriptions) to Google Play

### android diagnose_play_state

```sh
[bundle exec] fastlane android diagnose_play_state
```

Diagnose Google Play app state for release and metadata operations

### android promote_to_production

```sh
[bundle exec] fastlane android promote_to_production
```

Promote the internal track release to production

### android prepare_screenshots

```sh
[bundle exec] fastlane android prepare_screenshots
```

Create curated Android screenshot folders

----


## iOS

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload curated iOS screenshots to App Store Connect

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload store listing metadata (description, keywords, release notes) to App Store Connect

### ios submit_for_review

```sh
[bundle exec] fastlane ios submit_for_review
```

Submit the latest approved build for App Store review

### ios prepare_screenshots

```sh
[bundle exec] fastlane ios prepare_screenshots
```

Create curated iOS screenshot folders

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
