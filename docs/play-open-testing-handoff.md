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

## What You Need From Boss

These are the inputs that cannot be invented from the repo:

- Upload keystore ownership decision:
  - who owns the Play upload keystore
  - where the keystore file and credentials will be stored
- Public app name:
  - whether the Play-visible name stays close to `voxtourai_gps_spoofer`
  - or gets a cleaner tester-facing name
- App icon / logo:
  - current launcher icon is still the default Flutter icon
- Store screenshots:
  - at minimum, phone screenshots for the Play listing
- Store copy:
  - short description
  - full description
  - release notes style / tester-facing wording
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

- app label is still `voxtourai_gps_spoofer`
- launcher icon is still the default Flutter icon
- store screenshots and listing copy do not exist in this repo

### Account/process blockers

- Play Console actions require the right account access

## Recommended Next Sequence

1. Get the upload keystore decision from your boss.
2. Get the final tester-facing app name.
3. Get or create the icon and listing screenshots.
4. Get the short description, full description, and support details.
5. Add local signing credentials and build the final upload AAB.
6. Hand the signed AAB plus listing inputs to whoever owns Play Console access.
7. Create and roll out the open-testing release in Play Console.

## Fast Status Answer

If your boss asks "what is left before open testing?" the short answer is:

- The repo is technically prepared for a signed AAB build.
- The remaining blockers are the upload keystore, app name/icon/listing assets,
  and the Play Console setup itself.
