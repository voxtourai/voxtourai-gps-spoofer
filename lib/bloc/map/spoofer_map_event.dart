import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
abstract class SpooferMapEvent {
  const SpooferMapEvent();
}

class SpooferMapInitialized extends SpooferMapEvent {
  const SpooferMapInitialized();
}

class SpooferMapCurrentPositionSetRequested extends SpooferMapEvent {
  const SpooferMapCurrentPositionSetRequested({
    required this.position,
    this.updateLastInjected = false,
  });

  final LatLng? position;
  final bool updateLastInjected;
}

class SpooferMapLastInjectedPositionSetRequested extends SpooferMapEvent {
  const SpooferMapLastInjectedPositionSetRequested({required this.position});

  final LatLng? position;
}

class SpooferMapPolylinesSetRequested extends SpooferMapEvent {
  const SpooferMapPolylinesSetRequested({required this.polylines});

  final Set<Polyline> polylines;
}

class SpooferMapMarkersSetRequested extends SpooferMapEvent {
  const SpooferMapMarkersSetRequested({required this.markers});

  final Set<Marker> markers;
}

class SpooferMapAutoFollowSetRequested extends SpooferMapEvent {
  const SpooferMapAutoFollowSetRequested({required this.value});

  final bool value;
}

class SpooferMapPendingFitRouteSetRequested extends SpooferMapEvent {
  const SpooferMapPendingFitRouteSetRequested({required this.value});

  final bool value;
}

class SpooferMapProgrammaticMoveSetRequested extends SpooferMapEvent {
  const SpooferMapProgrammaticMoveSetRequested({required this.value});

  final bool value;
}

class SpooferMapLastMapStyleDarkSetRequested extends SpooferMapEvent {
  const SpooferMapLastMapStyleDarkSetRequested({required this.value});

  final bool? value;
}
