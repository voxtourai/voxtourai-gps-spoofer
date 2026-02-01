# GPS Spoofer — Milestones & TODO

## Milestone 0 — Decisions & inputs
- Finalize app/repo name and store listing direction.
- Confirm route/path file format (segments + speed encoding).
- Define MVP scope (Android‑only, minimal UI).

## Milestone 1 — Project scaffold
- Create new Flutter project (Android only to start).
- Verify build/run on emulator or device.
- Set up minimal app shell (single screen).

## Milestone 2 — Route ingest + map display
- Implement path upload/import.
- Parse route file into segments and GPS points.
- Render polyline on map (reuse existing widget if feasible).

## Milestone 3 — Spoofing engine (Android)
- Implement mock location streaming.
- Add adjustable speed control.
- Start/stop controls with basic status UI.

## Milestone 4 — UX polish + checks
- Validate input errors and edge cases.
- Basic settings (units, speed presets).
- Document known limitations.

## Milestone 5 — Research & release prep
- Review competitor apps (e.g., Fake GPS) and monetization models.
- Decide monetization approach (if any).
- Evaluate iOS feasibility/timeline.
- Prepare store assets and publishing checklist.

## Notes
- Priority remains TTS; this is future work only.
- Keep changes on a branch until explicitly approved to merge.


2 sliders, 1 is progress, 1 is speed, play button, can be automatic or manual movement