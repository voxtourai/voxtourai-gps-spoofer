# BLoC Migration TODO

This file tracks the BLoC migration plan for the GPS spoofer app.
As each chunk is implemented, remove that chunk from this file.

## Chunk 1: BLoC scaffolding and wiring shell
- Add `flutter_bloc` to dependencies.
- Create BLoC folder structure:
  - `lib/spoofer/bloc/route/`
  - `lib/spoofer/bloc/playback/`
  - `lib/spoofer/bloc/mock/`
  - `lib/spoofer/bloc/map/`
- Add initial `event/state/bloc` files for each domain.
- Wrap app/screen with `MultiBlocProvider` while keeping current controllers active.
- Goal: No behavior changes yet.

## Chunk 2: Route + waypoint migration
- Move route parsing/progress/waypoint CRUD/saved routes into `SpooferRouteBloc`.
- Replace route/waypoint controller reads in UI with `BlocBuilder`.
- Goal: Route load/clear/demo/manual waypoints/save-load routes keep current behavior.

## Chunk 3: Playback migration
- Move play/pause/speed/tick logic into `SpooferPlaybackBloc`.
- Dispatch tick events from bloc-managed timer.
- Goal: Slider + play behavior remains unchanged.

## Chunk 4: Mock/setup/status migration
- Move startup checks, setup checks, permission state, mock apply/clear, debug logs into `SpooferMockBloc`.
- Use `BlocListener` for one-shot UI events (toasts/dialog triggers).
- Goal: Setup and mock status features remain unchanged.

## Chunk 5: Map interaction migration
- Move map tap/long-press/recenter/fit-route/autofollow events into `SpooferMapBloc`.
- Move marker/polyline view-model generation into map bloc.
- Goal: Current map behavior and controls remain unchanged.

## Chunk 6: Cross-bloc coordination
- Define explicit coordination points:
  - route + playback -> target position
  - position -> mock apply + map follow
- Keep first pass in screen listeners, then move to a small coordinator service if needed.
- Goal: No regressions in auto-follow, playback, manual/search set.

## Chunk 7: Controller retirement
- Remove legacy `ChangeNotifier` controllers that are fully replaced.
- Remove dead widget state and unused helper methods.
- Goal: Feature parity with cleaner, event-driven structure.

## Chunk 8: Hardening + docs
- Run `flutter analyze`.
- Add unit tests for core BLoC transitions.
- Document BLoC architecture and event/state contracts in README.
- Goal: Stable baseline with documented architecture.
