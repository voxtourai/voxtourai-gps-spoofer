import '../../models/help_section.dart';

const List<HelpSection> helpSections = [
  HelpSection(
    'Getting started',
    [
      'Enable Developer Options and set this app as the mock location app.',
      'Grant location and notification permissions when prompted.',
      'Load a route or add custom waypoints, then press Play.',
    ],
  ),
  HelpSection(
    'Loading routes',
    [
      'Tap Load to paste an encoded polyline or Google Routes API JSON.',
      'Clear removes the active route and stops playback.',
      'When a route is loaded, Progress scrubs the route manually.',
    ],
  ),
  HelpSection(
    'Custom routes and waypoints',
    [
      'Long-press the map to add waypoints when no route is loaded.',
      'Drag a waypoint marker to move it, tap to select it.',
      'Use Delete/Rename or the Waypoints list to manage points.',
      'Save or load custom routes from the Waypoints list.',
    ],
  ),
  HelpSection(
    'Playback and speed',
    [
      'Play starts auto movement along the route.',
      'Speed is in m/s; negative values move in reverse.',
      'Speed 0 pauses movement without clearing the route.',
    ],
  ),
  HelpSection(
    'Map and camera',
    [
      'Recenter follows the current mock location on the map.',
      'Fit route zooms the map to the loaded path.',
      'Drag the map to stop auto-follow.',
      'Tap the map to set a single mock location when no route is active.',
    ],
  ),
  HelpSection(
    'Background mode',
    [
      'Enable Background mode in Settings to keep spoofing when minimized.',
      'Allow notification permission and battery optimization exemptions.',
      'A persistent notification indicates background mode is active.',
    ],
  ),
  HelpSection(
    'Dark mode',
    [
      'Use Settings to choose Off, On, UI only, or Map only.',
      'Map style updates when the app theme changes.',
    ],
  ),
  HelpSection(
    'Troubleshooting',
    [
      'If mock GPS is not applied, re-check mock app selection.',
      'Ensure location permission is granted and mock status is green.',
      'If other apps do not update, reopen them or check OS location settings.',
    ],
  ),
];
