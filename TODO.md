# BLoC Migration TODO

This file tracks the BLoC migration plan for the GPS spoofer app.
As each chunk is implemented, remove that chunk from this file.

## Chunk 7: Controller retirement
- Remove legacy `ChangeNotifier` controllers that are fully replaced.
- Remove dead widget state and unused helper methods.
- Goal: Feature parity with cleaner, event-driven structure.

## Chunk 8: Hardening + docs
- Run `flutter analyze`.
- Add unit tests for core BLoC transitions.
- Document BLoC architecture and event/state contracts in README.
- Goal: Stable baseline with documented architecture.
