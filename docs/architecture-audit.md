# Architecture Audit

This document is the chunk 1 output for the GPS spoofer refactor plan.
It defines the current ownership model, the structural problems to fix, the
target layout, and the behavior that must remain unchanged during chunk 2.
References to the old paths and class names below are historical on purpose.

## Scope

This audit is based on the current application wiring in:

- `lib/app.dart`
- `lib/ui/screens/spoofer_screen.dart`
- `lib/spoofer/bloc/**`
- `lib/spoofer/coordinator/spoofer_runtime_coordinator.dart`
- `lib/controllers/**`

## Current ownership

### App composition

`GpsSpooferApp` creates six blocs at application startup:

- `SpooferRouteBloc`
- `SpooferPlaybackBloc`
- `SpooferMockBloc`
- `SpooferMapBloc`
- `SpooferMessageBloc`
- `SpooferSettingsBloc`

This wiring lives in `lib/app.dart`.

### Route flow

`SpooferRouteBloc` owns:

- route parsing from encoded polyline or Routes API JSON
- route progress value
- current route position in state
- waypoint CRUD, rename, reorder, selection
- saved custom route persistence through `PreferencesController`
- route interpolation math and cumulative distance math

Important observation:
route interpolation already exists in `SpooferRouteBloc`, while similar math
also exists in `SpooferRuntimeCoordinator`.

### Playback flow

`SpooferPlaybackBloc` owns:

- play / pause state
- playback speed
- timer lifecycle
- tick sequence and tick delta timing
- app pause / resume playback continuation

This bloc is clean and self-contained.

### Mock-location flow

`SpooferMockBloc` owns:

- startup checks
- permission checks
- developer-mode and mock-app checks
- apply / clear mock location
- debug log
- prompt state and message state

Its external dependency is `MockLocationController`, which is a platform
channel adapter.

### Map flow

`SpooferMapBloc` owns:

- current position
- last injected position
- map markers
- map polylines
- auto-follow state
- pending fit state
- programmatic-move state
- last map style flag

This bloc is mostly a presentational cache for the map widget.

### Settings flow

`SpooferSettingsBloc` owns:

- mock-marker visibility
- setup bar visibility
- debug panel visibility
- background flags
- dark-mode setting

This bloc is UI state only.

### Message flow

`SpooferMessageBloc` owns:

- one-shot UI snack / overlay messages

This bloc is a very thin transport layer.

### Screen flow

`SpooferScreen` is currently doing more than view composition.
It owns substantial cross-bloc orchestration and device side effects:

- TOS gate
- first-launch prompts
- notification initialization and background notification actions
- route-state listener behavior
- mock-state listener behavior
- playback tick handling
- route progress to map position updates
- sending mocked GPS updates
- building route polylines
- building map markers
- camera follow / fit behavior
- search-screen navigation and callbacks
- settings-sheet callbacks

This means the screen is acting as the real runtime orchestrator.

### Coordinator and controllers

`SpooferRuntimeCoordinator` is a pure math helper.
It does not coordinate blocs, widget state, or external systems.

`MockLocationController` and `PreferencesController` are not controllers in the
MVC sense. They are adapters around platform-channel and local-persistence APIs.

## Structural findings

### 1. The `controllers/` folder is misnamed

Current files:

- `lib/controllers/mock_location_controller.dart`
- `lib/controllers/preferences_controller.dart`

These are infrastructure adapters, not application controllers.
Keeping the word `controller` here conflicts with the boss's expectation that
the BLoC layer is already the controller layer.

### 2. `SpooferRuntimeCoordinator` is misnamed

Current file:

- `lib/spoofer/coordinator/spoofer_runtime_coordinator.dart`

It performs route and playback math only.
The word `coordinator` implies cross-component orchestration, but the actual
orchestration still lives in `SpooferScreen`.

### 3. Route math is duplicated

Current duplication:

- `SpooferRouteBloc` has `_positionForProgress()` and related distance math.
- `SpooferRuntimeCoordinator` has `positionForProgress()` and related distance
  math.

Only one source of truth should exist for route interpolation.

### 4. Cross-bloc runtime flow is concentrated in the screen

Examples in `SpooferScreen`:

- playback tick -> route progress
- route progress -> map position
- map position -> mock location send
- route state -> map markers / polylines

This is the main reason the naming feels inconsistent today: the screen is
acting as the runtime controller even though the folder structure suggests that
the controller layer is elsewhere.

### 5. The `spoofer/` wrapper is redundant for this repo

Current structure:

- `lib/spoofer/bloc/**`
- `lib/spoofer/coordinator/**`

This repository is already the GPS spoofer app.
A top-level `spoofer/` feature wrapper adds nesting without adding a second
feature boundary.

### 6. `SpooferMapBloc` stores derived render artifacts

Markers and polylines are currently rebuilt from route and UI settings.
Those are derived values, not true independent domain state.

This is not the first refactor priority, but it should be treated as
presentational state, not business state.

### 7. Not every extra bloc needs to be removed in the first pass

`SpooferMessageBloc` and `SpooferMapBloc` may be simplified later, but removing
them in the same refactor that changes folders and naming would increase risk.

The first structural pass should focus on:

- removing misleading names
- flattening the folder structure
- removing duplicated runtime math
- making ownership easier to explain

## Target structure

The recommended target layout is:

```text
lib/
  app.dart
  main.dart
  bloc/
    map/
    message/
    mock/
    playback/
    route/
    settings/
  domain/
    route_playback_math.dart
  infrastructure/
    mock_location_gateway.dart
    preferences_store.dart
  models/
    help_section.dart
  ui/
    help/
    map/
    screens/
    widgets/
```

## Target ownership

### BLoC layer

The BLoC layer remains the primary controller layer.
No new top-level `controller` or `coordinator` concept should be introduced.

### Domain layer

Pure math and feature rules that do not touch Flutter widgets, platform
channels, or persistence belong in `lib/domain/`.

For this repo, the first candidate is the current runtime math helper.

Recommended rename:

- `SpooferRuntimeCoordinator` -> `RoutePlaybackMath`

Recommended target file:

- `lib/domain/route_playback_math.dart`

### Infrastructure layer

Platform and persistence wrappers belong in `lib/infrastructure/`.

Recommended renames:

- `MockLocationController` -> `MockLocationGateway`
- `PreferencesController` -> `PreferencesStore`

These names describe what the classes actually do.

### UI layer

`SpooferScreen` should remain the view entry point, but chunk 2 should reduce
its responsibility to:

- widget composition
- navigation
- local widget-only presentation concerns

Cross-bloc runtime effects should become easier to locate and explain, even if
they temporarily remain in the screen during the first mechanical refactor.

## Old-to-new mapping

### Folder moves

- `lib/spoofer/bloc/map/**` -> `lib/bloc/map/**`
- `lib/spoofer/bloc/message/**` -> `lib/bloc/message/**`
- `lib/spoofer/bloc/mock/**` -> `lib/bloc/mock/**`
- `lib/spoofer/bloc/playback/**` -> `lib/bloc/playback/**`
- `lib/spoofer/bloc/route/**` -> `lib/bloc/route/**`
- `lib/spoofer/bloc/settings/**` -> `lib/bloc/settings/**`
- `lib/spoofer/coordinator/spoofer_runtime_coordinator.dart` ->
  `lib/domain/route_playback_math.dart`
- `lib/controllers/mock_location_controller.dart` ->
  `lib/infrastructure/mock_location_gateway.dart`
- `lib/controllers/preferences_controller.dart` ->
  `lib/infrastructure/preferences_store.dart`

### Import cleanup

After the moves:

- `lib/app.dart` imports should reference `lib/bloc/**` and
  `lib/infrastructure/**`
- `lib/ui/screens/spoofer_screen.dart` should import from `lib/bloc/**`,
  `lib/domain/**`, and `lib/infrastructure/**`
- tests should import from the new top-level paths

## Behavior invariants for chunk 2

The first refactor pass is structural.
These behaviors must remain unchanged:

1. Route input accepts encoded polyline and Routes API JSON.
2. Playback still supports play, pause, reverse speed, and progress scrubbing.
3. Route interpolation and route-end / route-start boundary handling remain
   correct.
4. Tapping / long-pressing the map still supports manual location set and
   custom route editing as it does now.
5. Saved-route load / save / apply / delete still works.
6. Mock-location startup checks, prompts, apply, clear, and debug logging still
   work.
7. Search still geocodes through the platform adapter and selects a map point.
8. Background notification behavior and reset action still work.
9. TOS acceptance and startup prompt persistence still work.
10. The current tests continue to pass after the structural move.

## Chunk 2 implementation rules

Chunk 2 should follow these rules:

1. Make the refactor mostly mechanical: moves, renames, import updates, and
   duplicate-math removal.
2. Do not remove blocs just because they are thin if that risks behavior churn.
3. Do not introduce a new "manager", "controller", or "coordinator" layer.
4. Keep one source of truth for route interpolation math.
5. Preserve public state and event names where possible to reduce test churn.

## Recommended next step

Chunk 2 should implement the folder flattening and renames first:

1. move blocs from `lib/spoofer/bloc/**` to `lib/bloc/**`
2. rename infrastructure adapters out of `controllers/`
3. rename and relocate the runtime math helper into `lib/domain/`
4. remove duplicated interpolation math from either the bloc or the helper so
   one implementation remains
5. run `flutter analyze` and `flutter test`
