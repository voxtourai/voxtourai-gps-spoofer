// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_map_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferMapStateCWProxy {
  SpooferMapState initialized(bool initialized);

  SpooferMapState currentPosition(LatLng? currentPosition);

  SpooferMapState lastInjectedPosition(LatLng? lastInjectedPosition);

  SpooferMapState polylines(Set<Polyline> polylines);

  SpooferMapState markers(Set<Marker> markers);

  SpooferMapState autoFollowEnabled(bool autoFollowEnabled);

  SpooferMapState pendingFitRoute(bool pendingFitRoute);

  SpooferMapState isProgrammaticMove(bool isProgrammaticMove);

  SpooferMapState lastMapStyleDark(bool? lastMapStyleDark);

  /// Creates a new instance with the provided field values.
  SpooferMapState call({
    bool initialized,
    LatLng? currentPosition,
    LatLng? lastInjectedPosition,
    Set<Polyline> polylines,
    Set<Marker> markers,
    bool autoFollowEnabled,
    bool pendingFitRoute,
    bool isProgrammaticMove,
    bool? lastMapStyleDark,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferMapState.copyWith(...)` or
/// `instanceOfSpooferMapState.copyWith.fieldName(...)`.
class _$SpooferMapStateCWProxyImpl implements _$SpooferMapStateCWProxy {
  const _$SpooferMapStateCWProxyImpl(this._value);

  final SpooferMapState _value;

  @override
  SpooferMapState initialized(bool initialized) => call(initialized: initialized);

  @override
  SpooferMapState currentPosition(LatLng? currentPosition) => call(currentPosition: currentPosition);

  @override
  SpooferMapState lastInjectedPosition(LatLng? lastInjectedPosition) =>
      call(lastInjectedPosition: lastInjectedPosition);

  @override
  SpooferMapState polylines(Set<Polyline> polylines) => call(polylines: polylines);

  @override
  SpooferMapState markers(Set<Marker> markers) => call(markers: markers);

  @override
  SpooferMapState autoFollowEnabled(bool autoFollowEnabled) => call(autoFollowEnabled: autoFollowEnabled);

  @override
  SpooferMapState pendingFitRoute(bool pendingFitRoute) => call(pendingFitRoute: pendingFitRoute);

  @override
  SpooferMapState isProgrammaticMove(bool isProgrammaticMove) =>
      call(isProgrammaticMove: isProgrammaticMove);

  @override
  SpooferMapState lastMapStyleDark(bool? lastMapStyleDark) => call(lastMapStyleDark: lastMapStyleDark);

  @override
  SpooferMapState call({
    Object? initialized = const $CopyWithPlaceholder(),
    Object? currentPosition = const $CopyWithPlaceholder(),
    Object? lastInjectedPosition = const $CopyWithPlaceholder(),
    Object? polylines = const $CopyWithPlaceholder(),
    Object? markers = const $CopyWithPlaceholder(),
    Object? autoFollowEnabled = const $CopyWithPlaceholder(),
    Object? pendingFitRoute = const $CopyWithPlaceholder(),
    Object? isProgrammaticMove = const $CopyWithPlaceholder(),
    Object? lastMapStyleDark = const $CopyWithPlaceholder(),
  }) {
    return SpooferMapState(
      initialized: initialized == const $CopyWithPlaceholder() || initialized == null
          ? _value.initialized
          : initialized as bool,
      currentPosition: currentPosition == const $CopyWithPlaceholder()
          ? _value.currentPosition
          : currentPosition as LatLng?,
      lastInjectedPosition: lastInjectedPosition == const $CopyWithPlaceholder()
          ? _value.lastInjectedPosition
          : lastInjectedPosition as LatLng?,
      polylines: polylines == const $CopyWithPlaceholder() || polylines == null
          ? _value.polylines
          : polylines as Set<Polyline>,
      markers: markers == const $CopyWithPlaceholder() || markers == null
          ? _value.markers
          : markers as Set<Marker>,
      autoFollowEnabled: autoFollowEnabled == const $CopyWithPlaceholder() || autoFollowEnabled == null
          ? _value.autoFollowEnabled
          : autoFollowEnabled as bool,
      pendingFitRoute: pendingFitRoute == const $CopyWithPlaceholder() || pendingFitRoute == null
          ? _value.pendingFitRoute
          : pendingFitRoute as bool,
      isProgrammaticMove: isProgrammaticMove == const $CopyWithPlaceholder() || isProgrammaticMove == null
          ? _value.isProgrammaticMove
          : isProgrammaticMove as bool,
      lastMapStyleDark: lastMapStyleDark == const $CopyWithPlaceholder()
          ? _value.lastMapStyleDark
          : lastMapStyleDark as bool?,
    );
  }
}

extension $SpooferMapStateCopyWith on SpooferMapState {
  /// Returns a callable class used to build a new instance with modified fields.
  _$SpooferMapStateCWProxy get copyWith => _$SpooferMapStateCWProxyImpl(this);
}
