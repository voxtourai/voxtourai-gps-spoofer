import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/playback/spoofer_playback_state.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/route/spoofer_route_state.dart';
import 'package:voxtourai_gps_spoofer/spoofer/coordinator/spoofer_runtime_coordinator.dart';

void main() {
  const coordinator = SpooferRuntimeCoordinator();

  group('SpooferRuntimeCoordinator', () {
    test('returns null for tick resolution when route is unavailable', () {
      const route = SpooferRouteState();
      const playback = SpooferPlaybackState(
        isPlaying: true,
        tickDeltaSeconds: 0.1,
      );

      final result = coordinator.resolvePlaybackTick(
        routeState: route,
        playbackState: playback,
      );

      expect(result, isNull);
    });

    test('resolves progress at end boundary', () {
      const route = SpooferRouteState(
        routePoints: <LatLng>[
          LatLng(43.6532, -79.3832),
          LatLng(43.7000, -79.4000),
        ],
        progress: 0.95,
        totalDistanceMeters: 100,
      );
      const playback = SpooferPlaybackState(
        isPlaying: true,
        speedMps: 100,
        tickDeltaSeconds: 0.1,
      );

      final result = coordinator.resolvePlaybackTick(
        routeState: route,
        playbackState: playback,
      );

      expect(result, isNotNull);
      expect(result!.progress, 1.0);
      expect(result.boundary, PlaybackBoundary.end);
    });

    test('interpolates map position for partial progress', () {
      const route = SpooferRouteState(
        routePoints: <LatLng>[
          LatLng(0.0, 0.0),
          LatLng(0.0, 1.0),
        ],
        totalDistanceMeters: 1000,
      );

      final position = coordinator.positionForProgress(route, 0.5);

      expect(position, isNotNull);
      expect(position!.latitude, closeTo(0.0, 0.000001));
      expect(position.longitude, closeTo(0.0045, 0.001));
    });
  });
}
