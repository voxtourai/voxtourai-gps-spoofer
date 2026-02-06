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
