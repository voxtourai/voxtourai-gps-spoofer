import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../bloc/route/spoofer_route_state.dart';

typedef WaypointTapHandler = void Function(int index);
typedef WaypointDragEndHandler = void Function(int index, LatLng position);

Set<Polyline> buildRoutePolylines(List<LatLng> points) {
  if (points.length < 2) {
    return const <Polyline>{};
  }
  return <Polyline>{
    Polyline(
      polylineId: const PolylineId('route'),
      color: const Color(0xFF448AFF),
      width: 4,
      points: points,
    ),
  };
}

Set<Marker> buildRouteMarkers({
  required SpooferRouteState routeState,
  required LatLng? currentPosition,
  required bool showMockMarker,
  required WaypointTapHandler onWaypointTap,
  required WaypointDragEndHandler onWaypointDragEnd,
}) {
  final markers = <Marker>{};

  if (showMockMarker && currentPosition != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Mocked GPS'),
        zIndexInt: 1,
      ),
    );
  }

  for (var i = 0; i < routeState.waypointPoints.length; i++) {
    markers.add(
      Marker(
        markerId: MarkerId('wp_$i'),
        position: routeState.waypointPoints[i],
        draggable: true,
        onDragEnd: (position) => onWaypointDragEnd(i, position),
        onTap: () => onWaypointTap(i),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == routeState.selectedWaypointIndex
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: routeState.waypointNames.length > i
              ? routeState.waypointNames[i]
              : defaultWaypointName(i),
          snippet: 'Hold and drag to move',
        ),
        zIndexInt: 2,
      ),
    );
  }

  return markers;
}

LatLngBounds boundsFromLatLngs(List<LatLng> points) {
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;

  for (final point in points.skip(1)) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLng = math.min(minLng, point.longitude);
    maxLng = math.max(maxLng, point.longitude);
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

String formatDistanceMeters(double meters) {
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)} m';
  }
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String defaultWaypointName(int index) => 'Waypoint ${index + 1}';
