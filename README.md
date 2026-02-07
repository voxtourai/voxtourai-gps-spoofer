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
1. Set Google Maps key in `android/local.properties`:
   `MAPS_API_KEY=...`
2. Build/run with Flutter (Android).

## Usage
- Tap **Load** to paste a route; **Clear** removes it.
- **Play** follows the route automatically; scrub **Progress** to move manually.
- Long‑press map to add waypoints when no route is loaded.
- Use the Waypoints list to reorder/rename/delete and to save/load custom routes.
- Use Settings to run setup checks, enable background mode, and toggle debug panel.

## Notes
- Requires Android Developer Options with this app selected as mock location app.
- Device geocoding search quality depends on OS/geocoder availability.

## Architecture (BLoC)

The app uses feature BLoCs plus a small runtime coordinator:

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

- `SpooferRuntimeCoordinator`
  - Coordinates cross-BLoC runtime math for playback ticks and route interpolation:
    - playback tick -> next route progress (+ boundary handling)
    - route progress -> map position interpolation

## Testing

- Unit tests:
  - `test/spoofer_route_bloc_test.dart`
  - `test/spoofer_playback_bloc_test.dart`
  - `test/spoofer_mock_bloc_test.dart`
  - `test/spoofer_map_bloc_test.dart`
  - `test/spoofer_runtime_coordinator_test.dart`
- Integration smoke:
  - `integration_test/app_smoke_test.dart`

IntelliJ shared run configs live in `.run/`:
- `Flutter Analyze`
- `Flutter Test All`
- `Route Bloc Tests`
- `Integration Smoke`
