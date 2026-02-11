// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_route_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferRouteStateCWProxy {
  SpooferRouteState initialized(bool initialized);

  SpooferRouteState revision(int revision);

  SpooferRouteState routePoints(List<LatLng> routePoints);

  SpooferRouteState progress(double progress);

  SpooferRouteState totalDistanceMeters(double totalDistanceMeters);

  SpooferRouteState currentRoutePosition(LatLng? currentRoutePosition);

  SpooferRouteState waypointPoints(List<LatLng> waypointPoints);

  SpooferRouteState waypointNames(List<String> waypointNames);

  SpooferRouteState selectedWaypointIndex(int? selectedWaypointIndex);

  SpooferRouteState usingCustomRoute(bool usingCustomRoute);

  SpooferRouteState savedRoutes(List<Map<String, Object?>> savedRoutes);

  SpooferRouteState savedRoutesLoaded(bool savedRoutesLoaded);

  SpooferRouteState message(SpooferRouteStateMessage? message);

  /// Creates a new instance with the provided field values.
  SpooferRouteState call({
    bool initialized,
    int revision,
    List<LatLng> routePoints,
    double progress,
    double totalDistanceMeters,
    LatLng? currentRoutePosition,
    List<LatLng> waypointPoints,
    List<String> waypointNames,
    int? selectedWaypointIndex,
    bool usingCustomRoute,
    List<Map<String, Object?>> savedRoutes,
    bool savedRoutesLoaded,
    SpooferRouteStateMessage? message,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferRouteState.copyWith(...)` or
/// `instanceOfSpooferRouteState.copyWith.fieldName(...)`.
class _$SpooferRouteStateCWProxyImpl implements _$SpooferRouteStateCWProxy {
  const _$SpooferRouteStateCWProxyImpl(this._value);

  final SpooferRouteState _value;

  @override
  SpooferRouteState initialized(bool initialized) => call(initialized: initialized);

  @override
  SpooferRouteState revision(int revision) => call(revision: revision);

  @override
  SpooferRouteState routePoints(List<LatLng> routePoints) => call(routePoints: routePoints);

  @override
  SpooferRouteState progress(double progress) => call(progress: progress);

  @override
  SpooferRouteState totalDistanceMeters(double totalDistanceMeters) =>
      call(totalDistanceMeters: totalDistanceMeters);

  @override
  SpooferRouteState currentRoutePosition(LatLng? currentRoutePosition) =>
      call(currentRoutePosition: currentRoutePosition);

  @override
  SpooferRouteState waypointPoints(List<LatLng> waypointPoints) =>
      call(waypointPoints: waypointPoints);

  @override
  SpooferRouteState waypointNames(List<String> waypointNames) => call(waypointNames: waypointNames);

  @override
  SpooferRouteState selectedWaypointIndex(int? selectedWaypointIndex) =>
      call(selectedWaypointIndex: selectedWaypointIndex);

  @override
  SpooferRouteState usingCustomRoute(bool usingCustomRoute) => call(usingCustomRoute: usingCustomRoute);

  @override
  SpooferRouteState savedRoutes(List<Map<String, Object?>> savedRoutes) => call(savedRoutes: savedRoutes);

  @override
  SpooferRouteState savedRoutesLoaded(bool savedRoutesLoaded) =>
      call(savedRoutesLoaded: savedRoutesLoaded);

  @override
  SpooferRouteState message(SpooferRouteStateMessage? message) => call(message: message);

  @override
  SpooferRouteState call({
    Object? initialized = const $CopyWithPlaceholder(),
    Object? revision = const $CopyWithPlaceholder(),
    Object? routePoints = const $CopyWithPlaceholder(),
    Object? progress = const $CopyWithPlaceholder(),
    Object? totalDistanceMeters = const $CopyWithPlaceholder(),
    Object? currentRoutePosition = const $CopyWithPlaceholder(),
    Object? waypointPoints = const $CopyWithPlaceholder(),
    Object? waypointNames = const $CopyWithPlaceholder(),
    Object? selectedWaypointIndex = const $CopyWithPlaceholder(),
    Object? usingCustomRoute = const $CopyWithPlaceholder(),
    Object? savedRoutes = const $CopyWithPlaceholder(),
    Object? savedRoutesLoaded = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return SpooferRouteState(
      initialized: initialized == const $CopyWithPlaceholder() || initialized == null
          ? _value.initialized
          : initialized as bool,
      revision: revision == const $CopyWithPlaceholder() || revision == null
          ? _value.revision
          : revision as int,
      routePoints: routePoints == const $CopyWithPlaceholder() || routePoints == null
          ? _value.routePoints
          : routePoints as List<LatLng>,
      progress: progress == const $CopyWithPlaceholder() || progress == null
          ? _value.progress
          : progress as double,
      totalDistanceMeters: totalDistanceMeters == const $CopyWithPlaceholder() || totalDistanceMeters == null
          ? _value.totalDistanceMeters
          : totalDistanceMeters as double,
      currentRoutePosition: currentRoutePosition == const $CopyWithPlaceholder()
          ? _value.currentRoutePosition
          : currentRoutePosition as LatLng?,
      waypointPoints: waypointPoints == const $CopyWithPlaceholder() || waypointPoints == null
          ? _value.waypointPoints
          : waypointPoints as List<LatLng>,
      waypointNames: waypointNames == const $CopyWithPlaceholder() || waypointNames == null
          ? _value.waypointNames
          : waypointNames as List<String>,
      selectedWaypointIndex: selectedWaypointIndex == const $CopyWithPlaceholder()
          ? _value.selectedWaypointIndex
          : selectedWaypointIndex as int?,
      usingCustomRoute: usingCustomRoute == const $CopyWithPlaceholder() || usingCustomRoute == null
          ? _value.usingCustomRoute
          : usingCustomRoute as bool,
      savedRoutes: savedRoutes == const $CopyWithPlaceholder() || savedRoutes == null
          ? _value.savedRoutes
          : savedRoutes as List<Map<String, Object?>>,
      savedRoutesLoaded: savedRoutesLoaded == const $CopyWithPlaceholder() || savedRoutesLoaded == null
          ? _value.savedRoutesLoaded
          : savedRoutesLoaded as bool,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          : message as SpooferRouteStateMessage?,
    );
  }
}

extension $SpooferRouteStateCopyWith on SpooferRouteState {
  /// Returns a callable class used to build a new instance with modified fields.
  // ignore: library_private_types_in_public_api
  _$SpooferRouteStateCWProxy get copyWith => _$SpooferRouteStateCWProxyImpl(this);
}
