# GPS Spoofer

Android‑first Flutter app for mocking GPS location along a route or custom waypoints.

## Features
- Google Map view with route polyline and current mock marker.
- Load route from encoded polyline or Google Routes API JSON (`routes[0].polyline.encodedPolyline`).
- Manual progress scrub + play/pause autoplay.
- Speed control (m/s), supports reverse (negative speeds).
- Custom routes: long‑press to add waypoints, drag to move, rename/delete, reorder in list, and save/load routes.
- Search screen for device geocoding (no paid API) and quick mock location set.
- Background mode option (Android) with persistent notification.
- Debug panel (in Settings) with mock status + rolling log.
- Dark mode options (On / UI only / Map only / Off).
- TOS gate on first run.

## Setup
1. Resolve the Android Maps key:
   Generate `android/platform-secrets.properties`:
   `./scripts/grab-platform-secrets.sh`
   The script uses `MAPS_API_KEY_ANDROID` from the environment first, then falls back to the
   `maps-api-key-android` secret through `gcloud`.
   If `gcloud` does not already have a default project configured, set
   `GOOGLE_CLOUD_PROJECT=...` (or `GCLOUD_PROJECT=...`) before running the script.
   Or pass the key directly at build/run time:
   `MAPS_API_KEY=...`
2. Connect a physical Android device with Developer Options and USB debugging enabled.
3. Install/run the app, then select it as the mock location app in Android Developer Options.

Android builds fail fast if the Maps key cannot be resolved. The secret-grab script requires
`bash` and either `MAPS_API_KEY_ANDROID` in the environment or an authenticated `gcloud` setup.

## Run locally on Android

The supported spoofing workflow is a physical device; emulator support is not the target setup for mock-location testing.

Commands should be executed from the project root.

```shell
flutter run -d <device-id> lib/main.dart
```

If you use Android Studio / IntelliJ, select the shared `Main Local` run configuration from `.run/` and target your connected phone.

## Build APK locally

Commands should be executed from the project root.

```shell
flutter build apk --release
```

## Build AAB locally

Commands should be executed from the project root.

```shell
flutter build appbundle --release
```

Build commands use the same Maps key sources as local runs.

For Play-ready signing, configure `android/keystore.properties` from
`android/keystore.properties.example`, or set the `ANDROID_KEYSTORE_*`
environment variables before building.

If no release signing values are configured, release builds fall back to debug
signing for local smoke use only and are not uploadable to Google Play.

For the full repo-side release checklist, see
`docs/android-open-testing-checklist.md`.

## Usage
- Tap **Load** to paste a route; **Clear** removes it.
- **Play** follows the route automatically; scrub **Progress** to move manually.
- Long‑press map to add waypoints when no route is loaded.
- Use the Waypoints list to reorder/rename/delete and to save/load custom routes.
- Use Settings to run setup checks, enable background mode, and toggle debug panel.

## Notes
- Requires Android Developer Options with this app selected as mock location app.
- Device geocoding search quality depends on OS/geocoder availability.

## Architecture

The app is split into `bloc/`, `service/`, `model/`, and `ui/` layers:

For a meeting-ready walkthrough of the ownership model, runtime flow, and
verification story, see `docs/architecture-walkthrough.md`.

- `SpooferRouteBloc`
  - Owns route parsing, route progress, waypoint CRUD/reorder/rename, and saved custom routes.
  - Key events: load/clear/progress set, waypoint add/update/remove/select/rename/reorder, saved route load/save/delete/apply.
  - Key state: `routePoints`, `progress`, `totalDistanceMeters`, `waypointPoints`, `waypointNames`, `savedRoutes`, optional `message`.

- `SpooferPlaybackBloc`
  - Owns play/pause state, speed, app pause/resume behavior, and tick timer.
  - Key events: play/pause, speed set, lifecycle pause/resume, tick clock reset.
  - Key state: `isPlaying`, `speedMps`, `tickSequence`, `tickDeltaSeconds`, `resumeAfterPause`.

- `SpooferMockBloc`
  - Owns startup checks, mock status, mock apply/clear operations, prompt/message side effects, and debug log.
  - Key events: startup checks, prompt resolved, refresh status, apply/clear mock location, status/error/log updates.
  - Key state: permissions/dev/mock-app flags, last mock result, selected mock app, `mockError`, `debugLog`, optional `prompt` and `message`.

- `SpooferMapBloc`
  - Owns map UI state used by the screen: current/injected positions, markers/polylines, follow/fit/programmatic flags, map style mode cache.
  - Key events: set position/markers/polylines, toggle auto-follow, pending fit, programmatic move, map style dark flag.
  - Key state: `currentPosition`, `lastInjectedPosition`, `markers`, `polylines`, `autoFollowEnabled`, `pendingFitRoute`, `isProgrammaticMove`.

- `SpooferSettingsBloc`
  - Owns UI settings toggles and dark-mode preference.
  - Key events: setup/debug/mock-marker toggles, background mode flags, dark-mode setting changes.
  - Key state: `showSetupBar`, `showDebugPanel`, `showMockMarker`, `backgroundEnabled`, `backgroundBusy`, `backgroundNotificationShown`, `darkModeSetting`.

- `SpooferMessageBloc`
  - Owns one-shot UI messaging for snack/overlay notifications.
  - Key events: show message (`snack`/`overlay`) and clear message.
  - Key state: `message` with monotonic `id` and `type`.

- `RoutePlaybackMath`
  - Pure route/playback math used by the route BLoC and screen runtime:
    - playback tick -> next route progress (+ boundary handling)
    - route progress -> map position interpolation

- Service infrastructure adapters (non-BLoC):
  - `MockLocationGateway`: Android platform channel bridge for mock location operations.
  - `PreferencesStore`: persistence for TOS and saved custom routes.

## Testing

- Unit tests:
  - `test/spoofer_route_bloc_test.dart`
  - `test/spoofer_playback_bloc_test.dart`
  - `test/spoofer_mock_bloc_test.dart`
  - `test/spoofer_map_bloc_test.dart`
  - `test/route_playback_math_test.dart`
- Integration smoke:
  - `integration_test/app_smoke_test.dart`

IntelliJ shared run configs live in `.run/`:
- `Main Local`
- `Android Build`
- `Build APK`
- `Build App Bundle`
- `Grab Platform Secrets`
- `Grab Platform Secrets (WSL)`
- `Flutter Analyze`
- `Flutter Test All`
- `Route Bloc Tests`
- `Integration Smoke`
