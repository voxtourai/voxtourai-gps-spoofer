# GPS Spoofer — Project Notes

## Context
- Intended as an open-source GPS spoofing app (name TBD).
- Lower priority than TTS work; do not switch focus prematurely.

## Product sketch (from meeting)
- Flutter app, initially Android; iOS likely later.
- Minimal structure: `lib/` + `android/` only (no web/BFF/etc).
- Input: a route/path file (described as a Google route response), split into segments of GPS points.
- User selects a path, sets movement speed, starts spoofing.
- Optional map view to display the polyline; reuse existing map widget if possible.

## Platform notes
- Use Android mock location API: switch from actual to mocked and stream location updates.
- Publish as a separate app under the existing WalksTo brand (exact name TBD).
- Free initially; consider ads/monetization after studying competitors.

## Configuration
- Google Maps key: add `MAPS_API_KEY=...` to `android/local.properties` (not committed).
- Route input: paste an encoded polyline or a Google Routes API JSON response
  (expected path: `routes[0].polyline.encodedPolyline`).

## Constraints / process
- Keep scope minimal and avoid extra complexity.
- If using shared libraries, coordinate and do not commit directly without review.
- Use branches for experiments and keep history clean.

## Next steps
See `TODO.md` for the milestone plan and task list.
