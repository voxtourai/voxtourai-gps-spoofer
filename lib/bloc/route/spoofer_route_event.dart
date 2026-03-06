import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
abstract class SpooferRouteEvent {
  const SpooferRouteEvent();
}

class SpooferRouteInitialized extends SpooferRouteEvent {
  const SpooferRouteInitialized();
}

class SpooferRouteLoadRequested extends SpooferRouteEvent {
  const SpooferRouteLoadRequested({required this.input});

  final String input;
}

class SpooferRouteClearRequested extends SpooferRouteEvent {
  const SpooferRouteClearRequested();
}

class SpooferRouteProgressSetRequested extends SpooferRouteEvent {
  const SpooferRouteProgressSetRequested({required this.progress});

  final double progress;
}

class SpooferRouteWaypointAddedRequested extends SpooferRouteEvent {
  const SpooferRouteWaypointAddedRequested({required this.position});

  final LatLng position;
}

class SpooferRouteWaypointUpdatedRequested extends SpooferRouteEvent {
  const SpooferRouteWaypointUpdatedRequested({
    required this.index,
    required this.position,
  });

  final int index;
  final LatLng position;
}

class SpooferRouteWaypointRemovedRequested extends SpooferRouteEvent {
  const SpooferRouteWaypointRemovedRequested({required this.index});

  final int index;
}

class SpooferRouteWaypointSelectedRequested extends SpooferRouteEvent {
  const SpooferRouteWaypointSelectedRequested({required this.index});

  final int? index;
}

class SpooferRouteWaypointRenamedRequested extends SpooferRouteEvent {
  const SpooferRouteWaypointRenamedRequested({
    required this.index,
    required this.name,
  });

  final int index;
  final String name;
}

class SpooferRouteWaypointsReorderedRequested extends SpooferRouteEvent {
  const SpooferRouteWaypointsReorderedRequested({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;
}

class SpooferRouteSavedRoutesLoadRequested extends SpooferRouteEvent {
  const SpooferRouteSavedRoutesLoadRequested();
}

class SpooferRouteSavedRouteSaveRequested extends SpooferRouteEvent {
  const SpooferRouteSavedRouteSaveRequested({required this.name});

  final String name;
}

class SpooferRouteSavedRouteDeleteRequested extends SpooferRouteEvent {
  const SpooferRouteSavedRouteDeleteRequested({required this.index});

  final int index;
}

class SpooferRouteSavedRouteApplyRequested extends SpooferRouteEvent {
  const SpooferRouteSavedRouteApplyRequested({required this.index});

  final int index;
}
