import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

import '../../model/saved_route.dart';

part 'spoofer_route_state.g.dart';

@immutable
class SpooferRouteStateMessage {
  const SpooferRouteStateMessage({required this.id, required this.text});

  final int id;
  final String text;
}

@immutable
@CopyWith()
class SpooferRouteState {
  const SpooferRouteState({
    this.initialized = false,
    this.revision = 0,
    this.routePoints = const <LatLng>[],
    this.progress = 0,
    this.totalDistanceMeters = 0,
    this.currentRoutePosition,
    this.waypointPoints = const <LatLng>[],
    this.waypointNames = const <String>[],
    this.selectedWaypointIndex,
    this.usingCustomRoute = false,
    this.savedRoutes = const <SavedRoute>[],
    this.savedRoutesLoaded = false,
    this.message,
  });

  final bool initialized;
  final int revision;
  final List<LatLng> routePoints;
  final double progress;
  final double totalDistanceMeters;
  final LatLng? currentRoutePosition;
  final List<LatLng> waypointPoints;
  final List<String> waypointNames;
  final int? selectedWaypointIndex;
  final bool usingCustomRoute;
  final List<SavedRoute> savedRoutes;
  final bool savedRoutesLoaded;
  final SpooferRouteStateMessage? message;

  bool get hasRoute => routePoints.length >= 2;
  bool get hasPoints => routePoints.isNotEmpty;
  bool get hasWaypointPoints => waypointPoints.isNotEmpty;
  double get progressDistance => totalDistanceMeters * progress;
}
