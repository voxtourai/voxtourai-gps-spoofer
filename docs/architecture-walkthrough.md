# Architecture Walkthrough

This document is the chunk 4 boss-facing walkthrough for the GPS spoofer repo.
It explains the current structure after the refactor in terms of ownership,
runtime flow, and verification.

## Summary

The app is organized around four top-level areas:

- `bloc/`: feature-level control logic and feature state
- `service/`: pure route/playback math plus infrastructure adapters
- `model/`: shared data models
- `ui/`: widget composition and screens

The important architectural point is that the BLoC layer is the controller
layer. There is no parallel controller stack anymore.

## Why This Structure

The current structure is meant to answer a simple question:
"Where does this responsibility belong?"

- If it is feature control flow or feature state, it belongs in a BLoC.
- If it is pure math with no side effects, it belongs in `service/`.
- If it touches Android platform APIs or local storage, it belongs in
  `service/infrastructure/`.
- If it is widget composition or visual behavior, it belongs in `ui/`.

That gives the repo a cleaner explanation than the previous
`controller` / `coordinator` naming:

- `RoutePlaybackMath` is not a coordinator. It is pure math.
- `MockLocationGateway` and `PreferencesStore` are not controllers. They are
  adapters.
- The feature BLoCs are the primary controllers.

## App Composition

`GpsSpooferApp` wires up six feature BLoCs at startup in `lib/app.dart`:

- `SpooferRouteBloc`
- `SpooferPlaybackBloc`
- `SpooferMockBloc`
- `SpooferMapBloc`
- `SpooferMessageBloc`
- `SpooferSettingsBloc`

The screen tree then reads and listens to those blocs rather than creating
another control layer on top of them.

## Layer Map

### `bloc/`

Feature-owned state machines:

- `route/`
- `playback/`
- `mock/`
- `map/`
- `message/`
- `settings/`

Each BLoC owns a narrow slice of app behavior and exposes explicit events and
state.

### `service/`

- `RoutePlaybackMath`

This is the shared source of truth for:

- total route distance calculation
- playback tick to next-progress resolution
- route progress to interpolated map position

It also contains `service/infrastructure/` for adapter-style services:

- `MockLocationGateway`
- `PreferencesStore`

These classes isolate the platform channel and local persistence details under
`service/infrastructure/` so the feature logic can stay testable.

### `ui/`

The UI layer renders map state, controls, sheets, dialogs, and screens.
`SpooferScreen` still performs runtime orchestration between blocs and device
effects through listeners, but it no longer competes with a second
controller/coordinator abstraction.

## BLoC Ownership

### `SpooferRouteBloc`

Owns:

- route parsing from encoded polyline or Routes API JSON
- route progress state
- current interpolated route position
- custom waypoint add/update/remove/select/rename/reorder
- saved custom route load/save/delete/apply

Key events:

- `SpooferRouteLoadRequested`
- `SpooferRouteClearRequested`
- `SpooferRouteProgressSetRequested`
- `SpooferRouteWaypointAddedRequested`
- `SpooferRouteWaypointUpdatedRequested`
- `SpooferRouteWaypointRemovedRequested`
- `SpooferRouteWaypointRenamedRequested`
- `SpooferRouteWaypointsReorderedRequested`
- `SpooferRouteSavedRoutesLoadRequested`
- `SpooferRouteSavedRouteSaveRequested`
- `SpooferRouteSavedRouteDeleteRequested`
- `SpooferRouteSavedRouteApplyRequested`

Key state:

- `routePoints`
- `progress`
- `totalDistanceMeters`
- `currentRoutePosition`
- `waypointPoints`
- `waypointNames`
- `selectedWaypointIndex`
- `savedRoutes`
- `message`

Collaborators:

- `RoutePlaybackMath`
- `PreferencesStore`

Why it exists:

This is the feature source of truth for what route is loaded and where the app
currently is along that route.

### `SpooferPlaybackBloc`

Owns:

- play/pause state
- playback speed
- tick timer lifecycle
- pause/resume behavior when the app background state changes

Key events:

- `SpooferPlaybackPlayRequested`
- `SpooferPlaybackPauseRequested`
- `SpooferPlaybackSpeedSetRequested`
- `SpooferPlaybackAppPaused`
- `SpooferPlaybackAppResumed`
- `SpooferPlaybackTickClockResetRequested`
- `SpooferPlaybackTicked`

Key state:

- `isPlaying`
- `speedMps`
- `tickSequence`
- `tickDeltaSeconds`
- `resumeAfterPause`

Why it exists:

Playback timing is independent from route content and independent from mock GPS
application, so it is kept as its own state machine.

### `SpooferMockBloc`

Owns:

- startup checks
- location permission status
- developer-options and mock-app selection status
- apply/clear mock location requests
- mock error state
- prompt state
- message state
- rolling debug log

Key events:

- `SpooferMockStartupChecksRequested`
- `SpooferMockPromptResolved`
- `SpooferMockRefreshStatusRequested`
- `SpooferMockApplyLocationRequested`
- `SpooferMockClearLocationRequested`
- `SpooferMockErrorSetRequested`
- `SpooferMockErrorClearedRequested`
- `SpooferMockDebugLogAppended`
- `SpooferMockMessageRequested`

Key state:

- `hasLocationPermission`
- `isDeveloperModeEnabled`
- `isMockLocationApp`
- `selectedMockApp`
- `lastMockStatus`
- `mockError`
- `prompt`
- `message`
- `debugLog`

Collaborator:

- `MockLocationGateway`

Why it exists:

All Android mock-location side effects and setup checks are centralized here so
platform behavior is not scattered across the UI tree.

### `SpooferMapBloc`

Owns:

- map-visible current position
- last injected position
- map markers
- map polylines
- auto-follow flag
- fit-route flag
- programmatic camera-move flag
- last map-style dark flag

Key events:

- `SpooferMapCurrentPositionSetRequested`
- `SpooferMapLastInjectedPositionSetRequested`
- `SpooferMapMarkersSetRequested`
- `SpooferMapPolylinesSetRequested`
- `SpooferMapAutoFollowSetRequested`
- `SpooferMapPendingFitRouteSetRequested`
- `SpooferMapProgrammaticMoveSetRequested`
- `SpooferMapLastMapStyleDarkSetRequested`

Key state:

- `currentPosition`
- `lastInjectedPosition`
- `markers`
- `polylines`
- `autoFollowEnabled`
- `pendingFitRoute`
- `isProgrammaticMove`
- `lastMapStyleDark`

Why it exists:

The map widget has interactive UI state that is easier to reason about when it
is explicit rather than buried inside the widget tree.

### `SpooferSettingsBloc`

Owns:

- setup bar visibility
- debug panel visibility
- mock marker visibility
- background mode flags
- dark mode setting

Key events:

- `SpooferSettingsShowSetupBarSetRequested`
- `SpooferSettingsShowDebugPanelSetRequested`
- `SpooferSettingsShowMockMarkerSetRequested`
- `SpooferSettingsBackgroundEnabledSetRequested`
- `SpooferSettingsBackgroundBusySetRequested`
- `SpooferSettingsBackgroundNotificationShownSetRequested`
- `SpooferSettingsDarkModeSetRequested`

Key state:

- `showSetupBar`
- `showDebugPanel`
- `showMockMarker`
- `backgroundEnabled`
- `backgroundBusy`
- `backgroundNotificationShown`
- `darkModeSetting`

Why it exists:

These are feature toggles and UI preferences that should survive screen rebuilds
without being mixed into unrelated feature state.

### `SpooferMessageBloc`

Owns:

- one-shot UI messages for snack/overlay display

Key events:

- `SpooferMessageShownRequested`
- `SpooferMessageClearedRequested`

Key state:

- `message`

Why it exists:

This keeps transient user-facing messaging separate from route, playback, and
mock state.

## Runtime Flows

### 1. Route load flow

1. User pastes an encoded polyline or Routes API JSON.
2. `SpooferRouteBloc` parses and decodes it.
3. `SpooferRouteBloc` computes `totalDistanceMeters` and
   `currentRoutePosition`.
4. `SpooferScreen` listens to route-state changes and rebuilds markers,
   polylines, and fit-to-route behavior.

### 2. Playback flow

1. User presses play.
2. `SpooferPlaybackBloc` starts its timer and emits ticks.
3. `SpooferScreen` listens for `tickSequence` changes.
4. `RoutePlaybackMath.resolvePlaybackTick()` converts the tick delta and speed
   into the next route progress value.
5. `SpooferScreen` applies that progress back into `SpooferRouteBloc`.
6. `RoutePlaybackMath.positionForProgress()` converts route progress into a map
   coordinate.
7. `SpooferScreen` sends that coordinate to `SpooferMockBloc`, which applies it
   through `MockLocationGateway`.

### 3. Manual/custom-route flow

1. User long-presses the map to add waypoints.
2. `SpooferRouteBloc` stores waypoint points and names.
3. `SpooferRouteBloc` rebuilds the custom route from the waypoint list.
4. `SpooferScreen` refreshes rendered markers/polylines and can send the
   resulting position to mock GPS when progress changes.

### 4. Startup-check flow

1. Screen requests startup checks after launch/TOS completion.
2. `SpooferMockBloc` verifies location permission.
3. It verifies developer mode.
4. It verifies whether this app is selected as the mock-location app.
5. If something is missing, it emits a prompt state.
6. The UI resolves that prompt and sends `SpooferMockPromptResolved`.
7. `SpooferMockBloc` opens app settings or developer options through
   `MockLocationGateway` / platform integrations.

## What Still Lives In The Screen

`SpooferScreen` still contains runtime composition logic that ties separate
feature blocs together:

- route-state listener behavior
- playback tick handling
- map marker/polyline refresh
- camera follow/fit behavior
- mock-location send on progress changes
- first-launch prompts and background-notification wiring

That is acceptable for the current repo state because:

- the feature ownership is now explicit
- the misleading controller/coordinator naming is gone
- the service math is centralized and testable
- the remaining screen orchestration is visible in one file

If this grows further, the next refactor target would be extracting some of the
screen runtime effects into a narrower application-service layer or smaller UI
coordinator widgets. That is not required to explain the app cleanly today.

## Verification Story

The verification approach is:

1. static analysis
2. focused unit tests around each feature state machine
3. integration smoke coverage
4. manual physical-device validation for the Android-specific mock-location path

### Automated checks

- `flutter analyze`
- `flutter test`

Current focused regression coverage includes:

- route parsing, route progress, custom waypoint flows, and saved-route flows
- playback timer and pause/resume behavior
- startup-check prompt branches and mock apply/clear failures
- route interpolation and playback boundary math

Relevant test files:

- `test/spoofer_route_bloc_test.dart`
- `test/spoofer_playback_bloc_test.dart`
- `test/spoofer_mock_bloc_test.dart`
- `test/spoofer_map_bloc_test.dart`
- `test/route_playback_math_test.dart`
- `integration_test/app_smoke_test.dart`

### Manual validation still required

Automated tests do not replace on-device verification for:

- Android Developer Options and mock-app selection behavior
- platform-channel behavior on a real phone
- Google Map rendering and camera UX
- background mode and notification behavior

## Short Version For Review Meetings

If asked to explain the architecture quickly:

1. The BLoCs are the controller layer.
2. `RoutePlaybackMath` is the pure math layer.
3. `MockLocationGateway` and `PreferencesStore` are infrastructure adapters.
4. `SpooferScreen` composes the feature blocs and coordinates UI/runtime effects.
5. The risky behavior is covered by route/playback/mock/math tests plus phone
   validation for Android-specific behavior.
