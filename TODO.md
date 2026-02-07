# BLoC Migration TODO

This file tracks the BLoC migration plan for the GPS spoofer app.
As each chunk is implemented, remove that chunk from this file.

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
