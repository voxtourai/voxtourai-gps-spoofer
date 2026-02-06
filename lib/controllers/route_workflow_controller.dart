import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_state_controller.dart';
import 'route_controller.dart';
import 'waypoint_controller.dart';

class RouteWorkflowController extends ChangeNotifier {
  RouteWorkflowController({
    required MapStateController mapState,
    VoidCallback? onRouteEdited,
    VoidCallback? onMarkersChanged,
  })  : _mapState = mapState,
        _onRouteEdited = onRouteEdited,
        _onMarkersChanged = onMarkersChanged {
    _route.addListener(_notify);
    _waypoints.addListener(_notify);
  }

  final RouteController _route = RouteController();
  final WaypointController _waypoints = WaypointController();
  final MapStateController _mapState;
  VoidCallback? _onRouteEdited;
  VoidCallback? _onMarkersChanged;

  RouteController get route => _route;
  WaypointController get waypoints => _waypoints;
  MapStateController get mapState => _mapState;

  void setOnRouteEdited(VoidCallback? callback) {
    _onRouteEdited = callback;
  }

  void setOnMarkersChanged(VoidCallback? callback) {
    _onMarkersChanged = callback;
  }

  @override
  void dispose() {
    _route.removeListener(_notify);
    _waypoints.removeListener(_notify);
    _route.dispose();
    _waypoints.dispose();
    super.dispose();
  }

  void clearAll({bool resetPosition = true}) {
    _route.clear();
    _waypoints.clear();
    _mapState.setPolylines(const {});
    _mapState.setCustomMarkers(const {});
    _onMarkersChanged?.call();
    if (resetPosition) {
      _mapState.setCurrentPosition(null, updateLastInjected: true);
    }
  }

  void setRouteFromPoints(List<LatLng> points) {
    _waypoints.clear();
    _mapState.setCustomMarkers(const {});
    _onMarkersChanged?.call();
    _route.setRoute(points);
    _syncPolylines();
  }

  void rebuildFromWaypoints({bool resetPositionIfEmpty = true}) {
    if (_waypoints.points.isEmpty) {
      _route.clear();
      _mapState.setPolylines(const {});
      if (resetPositionIfEmpty) {
        _mapState.setCurrentPosition(null, updateLastInjected: true);
      }
      return;
    }
    _route.setRoute(List<LatLng>.from(_waypoints.points));
    _syncPolylines();
  }

  void addWaypoint(LatLng position) {
    _waypoints.addPoint(position);
    rebuildFromWaypoints();
    rebuildCustomMarkers();
    _onRouteEdited?.call();
  }

  void updateWaypoint(int index, LatLng position) {
    _waypoints.updatePoint(index, position);
    rebuildFromWaypoints(resetPositionIfEmpty: false);
    rebuildCustomMarkers();
    _onRouteEdited?.call();
  }

  void removeWaypoint(int index) {
    _waypoints.removePoint(index);
    rebuildFromWaypoints();
    rebuildCustomMarkers();
    _onRouteEdited?.call();
  }

  void selectWaypoint(int? index) {
    _waypoints.setSelectedIndex(index);
    rebuildCustomMarkers();
  }

  void renameWaypoint(int index, String name) {
    _waypoints.renamePoint(index, name);
    rebuildCustomMarkers();
  }

  void reorderWaypoints(int oldIndex, int newIndex) {
    _waypoints.reorder(oldIndex, newIndex);
    rebuildFromWaypoints(resetPositionIfEmpty: false);
    rebuildCustomMarkers();
    _onRouteEdited?.call();
  }

  void setWaypointsFromSaved(List<LatLng> points, List<String> names) {
    _waypoints.setFromSaved(points, names);
    rebuildFromWaypoints();
    rebuildCustomMarkers();
    _onRouteEdited?.call();
  }

  void rebuildCustomMarkers() {
    if (_waypoints.points.isEmpty) {
      _mapState.setCustomMarkers(const {});
      _onMarkersChanged?.call();
      return;
    }

    _mapState.setCustomMarkers({
      for (var i = 0; i < _waypoints.points.length; i++)
        Marker(
          markerId: MarkerId('wp_$i'),
          position: _waypoints.points[i],
          draggable: true,
          onDragEnd: (pos) {
            updateWaypoint(i, pos);
            selectWaypoint(i);
          },
          onTap: () {
            selectWaypoint(i);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == _waypoints.selectedIndex ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: _waypoints.names.length > i ? _waypoints.names[i] : _waypoints.defaultName(i),
            snippet: 'Hold and drag to move',
          ),
          zIndexInt: 2,
        ),
    });
    _onMarkersChanged?.call();
  }

  void _syncPolylines() {
    _mapState.setPolylines(
      _route.hasRoute
          ? {
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blueAccent,
                width: 4,
                points: _route.points,
              ),
            }
          : const {},
    );
  }

  void _notify() => notifyListeners();
}
