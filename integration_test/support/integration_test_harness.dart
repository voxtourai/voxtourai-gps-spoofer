import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voxtourai_gps_spoofer/app.dart';
import 'package:voxtourai_gps_spoofer/bloc/route/spoofer_route_bloc.dart';
import 'package:voxtourai_gps_spoofer/service/infrastructure/mock_location_gateway.dart';
import 'package:voxtourai_gps_spoofer/service/infrastructure/preferences_store.dart';
import 'package:voxtourai_gps_spoofer/model/saved_route.dart';
import 'package:voxtourai_gps_spoofer/ui/screens/spoofer_screen.dart';

class RecordedMockLocationCall {
  const RecordedMockLocationCall({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speedMps,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double speedMps;
}

class RecordingMockLocationGateway extends MockLocationGateway {
  RecordingMockLocationGateway({
    this.currentLocation,
    this.lastKnownLocation,
    this.developerModeEnabled = true,
    this.mockLocationAppSelected = true,
    this.selectedMockApp = 'GPS Spoofer',
    this.geocodeResults = const <Map<String, Object?>>[],
  });

  final List<RecordedMockLocationCall> setMockLocationCalls =
      <RecordedMockLocationCall>[];
  final List<Map<String, Object?>> geocodeResults;

  LatLng? currentLocation;
  LatLng? lastKnownLocation;
  bool developerModeEnabled;
  bool mockLocationAppSelected;
  String? selectedMockApp;
  int clearMockLocationCount = 0;
  int openDeveloperSettingsCount = 0;

  @override
  Future<Map<String, Object?>?> setMockLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speedMps,
  }) async {
    setMockLocationCalls.add(
      RecordedMockLocationCall(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        speedMps: speedMps,
      ),
    );
    currentLocation = LatLng(latitude, longitude);
    lastKnownLocation ??= currentLocation;
    return <String, Object?>{
      'gpsApplied': true,
      'mockAppSelected': mockLocationAppSelected,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speedMps': speedMps,
    };
  }

  @override
  Future<Map<String, Object?>?> clearMockLocation() async {
    clearMockLocationCount += 1;
    return <String, Object?>{'mockCleared': true, 'gpsApplied': false};
  }

  @override
  Future<LatLng?> getCurrentLocation() async => currentLocation;

  @override
  Future<LatLng?> getLastKnownLocation() async =>
      lastKnownLocation ?? currentLocation;

  @override
  Future<Map<String, Object?>?> getMockDebug() async {
    return <String, Object?>{
      'developerModeEnabled': developerModeEnabled,
      'mockLocationAppSelected': mockLocationAppSelected,
      'selectedMockApp': selectedMockApp,
      'setMockLocationCalls': setMockLocationCalls.length,
      'clearMockLocationCount': clearMockLocationCount,
    };
  }

  @override
  Future<bool> isDeveloperModeEnabled() async => developerModeEnabled;

  @override
  Future<bool> isMockLocationApp() async => mockLocationAppSelected;

  @override
  Future<String?> getMockLocationApp() async => selectedMockApp;

  @override
  Future<void> openDeveloperSettings() async {
    openDeveloperSettingsCount += 1;
  }

  @override
  Future<List<Map<String, Object?>>> geocodeAddress(
    String query, {
    int maxResults = 8,
  }) async {
    return List<Map<String, Object?>>.from(geocodeResults.take(maxResults));
  }
}

class InMemoryPreferencesStore extends PreferencesStore {
  InMemoryPreferencesStore({
    this.tosAccepted = true,
    this.startupPromptsShown = true,
    List<SavedRoute>? savedRoutes,
  }) : _savedRoutes = List<SavedRoute>.from(savedRoutes ?? const []);

  bool tosAccepted;
  bool startupPromptsShown;
  final List<SavedRoute> _savedRoutes;

  @override
  Future<bool> isTosAccepted() async => tosAccepted;

  @override
  Future<void> setTosAccepted(bool accepted) async {
    tosAccepted = accepted;
  }

  @override
  Future<bool> isStartupPromptsShown() async => startupPromptsShown;

  @override
  Future<void> setStartupPromptsShown(bool shown) async {
    startupPromptsShown = shown;
  }

  @override
  Future<List<SavedRoute>> loadSavedRoutes() async {
    return List<SavedRoute>.from(_savedRoutes);
  }

  @override
  Future<void> saveRoutes(List<SavedRoute> routes) async {
    _savedRoutes
      ..clear()
      ..addAll(routes);
  }

  @override
  Future<void> upsertSavedRoute({
    required String name,
    required List<LatLng> points,
    required List<String> names,
  }) async {
    final entry = SavedRoute(
      name: name,
      points: List<LatLng>.unmodifiable(points),
      waypointNames: List<String>.unmodifiable(names),
    );
    final index = _savedRoutes.indexWhere((route) => route.name == name);
    if (index >= 0) {
      _savedRoutes[index] = entry;
    } else {
      _savedRoutes.add(entry);
    }
  }
}

class IntegrationTestAppHarness {
  IntegrationTestAppHarness({
    RecordingMockLocationGateway? mockGateway,
    InMemoryPreferencesStore? preferencesStore,
    this.playbackTickInterval = const Duration(milliseconds: 10),
  }) : mockGateway = mockGateway ?? RecordingMockLocationGateway(),
       preferencesStore = preferencesStore ?? InMemoryPreferencesStore();

  final RecordingMockLocationGateway mockGateway;
  final InMemoryPreferencesStore preferencesStore;
  final Duration playbackTickInterval;

  Widget buildApp() {
    return GpsSpooferApp(
      dependencies: GpsSpooferAppDependencies(
        mockGateway: mockGateway,
        preferencesStore: preferencesStore,
        playbackTickInterval: playbackTickInterval,
        requestLocationPermission: () async => true,
        openAppSettingsAction: () async => true,
      ),
      screenLaunchOptions: const SpooferScreenLaunchOptions(
        initializeNotifications: false,
        manageBackgroundNotifications: false,
        runFirstLaunchPrompts: false,
        enableBackgroundModeOnLaunch: false,
        runStartupChecksOnLaunch: false,
      ),
    );
  }
}

Future<void> pumpIntegrationApp(
  WidgetTester tester,
  IntegrationTestAppHarness harness,
) async {
  await tester.pumpWidget(harness.buildApp());
  await pumpFrames(tester, count: 8);
}

Future<void> pumpFrames(
  WidgetTester tester, {
  int count = 1,
  Duration step = const Duration(milliseconds: 150),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

Future<void> waitForCondition(
  WidgetTester tester,
  bool Function() condition, {
  int maxPumps = 30,
  Duration step = const Duration(milliseconds: 150),
  String reason = 'Timed out waiting for condition.',
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (condition()) {
      return;
    }
    await tester.pump(step);
  }
  if (!condition()) {
    fail(reason);
  }
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
  Duration step = const Duration(milliseconds: 150),
  String? reason,
}) async {
  await waitForCondition(
    tester,
    () => finder.evaluate().isNotEmpty,
    maxPumps: maxPumps,
    step: step,
    reason: reason ?? 'Timed out waiting for ${finder.description}.',
  );
}

Future<void> tapTooltip(
  WidgetTester tester,
  String tooltip, {
  bool useLast = false,
  int beforeTapFrames = 2,
  int afterTapFrames = 2,
}) async {
  final finder = find.byTooltip(tooltip);
  await waitForFinder(
    tester,
    finder,
    reason: 'Could not find tooltip "$tooltip".',
  );
  if (beforeTapFrames > 0) {
    await pumpFrames(tester, count: beforeTapFrames);
  }
  final target = useLast ? finder.last : finder.first;
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  if (afterTapFrames > 0) {
    await pumpFrames(tester, count: afterTapFrames);
  } else {
    await tester.pump();
  }
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool useLast = false,
  int beforeTapFrames = 2,
  int afterTapFrames = 2,
}) async {
  final finder = find.text(text);
  await waitForFinder(tester, finder, reason: 'Could not find text "$text".');
  if (beforeTapFrames > 0) {
    await pumpFrames(tester, count: beforeTapFrames);
  }
  final target = useLast ? finder.last : finder.first;
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  if (afterTapFrames > 0) {
    await pumpFrames(tester, count: afterTapFrames);
  } else {
    await tester.pump();
  }
}

Future<void> tapFinder(
  WidgetTester tester,
  Finder finder, {
  int beforeTapFrames = 2,
  int afterTapFrames = 2,
  String? reason,
}) async {
  await waitForFinder(
    tester,
    finder,
    reason: reason ?? 'Could not find ${finder.description}.',
  );
  if (beforeTapFrames > 0) {
    await pumpFrames(tester, count: beforeTapFrames);
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  if (afterTapFrames > 0) {
    await pumpFrames(tester, count: afterTapFrames);
  } else {
    await tester.pump();
  }
}

T readBloc<T>(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(Scaffold).first);
  return context.read<T>();
}

Future<void> loadDemoRoute(WidgetTester tester) async {
  final routeBloc = readBloc<SpooferRouteBloc>(tester);
  await tapTooltip(tester, 'Load route');
  await tapText(tester, 'Demo');
  await tapText(tester, 'Load');
  await waitForCondition(
    tester,
    () => routeBloc.state.hasRoute,
    reason: 'Route did not load from the demo input.',
  );
}
