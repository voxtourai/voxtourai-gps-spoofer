# Android Open Testing Checklist

This document is the chunk 5 release-prep output for the GPS spoofer repo.
It covers the repo-side readiness for Google Play open testing and separates
what is ready now from what still needs secrets or Play Console work.

## Ready Now

- Android release builds already produce:
  - APK: `build/app/outputs/flutter-apk/app-release.apk`
  - AAB: `build/app/outputs/bundle/release/app-release.aab`
- The Android app ID is already set:
  - `ai.voxtour.voxtourai_gps_spoofer`
- Versioning already flows from `pubspec.yaml` into Android:
  - `versionName` -> Flutter build name
  - `versionCode` -> Flutter build number
- The Google Maps API key is already wired through Gradle/local properties/env:
  - `MAPS_API_KEY`
- Shared IntelliJ run configs already exist for:
  - `Build APK`
  - `Build App Bundle`
  - `Main Local`
  - `Flutter Analyze`
  - `Flutter Test All`

## Repo Changes In This Chunk

- Release signing now supports the same `keystore.properties` pattern used in
  `voxtourai_fe`.
- Release signing can also be supplied through environment variables:
  - `ANDROID_KEYSTORE_FILE`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
- A committed template now exists at:
  - `android/keystore.properties.example`
- `android/.gitignore` now ignores `keystore.properties`.

## Release Signing Behavior

### Preferred local setup

Create `android/keystore.properties` from the example file:

```properties
storeFile=.keystore/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

### Environment-variable alternative

PowerShell example:

```powershell
$env:ANDROID_KEYSTORE_FILE = "C:\path\to\upload-keystore.jks"
$env:ANDROID_KEYSTORE_PASSWORD = "..."
$env:ANDROID_KEY_ALIAS = "upload"
$env:ANDROID_KEY_PASSWORD = "..."
```

### Fallback behavior

If no release signing values are configured, the repo still falls back to the
debug signing config for local `--release` builds.

That fallback is useful for local smoke validation only.
It is not acceptable for Google Play upload.

## Local Release Commands

Commands should be executed from the project root.

### Build APK

```shell
flutter build apk --release
```

### Build AAB

```shell
flutter build appbundle --release
```

Required local inputs:

- `MAPS_API_KEY`
- release keystore config, if the output is intended for Play upload

## Ready Vs Blocked

### Ready

- repo can build release APK and AAB artifacts
- repo can now consume a real upload keystore without hardcoding secrets
- app package name and versioning path are defined
- automated checks exist:
  - `flutter analyze`
  - `flutter test`

### Blocked Until Provided

- upload keystore file and credentials are not committed in this repo
- no Play App Signing enrollment can be completed from the repo alone

### Blocked Until Product/Branding Decision

- app label in `AndroidManifest.xml` is still `voxtourai_gps_spoofer`
- launcher icon is still the default Flutter icon
- final store name, icon, screenshots, and listing copy are not part of the repo

### Blocked Until Play Console Work

- create or configure the Play app record
- enroll/confirm Play App Signing
- create the `Open testing` track
- upload the `.aab`
- complete store listing fields
- complete app content / privacy / safety forms
- define tester availability or public opt-in settings
- roll out the open-testing release

## Recommended Order

1. Obtain the upload keystore and credentials.
2. Add `android/keystore.properties` locally, or set the signing env vars.
3. Build the AAB locally:
   - `flutter build appbundle --release`
4. Verify the produced artifact:
   - `build/app/outputs/bundle/release/app-release.aab`
5. Replace the default app label/icon before external testing.
6. Upload the AAB to Play Console open testing.

## Meeting Summary Version

If asked whether open testing is ready:

- The repo is now wired to accept a real upload keystore.
- The technical blocker is the missing keystore/credentials.
- The product blockers are the app name/icon/listing assets.
- The final rollout step still happens in Play Console, not in the repo.
