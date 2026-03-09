import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voxtourai_gps_spoofer/bloc/playback/spoofer_playback_state.dart';
import 'package:voxtourai_gps_spoofer/bloc/route/spoofer_route_state.dart';
import 'package:voxtourai_gps_spoofer/service/route_playback_math.dart';

void main() {
  const routePlaybackMath = RoutePlaybackMath();

  group('RoutePlaybackMath', () {
    test('returns null for tick resolution when route is unavailable', () {
      const route = SpooferRouteState();
      const playback = SpooferPlaybackState(
        isPlaying: true,
        tickDeltaSeconds: 0.1,
      );

      final result = routePlaybackMath.resolvePlaybackTick(
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

      final result = routePlaybackMath.resolvePlaybackTick(
        routeState: route,
        playbackState: playback,
      );

      expect(result, isNotNull);
      expect(result!.progress, 1.0);
      expect(result.boundary, PlaybackBoundary.end);
    });

    test('resolves progress at start boundary when reversing past zero', () {
      const route = SpooferRouteState(
        routePoints: <LatLng>[
          LatLng(43.6532, -79.3832),
          LatLng(43.7000, -79.4000),
        ],
        progress: 0.05,
        totalDistanceMeters: 100,
      );
      const playback = SpooferPlaybackState(
        isPlaying: true,
        speedMps: -100,
        tickDeltaSeconds: 0.1,
      );

      final result = routePlaybackMath.resolvePlaybackTick(
        routeState: route,
        playbackState: playback,
      );

      expect(result, isNotNull);
      expect(result!.progress, 0.0);
      expect(result.boundary, PlaybackBoundary.start);
    });

    test('returns zero total distance for fewer than two points', () {
      expect(routePlaybackMath.totalDistanceMeters(const <LatLng>[]), 0.0);
      expect(
        routePlaybackMath.totalDistanceMeters(const <LatLng>[LatLng(0.0, 0.0)]),
        0.0,
      );
    });

    test('interpolates map position for partial progress', () {
      const route = SpooferRouteState(
        routePoints: <LatLng>[LatLng(0.0, 0.0), LatLng(0.0, 1.0)],
        totalDistanceMeters: 1000,
      );

      final position = routePlaybackMath.positionForProgress(
        points: route.routePoints,
        totalDistanceMeters: route.totalDistanceMeters,
        progress: 0.5,
      );

      expect(position, isNotNull);
      expect(position!.latitude, closeTo(0.0, 0.000001));
      expect(position.longitude, closeTo(0.0045, 0.001));
    });

    test('clamps out-of-range progress to route endpoints', () {
      const points = <LatLng>[LatLng(0.0, 0.0), LatLng(0.0, 1.0)];
      final totalDistanceMeters = routePlaybackMath.totalDistanceMeters(points);

      final beforeStart = routePlaybackMath.positionForProgress(
        points: points,
        totalDistanceMeters: totalDistanceMeters,
        progress: -1,
      );
      final afterEnd = routePlaybackMath.positionForProgress(
        points: points,
        totalDistanceMeters: totalDistanceMeters,
        progress: 2,
      );

      expect(beforeStart, points.first);
      expect(afterEnd, points.last);
    });

    test('returns the first point when total distance is zero', () {
      const points = <LatLng>[LatLng(1.0, 1.0), LatLng(1.0, 1.0)];

      final position = routePlaybackMath.positionForProgress(
        points: points,
        totalDistanceMeters: 0,
        progress: 0.5,
      );

      expect(position, points.first);
    });
  });
}
