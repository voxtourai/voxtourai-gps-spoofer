import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voxtourai_gps_spoofer/bloc/playback/spoofer_playback_bloc.dart';
import 'package:voxtourai_gps_spoofer/bloc/route/spoofer_route_bloc.dart';
import 'package:voxtourai_gps_spoofer/bloc/settings/spoofer_settings_bloc.dart';
import 'package:voxtourai_gps_spoofer/models/saved_route.dart';

import 'support/integration_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads demo route, starts playback, and applies mock locations', (
    tester,
  ) async {
    final harness = IntegrationTestAppHarness();
    await pumpIntegrationApp(tester, harness);
    await loadDemoRoute(tester);

    final routeBloc = readBloc<SpooferRouteBloc>(tester);
    final playbackBloc = readBloc<SpooferPlaybackBloc>(tester);

    expect(routeBloc.state.hasRoute, isTrue);
    expect(routeBloc.state.progress, 0);

    await tapTooltip(tester, 'Play');
    await waitForCondition(
      tester,
      () =>
          playbackBloc.state.isPlaying &&
          routeBloc.state.progress > 0 &&
          harness.mockGateway.setMockLocationCalls.isNotEmpty,
      maxPumps: 40,
      step: const Duration(milliseconds: 100),
      reason: 'Playback did not advance the route or apply mock locations.',
    );

    expect(playbackBloc.state.isPlaying, isTrue);
    expect(harness.mockGateway.setMockLocationCalls, isNotEmpty);
    expect(routeBloc.state.progress, greaterThan(0));

    await tapTooltip(tester, 'Pause');
    await waitForCondition(
      tester,
      () => !playbackBloc.state.isPlaying,
      reason: 'Playback did not pause.',
    );
  });

  testWidgets('clears an active route and stops playback', (tester) async {
    final harness = IntegrationTestAppHarness();
    await pumpIntegrationApp(tester, harness);
    await loadDemoRoute(tester);

    final routeBloc = readBloc<SpooferRouteBloc>(tester);
    final playbackBloc = readBloc<SpooferPlaybackBloc>(tester);

    await tapTooltip(tester, 'Play');
    await waitForCondition(
      tester,
      () => routeBloc.state.progress > 0,
      maxPumps: 40,
      step: const Duration(milliseconds: 100),
      reason: 'Playback never advanced before the clear flow.',
    );

    await tapTooltip(tester, 'Clear route');
    final clearRouteButton = find.widgetWithText(FilledButton, 'Clear route');
    await waitForFinder(
      tester,
      clearRouteButton,
      reason: 'Clear route confirmation did not appear.',
    );
    await tester.tap(clearRouteButton);
    await tester.pump();

    await waitForCondition(
      tester,
      () => !routeBloc.state.hasPoints && !playbackBloc.state.isPlaying,
      reason: 'Route clear did not remove the route and stop playback.',
    );

    expect(routeBloc.state.hasRoute, isFalse);
    expect(routeBloc.state.progress, 0);
    expect(playbackBloc.state.isPlaying, isFalse);
  });

  testWidgets('loads a saved custom route from the waypoint sheet', (
    tester,
  ) async {
    final harness = IntegrationTestAppHarness(
      preferencesStore: InMemoryPreferencesStore(
        savedRoutes: <SavedRoute>[
          SavedRoute(
            name: 'Saved Waterfront Route',
            points: const <LatLng>[
              LatLng(43.64073, -79.37637),
              LatLng(43.64192, -79.37414),
              LatLng(43.64323, -79.37191),
            ],
            waypointNames: const <String>['Start', 'Midpoint', 'Finish'],
          ),
        ],
      ),
    );

    await pumpIntegrationApp(tester, harness);

    final routeBloc = readBloc<SpooferRouteBloc>(tester);

    await tapTooltip(tester, 'Waypoints', afterTapFrames: 4);
    await tapFinder(
      tester,
      find.widgetWithIcon(IconButton, Icons.folder_open),
      beforeTapFrames: 2,
      afterTapFrames: 4,
      reason: 'Waypoint sheet load-route action did not appear.',
    );
    await tapText(
      tester,
      'Saved Waterfront Route',
      beforeTapFrames: 2,
      afterTapFrames: 3,
    );

    await waitForCondition(
      tester,
      () => routeBloc.state.hasRoute && routeBloc.state.usingCustomRoute,
      reason: 'Saved route was not applied from the waypoint sheet.',
    );

    expect(routeBloc.state.waypointNames, const <String>[
      'Start',
      'Midpoint',
      'Finish',
    ]);
    expect(routeBloc.state.waypointPoints.length, 3);
    expect(routeBloc.state.savedRoutesLoaded, isTrue);
  });

  testWidgets('settings sheet toggles setup bar and disables mock location', (
    tester,
  ) async {
    final harness = IntegrationTestAppHarness();
    await pumpIntegrationApp(tester, harness);

    final settingsBloc = readBloc<SpooferSettingsBloc>(tester);

    expect(settingsBloc.state.showSetupBar, isFalse);
    expect(harness.mockGateway.clearMockLocationCount, 0);

    await tapTooltip(tester, 'Settings', afterTapFrames: 4);
    await tapFinder(
      tester,
      find.widgetWithText(ListTile, 'Show setup bar'),
      beforeTapFrames: 2,
      afterTapFrames: 3,
      reason: 'Settings sheet did not show the setup-bar toggle.',
    );
    await waitForCondition(
      tester,
      () => settingsBloc.state.showSetupBar,
      reason: 'Settings toggle did not enable the setup bar.',
    );

    await tapFinder(
      tester,
      find.widgetWithText(OutlinedButton, 'Disable mock location'),
      beforeTapFrames: 1,
      afterTapFrames: 3,
      reason: 'Disable mock location action did not appear.',
    );
    await waitForCondition(
      tester,
      () => harness.mockGateway.clearMockLocationCount == 1,
      reason: 'Disable mock location did not clear the injected location.',
    );

    expect(settingsBloc.state.showSetupBar, isTrue);
    expect(harness.mockGateway.clearMockLocationCount, 1);
  });
}
