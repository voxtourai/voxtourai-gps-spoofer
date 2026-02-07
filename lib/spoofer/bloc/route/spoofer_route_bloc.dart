import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../controllers/preferences_controller.dart';
import '../../../controllers/route_controller.dart';
import '../../../controllers/waypoint_controller.dart';

import 'spoofer_route_event.dart';
import 'spoofer_route_state.dart';

class SpooferRouteBloc extends Bloc<SpooferRouteEvent, SpooferRouteState> {
  SpooferRouteBloc({
    PreferencesController? preferencesController,
  })  : _preferencesController = preferencesController ?? PreferencesController(),
        super(const SpooferRouteState()) {
    on<SpooferRouteInitialized>(_onInitialized);
    on<SpooferRouteLoadRequested>(_onRouteLoadRequested);
    on<SpooferRouteClearRequested>(_onRouteClearRequested);
    on<SpooferRouteProgressSetRequested>(_onRouteProgressSetRequested);
    on<SpooferRouteWaypointAddedRequested>(_onWaypointAddedRequested);
    on<SpooferRouteWaypointUpdatedRequested>(_onWaypointUpdatedRequested);
    on<SpooferRouteWaypointRemovedRequested>(_onWaypointRemovedRequested);
    on<SpooferRouteWaypointSelectedRequested>(_onWaypointSelectedRequested);
    on<SpooferRouteWaypointRenamedRequested>(_onWaypointRenamedRequested);
    on<SpooferRouteWaypointsReorderedRequested>(_onWaypointsReorderedRequested);
    on<SpooferRouteSavedRoutesLoadRequested>(_onSavedRoutesLoadRequested);
    on<SpooferRouteSavedRouteSaveRequested>(_onSavedRouteSaveRequested);
    on<SpooferRouteSavedRouteDeleteRequested>(_onSavedRouteDeleteRequested);
    on<SpooferRouteSavedRouteApplyRequested>(_onSavedRouteApplyRequested);
  }

  final PreferencesController _preferencesController;
  final RouteController _route = RouteController();
  final WaypointController _waypoints = WaypointController();
  List<Map<String, Object?>> _savedRoutes = const <Map<String, Object?>>[];
  bool _savedRoutesLoaded = false;
  int _messageId = 0;
  int _revision = 0;

  @override
  Future<void> close() {
    _route.dispose();
    _waypoints.dispose();
    return super.close();
  }

  void _onInitialized(
    SpooferRouteInitialized event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (!state.initialized) {
      emit(_buildState(initialized: true));
    }
  }

  void _onRouteClearRequested(
    SpooferRouteClearRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _route.clear();
    _waypoints.clear();
    emit(_buildState());
  }

  void _onRouteProgressSetRequested(
    SpooferRouteProgressSetRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (!_route.hasPoints) {
      return;
    }
    _route.setProgress(_clamp01(event.progress));
    emit(_buildState());
  }

  void _onWaypointAddedRequested(
    SpooferRouteWaypointAddedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (_route.hasPoints && !_waypoints.usingCustomRoute) {
      emit(_buildState(message: 'Clear the loaded route to edit a custom route.'));
      return;
    }
    _waypoints.addPoint(event.position);
    _rebuildRouteFromWaypoints();
    emit(_buildState());
  }

  void _onWaypointUpdatedRequested(
    SpooferRouteWaypointUpdatedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _waypoints.updatePoint(event.index, event.position);
    _rebuildRouteFromWaypoints(resetProgress: false);
    emit(_buildState());
  }

  void _onWaypointRemovedRequested(
    SpooferRouteWaypointRemovedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _waypoints.removePoint(event.index);
    _rebuildRouteFromWaypoints();
    emit(_buildState());
  }

  void _onWaypointSelectedRequested(
    SpooferRouteWaypointSelectedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _waypoints.setSelectedIndex(event.index);
    emit(_buildState());
  }

  void _onWaypointRenamedRequested(
    SpooferRouteWaypointRenamedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _waypoints.renamePoint(event.index, event.name);
    emit(_buildState());
  }

  void _onWaypointsReorderedRequested(
    SpooferRouteWaypointsReorderedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _waypoints.reorder(event.oldIndex, event.newIndex);
    _rebuildRouteFromWaypoints(resetProgress: false);
    emit(_buildState());
  }

  Future<void> _onSavedRoutesLoadRequested(
    SpooferRouteSavedRoutesLoadRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    _savedRoutes = await _preferencesController.loadSavedRoutes();
    _savedRoutesLoaded = true;
    emit(_buildState());
  }

  Future<void> _onSavedRouteSaveRequested(
    SpooferRouteSavedRouteSaveRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    if (_waypoints.points.isEmpty) {
      emit(_buildState(message: 'No custom route to save.'));
      return;
    }
    final name = event.name.trim();
    if (name.isEmpty) {
      emit(_buildState(message: 'Route name is required.'));
      return;
    }
    await _preferencesController.upsertSavedRoute(
      name: name,
      points: _waypoints.points,
      names: _waypoints.names,
    );
    _savedRoutes = await _preferencesController.loadSavedRoutes();
    _savedRoutesLoaded = true;
    emit(_buildState(message: 'Saved "$name".'));
  }

  Future<void> _onSavedRouteDeleteRequested(
    SpooferRouteSavedRouteDeleteRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    if (event.index < 0 || event.index >= _savedRoutes.length) {
      return;
    }
    final updated = List<Map<String, Object?>>.from(_savedRoutes)..removeAt(event.index);
    await _preferencesController.saveRoutes(updated);
    _savedRoutes = updated;
    _savedRoutesLoaded = true;
    emit(_buildState());
  }

  void _onSavedRouteApplyRequested(
    SpooferRouteSavedRouteApplyRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (event.index < 0 || event.index >= _savedRoutes.length) {
      return;
    }

    final route = _savedRoutes[event.index];
    final points = <LatLng>[];
    final names = <String>[];
    final rawPoints = route['points'];
    if (rawPoints is List) {
      for (final item in rawPoints) {
        if (item is Map) {
          final lat = item['lat'];
          final lng = item['lng'];
          if (lat is num && lng is num) {
            points.add(LatLng(lat.toDouble(), lng.toDouble()));
          }
        }
      }
    }
    final rawNames = route['names'];
    if (rawNames is List) {
      for (final item in rawNames) {
        names.add(item.toString());
      }
    }
    if (points.isEmpty) {
      emit(_buildState(message: 'Saved route is empty.'));
      return;
    }
    _waypoints.setFromSaved(points, names);
    _rebuildRouteFromWaypoints();
    emit(_buildState());
  }

  void _rebuildRouteFromWaypoints({bool resetProgress = true}) {
    if (_waypoints.points.isEmpty) {
      _route.clear();
      return;
    }
    final previousProgress = _route.progress;
    _route.setRoute(List<LatLng>.from(_waypoints.points));
    if (!resetProgress && _route.totalDistanceMeters > 0) {
      _route.setProgress(previousProgress);
    }
  }

  Future<void> _onRouteLoadRequested(
    SpooferRouteLoadRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    final input = event.input.trim();
    if (input.isEmpty) {
      emit(_buildState(message: 'Paste an encoded polyline or Routes API JSON.'));
      return;
    }

    final polyline = _extractPolylineFromInput(input);
    if (polyline == null || polyline.isEmpty) {
      emit(_buildState(message: 'No encoded polyline found in input.'));
      return;
    }

    try {
      final points = _route.decodePolyline(polyline);
      if (points.length < 2) {
        emit(_buildState(message: 'Failed to decode polyline.'));
        return;
      }
      _waypoints.clear();
      _route.setRoute(points);
      _route.setProgress(0);
      emit(_buildState());
    } on RangeError {
      emit(_buildState(message: 'Invalid polyline: input is incomplete or malformed.'));
    } catch (error) {
      emit(_buildState(message: 'Failed to load route: $error'));
    }
  }

  String? _extractPolylineFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final unquoted = _stripSurroundingQuotes(trimmed);
    if (unquoted.startsWith('{') || unquoted.startsWith('[')) {
      try {
        final dynamic data = jsonDecode(unquoted);
        final extracted = _extractPolylineFromJson(data);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      } catch (_) {
        // fall through
      }
      final match = RegExp(r'encodedPolyline\"?\s*:\s*\"([^\"]+)\"').firstMatch(unquoted);
      if (match != null) {
        return match.group(1);
      }
    }

    return unquoted;
  }

  String _stripSurroundingQuotes(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  String? _extractPolylineFromJson(dynamic data) {
    if (data is Map) {
      final direct = _extractPolylineFromMap(data.cast<String, dynamic>());
      if (direct != null) {
        return direct;
      }
    }
    if (data is List) {
      for (final item in data) {
        final found = _extractPolylineFromJson(item);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  String? _extractPolylineFromMap(Map<String, dynamic> map) {
    final direct = map['encodedPolyline'] ?? map['routePolyline'] ?? map['polyline'];
    if (direct is String) {
      return direct;
    }
    final polylineNode = map['polyline'];
    if (polylineNode is Map) {
      final encoded = polylineNode['encodedPolyline'];
      if (encoded is String) {
        return encoded;
      }
    }
    final routes = map['routes'];
    if (routes is List && routes.isNotEmpty) {
      return _extractPolylineFromJson(routes);
    }
    return null;
  }

  SpooferRouteState _buildState({
    bool? initialized,
    String? message,
  }) {
    final messageModel = message == null
        ? null
        : SpooferRouteStateMessage(
            id: ++_messageId,
            text: message,
          );
    return SpooferRouteState(
      initialized: initialized ?? state.initialized,
      revision: ++_revision,
      routePoints: List<LatLng>.unmodifiable(_route.points),
      progress: _route.progress,
      totalDistanceMeters: _route.totalDistanceMeters,
      currentRoutePosition: _route.positionForCurrentProgress(),
      waypointPoints: List<LatLng>.unmodifiable(_waypoints.points),
      waypointNames: List<String>.unmodifiable(_waypoints.names),
      selectedWaypointIndex: _waypoints.selectedIndex,
      usingCustomRoute: _waypoints.usingCustomRoute,
      savedRoutes: List<Map<String, Object?>>.unmodifiable(_savedRoutes),
      savedRoutesLoaded: _savedRoutesLoaded,
      message: messageModel,
    );
  }

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
