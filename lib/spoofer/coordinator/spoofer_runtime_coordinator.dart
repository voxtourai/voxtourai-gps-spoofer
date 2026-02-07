import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/playback/spoofer_playback_state.dart';
import '../bloc/route/spoofer_route_state.dart';

enum PlaybackBoundary {
  none,
  start,
  end,
}

class PlaybackTickResolution {
  const PlaybackTickResolution({
    required this.progress,
    required this.boundary,
  });

  final double progress;
  final PlaybackBoundary boundary;
}

class SpooferRuntimeCoordinator {
  const SpooferRuntimeCoordinator();

  PlaybackTickResolution? resolvePlaybackTick({
    required SpooferRouteState routeState,
    required SpooferPlaybackState playbackState,
  }) {
    final deltaSeconds = playbackState.tickDeltaSeconds;
    if (deltaSeconds == null || !routeState.hasRoute) {
      return null;
    }

    final nextDistance = routeState.progressDistance + playbackState.speedMps * deltaSeconds;
    if (nextDistance >= routeState.totalDistanceMeters) {
      return const PlaybackTickResolution(
        progress: 1.0,
        boundary: PlaybackBoundary.end,
      );
    }
    if (nextDistance <= 0) {
      return const PlaybackTickResolution(
        progress: 0.0,
        boundary: PlaybackBoundary.start,
      );
    }

    return PlaybackTickResolution(
      progress: nextDistance / routeState.totalDistanceMeters,
      boundary: PlaybackBoundary.none,
    );
  }

  LatLng? positionForProgress(SpooferRouteState routeState, double progress) {
    final points = routeState.routePoints;
    if (points.isEmpty) {
      return null;
    }
    if (points.length == 1 || routeState.totalDistanceMeters <= 0) {
      return points.first;
    }

    final targetMeters = routeState.totalDistanceMeters * _clamp01(progress);

    var cumulative = 0.0;
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final segmentMeters = _distanceMeters(start, end);
      if (segmentMeters <= 0) {
        continue;
      }
      if (cumulative + segmentMeters >= targetMeters) {
        final remaining = targetMeters - cumulative;
        final t = remaining / segmentMeters;
        final lat = start.latitude + (end.latitude - start.latitude) * t;
        final lng = start.longitude + (end.longitude - start.longitude) * t;
        return LatLng(lat, lng);
      }
      cumulative += segmentMeters;
    }
    return points.last;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final aa = sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return earthRadius * c;
  }

  double _degToRad(double degrees) => degrees * (math.pi / 180.0);

  double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}
