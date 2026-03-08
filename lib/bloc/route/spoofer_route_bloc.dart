import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/route_input_parser.dart';
import '../../domain/route_playback_math.dart';
import '../../infrastructure/preferences_store.dart';
import '../../models/saved_route.dart';

import 'spoofer_route_event.dart';
import 'spoofer_route_state.dart';

class SpooferRouteBloc extends Bloc<SpooferRouteEvent, SpooferRouteState> {
  SpooferRouteBloc({
    PreferencesStore? preferencesStore,
    RoutePlaybackMath? routePlaybackMath,
  }) : _preferencesStore = preferencesStore ?? PreferencesStore(),
       _routePlaybackMath = routePlaybackMath ?? const RoutePlaybackMath(),
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

  final PreferencesStore _preferencesStore;
  final RoutePlaybackMath _routePlaybackMath;
  List<LatLng> _routePoints = <LatLng>[];
  double _routeTotalDistanceMeters = 0;
  double _routeProgress = 0;
  List<LatLng> _waypointPoints = <LatLng>[];
  List<String> _waypointNames = <String>[];
  int? _selectedWaypointIndex;
  bool _usingCustomRoute = false;
  List<SavedRoute> _savedRoutes = const <SavedRoute>[];
  bool _savedRoutesLoaded = false;
  int _messageId = 0;
  int _revision = 0;

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
    _clearRoute();
    _clearWaypoints();
    emit(_buildState());
  }

  void _onRouteProgressSetRequested(
    SpooferRouteProgressSetRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (_routePoints.isEmpty) {
      return;
    }
    _setProgress(_clamp01(event.progress));
    emit(_buildState());
  }

  void _onWaypointAddedRequested(
    SpooferRouteWaypointAddedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (_routePoints.isNotEmpty && !_usingCustomRoute) {
      emit(
        _buildState(message: 'Clear the loaded route to edit a custom route.'),
      );
      return;
    }
    _addWaypoint(event.position);
    _rebuildRouteFromWaypoints();
    emit(_buildState());
  }

  void _onWaypointUpdatedRequested(
    SpooferRouteWaypointUpdatedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _updateWaypoint(event.index, event.position);
    _rebuildRouteFromWaypoints(resetProgress: false);
    emit(_buildState());
  }

  void _onWaypointRemovedRequested(
    SpooferRouteWaypointRemovedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _removeWaypoint(event.index);
    _rebuildRouteFromWaypoints();
    emit(_buildState());
  }

  void _onWaypointSelectedRequested(
    SpooferRouteWaypointSelectedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _selectedWaypointIndex = event.index;
    emit(_buildState());
  }

  void _onWaypointRenamedRequested(
    SpooferRouteWaypointRenamedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (event.index < 0 || event.index >= _waypointNames.length) {
      return;
    }
    _waypointNames[event.index] = event.name;
    emit(_buildState());
  }

  void _onWaypointsReorderedRequested(
    SpooferRouteWaypointsReorderedRequested event,
    Emitter<SpooferRouteState> emit,
  ) {
    _reorderWaypoints(event.oldIndex, event.newIndex);
    _rebuildRouteFromWaypoints(resetProgress: false);
    emit(_buildState());
  }

  Future<void> _onSavedRoutesLoadRequested(
    SpooferRouteSavedRoutesLoadRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    _savedRoutes = await _preferencesStore.loadSavedRoutes();
    _savedRoutesLoaded = true;
    emit(_buildState());
  }

  Future<void> _onSavedRouteSaveRequested(
    SpooferRouteSavedRouteSaveRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    if (_waypointPoints.isEmpty) {
      emit(_buildState(message: 'No custom route to save.'));
      return;
    }
    final name = event.name.trim();
    if (name.isEmpty) {
      emit(_buildState(message: 'Route name is required.'));
      return;
    }
    await _preferencesStore.upsertSavedRoute(
      name: name,
      points: _waypointPoints,
      names: _waypointNames,
    );
    _savedRoutes = await _preferencesStore.loadSavedRoutes();
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
    final updated = List<SavedRoute>.from(_savedRoutes)..removeAt(event.index);
    await _preferencesStore.saveRoutes(updated);
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
    if (route.points.isEmpty) {
      emit(_buildState(message: 'Saved route is empty.'));
      return;
    }
    _setWaypointsFromSaved(route.points, route.waypointNames);
    _rebuildRouteFromWaypoints();
    emit(_buildState());
  }

  void _rebuildRouteFromWaypoints({bool resetProgress = true}) {
    if (_waypointPoints.isEmpty) {
      _clearRoute();
      return;
    }
    final previousProgress = _routeProgress;
    _setRoute(List<LatLng>.from(_waypointPoints));
    if (!resetProgress && _routeTotalDistanceMeters > 0) {
      _setProgress(previousProgress);
    }
  }

  Future<void> _onRouteLoadRequested(
    SpooferRouteLoadRequested event,
    Emitter<SpooferRouteState> emit,
  ) async {
    final input = event.input.trim();
    if (input.isEmpty) {
      emit(
        _buildState(message: 'Paste an encoded polyline or Routes API JSON.'),
      );
      return;
    }

    final polyline = extractPolylineFromInput(input);
    if (polyline == null || polyline.isEmpty) {
      emit(_buildState(message: 'No encoded polyline found in input.'));
      return;
    }

    try {
      final points = _decodePolyline(polyline);
      if (points.length < 2) {
        emit(_buildState(message: 'Failed to decode polyline.'));
        return;
      }
      _clearWaypoints();
      _setRoute(points);
      _setProgress(0);
      emit(_buildState());
    } on RangeError {
      emit(
        _buildState(
          message: 'Invalid polyline: input is incomplete or malformed.',
        ),
      );
    } catch (error) {
      emit(_buildState(message: 'Failed to load route: $error'));
    }
  }

  SpooferRouteState _buildState({bool? initialized, String? message}) {
    final messageModel = message == null
        ? null
        : SpooferRouteStateMessage(id: ++_messageId, text: message);
    return SpooferRouteState(
      initialized: initialized ?? state.initialized,
      revision: ++_revision,
      routePoints: List<LatLng>.unmodifiable(_routePoints),
      progress: _routeProgress,
      totalDistanceMeters: _routeTotalDistanceMeters,
      currentRoutePosition: _routePlaybackMath.positionForProgress(
        points: _routePoints,
        totalDistanceMeters: _routeTotalDistanceMeters,
        progress: _routeProgress,
      ),
      waypointPoints: List<LatLng>.unmodifiable(_waypointPoints),
      waypointNames: List<String>.unmodifiable(_waypointNames),
      selectedWaypointIndex: _selectedWaypointIndex,
      usingCustomRoute: _usingCustomRoute,
      savedRoutes: List<SavedRoute>.unmodifiable(_savedRoutes),
      savedRoutesLoaded: _savedRoutesLoaded,
      message: messageModel,
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = PolylinePoints().decodePolyline(encoded);
    return points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  void _clearRoute() {
    _routePoints = <LatLng>[];
    _routeTotalDistanceMeters = 0;
    _routeProgress = 0;
  }

  void _clearWaypoints() {
    _waypointPoints = <LatLng>[];
    _waypointNames = <String>[];
    _selectedWaypointIndex = null;
    _usingCustomRoute = false;
  }

  void _addWaypoint(LatLng position) {
    _usingCustomRoute = true;
    _waypointPoints.add(position);
    _waypointNames.add(_defaultWaypointName(_waypointPoints.length - 1));
  }

  void _updateWaypoint(int index, LatLng position) {
    if (index < 0 || index >= _waypointPoints.length) {
      return;
    }
    _waypointPoints[index] = position;
  }

  void _removeWaypoint(int index) {
    if (index < 0 || index >= _waypointPoints.length) {
      return;
    }
    _waypointPoints.removeAt(index);
    _waypointNames.removeAt(index);
    if (_waypointPoints.isEmpty) {
      _usingCustomRoute = false;
      _waypointNames = <String>[];
    }
    if (_selectedWaypointIndex == index) {
      _selectedWaypointIndex = null;
    }
    _normalizeDefaultWaypointNames();
  }

  void _setWaypointsFromSaved(List<LatLng> points, List<String> names) {
    _usingCustomRoute = true;
    _waypointPoints = List<LatLng>.from(points);
    _waypointNames = names.length == points.length
        ? List<String>.from(names)
        : List<String>.generate(points.length, _defaultWaypointName);
    _selectedWaypointIndex = null;
  }

  void _reorderWaypoints(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _waypointPoints.length) {
      return;
    }
    if (newIndex < 0 || newIndex > _waypointPoints.length) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex == oldIndex) {
      return;
    }

    final point = _waypointPoints.removeAt(oldIndex);
    final name = _waypointNames.removeAt(oldIndex);
    _waypointPoints.insert(newIndex, point);
    _waypointNames.insert(newIndex, name);

    if (_selectedWaypointIndex != null) {
      final selected = _selectedWaypointIndex!;
      if (selected == oldIndex) {
        _selectedWaypointIndex = newIndex;
      } else if (oldIndex < selected && newIndex >= selected) {
        _selectedWaypointIndex = selected - 1;
      } else if (oldIndex > selected && newIndex <= selected) {
        _selectedWaypointIndex = selected + 1;
      }
    }
    _normalizeDefaultWaypointNames();
  }

  void _normalizeDefaultWaypointNames() {
    for (var i = 0; i < _waypointNames.length; i++) {
      if (RegExp(r'^Waypoint\s+\d+$').hasMatch(_waypointNames[i])) {
        _waypointNames[i] = _defaultWaypointName(i);
      }
    }
  }

  String _defaultWaypointName(int index) => 'Waypoint ${index + 1}';

  void _setRoute(List<LatLng> points) {
    _routePoints = points;
    _routeTotalDistanceMeters = _routePlaybackMath.totalDistanceMeters(points);
    _routeProgress = 0;
  }

  void _setProgress(double value) {
    _routeProgress = _clamp01(value);
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
