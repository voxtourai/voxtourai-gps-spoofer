import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
class SpooferMapState {
  const SpooferMapState({
    this.initialized = false,
    this.currentPosition,
    this.lastInjectedPosition,
    this.polylines = const <Polyline>{},
    this.markers = const <Marker>{},
    this.autoFollowEnabled = true,
    this.pendingFitRoute = false,
    this.isProgrammaticMove = false,
    this.lastMapStyleDark,
  });

  final bool initialized;
  final LatLng? currentPosition;
  final LatLng? lastInjectedPosition;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final bool autoFollowEnabled;
  final bool pendingFitRoute;
  final bool isProgrammaticMove;
  final bool? lastMapStyleDark;

  SpooferMapState copyWith({
    bool? initialized,
    LatLng? currentPosition,
    bool clearCurrentPosition = false,
    LatLng? lastInjectedPosition,
    bool clearLastInjectedPosition = false,
    Set<Polyline>? polylines,
    Set<Marker>? markers,
    bool? autoFollowEnabled,
    bool? pendingFitRoute,
    bool? isProgrammaticMove,
    bool? lastMapStyleDark,
    bool clearLastMapStyleDark = false,
  }) {
    return SpooferMapState(
      initialized: initialized ?? this.initialized,
      currentPosition: clearCurrentPosition ? null : (currentPosition ?? this.currentPosition),
      lastInjectedPosition: clearLastInjectedPosition
          ? null
          : (lastInjectedPosition ?? this.lastInjectedPosition),
      polylines: polylines ?? this.polylines,
      markers: markers ?? this.markers,
      autoFollowEnabled: autoFollowEnabled ?? this.autoFollowEnabled,
      pendingFitRoute: pendingFitRoute ?? this.pendingFitRoute,
      isProgrammaticMove: isProgrammaticMove ?? this.isProgrammaticMove,
      lastMapStyleDark: clearLastMapStyleDark ? null : (lastMapStyleDark ?? this.lastMapStyleDark),
    );
  }
}
