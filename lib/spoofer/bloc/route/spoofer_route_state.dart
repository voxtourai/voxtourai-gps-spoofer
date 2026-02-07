import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
class SpooferRouteStateMessage {
  const SpooferRouteStateMessage({
    required this.id,
    required this.text,
  });

  final int id;
  final String text;
}

@immutable
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
    this.savedRoutes = const <Map<String, Object?>>[],
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
  final List<Map<String, Object?>> savedRoutes;
  final bool savedRoutesLoaded;
  final SpooferRouteStateMessage? message;

  bool get hasRoute => routePoints.length >= 2;
  bool get hasPoints => routePoints.isNotEmpty;
  bool get hasWaypointPoints => waypointPoints.isNotEmpty;
  double get progressDistance => totalDistanceMeters * progress;

  SpooferRouteState copyWith({
    bool? initialized,
    int? revision,
    List<LatLng>? routePoints,
    double? progress,
    double? totalDistanceMeters,
    LatLng? currentRoutePosition,
    bool clearCurrentRoutePosition = false,
    List<LatLng>? waypointPoints,
    List<String>? waypointNames,
    int? selectedWaypointIndex,
    bool clearSelectedWaypointIndex = false,
    bool? usingCustomRoute,
    List<Map<String, Object?>>? savedRoutes,
    bool? savedRoutesLoaded,
    SpooferRouteStateMessage? message,
    bool clearMessage = false,
  }) {
    return SpooferRouteState(
      initialized: initialized ?? this.initialized,
      revision: revision ?? this.revision,
      routePoints: routePoints ?? this.routePoints,
      progress: progress ?? this.progress,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      currentRoutePosition: clearCurrentRoutePosition
          ? null
          : (currentRoutePosition ?? this.currentRoutePosition),
      waypointPoints: waypointPoints ?? this.waypointPoints,
      waypointNames: waypointNames ?? this.waypointNames,
      selectedWaypointIndex: clearSelectedWaypointIndex
          ? null
          : (selectedWaypointIndex ?? this.selectedWaypointIndex),
      usingCustomRoute: usingCustomRoute ?? this.usingCustomRoute,
      savedRoutes: savedRoutes ?? this.savedRoutes,
      savedRoutesLoaded: savedRoutesLoaded ?? this.savedRoutesLoaded,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
