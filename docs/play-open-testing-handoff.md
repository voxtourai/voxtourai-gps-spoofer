# Play Open Testing Handoff

This document is the chunk 6 handoff for the GPS spoofer app.
It separates what is already ready in the repo from what still needs a product
decision, a secret, or Play Console access.

## Repo Status

Already ready in the repo:

- Android app builds locally as both APK and AAB
- release signing now supports `android/keystore.properties` or
  `ANDROID_KEYSTORE_*` environment variables
- shared IntelliJ run/build configs exist
- build and release steps are documented
- architecture and verification docs exist
- regression coverage exists for route, playback, mock, and route-math flows

Relevant docs:

- `docs/android-open-testing-checklist.md`
- `docs/architecture-walkthrough.md`
- `docs/android-play-store-default-listing.md`

## What You Need From Boss

These are the inputs that cannot be invented from the repo:

- Upload keystore ownership decision:
  - who owns the Play upload keystore
  - where the keystore file and credentials will be stored
- App icon / logo:
  - current launcher icon is still the default Flutter icon
- Store screenshots:
  - at minimum, phone screenshots for the Play listing
- Store copy approval:
  - default draft now exists in `docs/android-play-store-default-listing.md`
  - final short/full description still needs product review if wording must be adjusted
  - release notes style / tester-facing wording is still needed
- Support/contact details:
  - support email
  - support URL if one will be used
  - privacy policy URL if one exists or is required
- Testing audience decision:
  - who open testing is for
  - whether it should be truly open or effectively limited to known testers

## What Needs Play Console Access

These steps cannot be completed from the repo alone:

- create or confirm the Play app entry
- enroll or confirm Play App Signing setup
- create the `Open testing` track
- upload the signed `.aab`
- add release notes
- complete the store listing fields
- complete app content / safety / privacy questionnaire answers
- choose tester availability and rollout settings
- start the open-testing rollout

## What Is Still Blocked Right Now

### Technical blockers

- no real upload keystore has been provided yet

### Product/branding blockers

- current public app name is `GPS Spoofer`, but the launcher icon is still unfinished
- launcher icon is still the default Flutter icon
- store screenshots do not exist in this repo
- listing draft now exists in `docs/android-play-store-default-listing.md`, but it still needs approval and Play Console entry

### Account/process blockers

- Play Console actions require the right account access

## Recommended Next Sequence

1. Get the upload keystore decision from your boss.
2. Get or create the icon and listing screenshots.
3. Review the draft store listing in `docs/android-play-store-default-listing.md` and confirm support details.
4. Add local signing credentials and build the final upload AAB.
5. Hand the signed AAB plus listing inputs to whoever owns Play Console access.
6. Create and roll out the open-testing release in Play Console.

## Fast Status Answer

If your boss asks "what is left before open testing?" the short answer is:

- The repo is technically prepared for a signed AAB build.
- The remaining blockers are the upload keystore, icon/listing assets, and the
  Play Console setup itself.
