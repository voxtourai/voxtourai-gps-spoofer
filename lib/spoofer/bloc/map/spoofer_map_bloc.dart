import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_map_event.dart';
import 'spoofer_map_state.dart';

class SpooferMapBloc extends Bloc<SpooferMapEvent, SpooferMapState> {
  SpooferMapBloc() : super(const SpooferMapState()) {
    on<SpooferMapInitialized>(_onInitialized);
    on<SpooferMapCurrentPositionSetRequested>(_onCurrentPositionSetRequested);
    on<SpooferMapLastInjectedPositionSetRequested>(_onLastInjectedPositionSetRequested);
    on<SpooferMapPolylinesSetRequested>(_onPolylinesSetRequested);
    on<SpooferMapMarkersSetRequested>(_onMarkersSetRequested);
    on<SpooferMapAutoFollowSetRequested>(_onAutoFollowSetRequested);
    on<SpooferMapPendingFitRouteSetRequested>(_onPendingFitRouteSetRequested);
    on<SpooferMapProgrammaticMoveSetRequested>(_onProgrammaticMoveSetRequested);
    on<SpooferMapLastMapStyleDarkSetRequested>(_onLastMapStyleDarkSetRequested);
  }

  void _onInitialized(
    SpooferMapInitialized event,
    Emitter<SpooferMapState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }

  void _onCurrentPositionSetRequested(
    SpooferMapCurrentPositionSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (state.currentPosition == event.position &&
        (!event.updateLastInjected || state.lastInjectedPosition == event.position)) {
      return;
    }
    emit(
      state.copyWith(
        currentPosition: event.position,
        lastInjectedPosition: event.updateLastInjected ? event.position : null,
      ),
    );
  }

  void _onLastInjectedPositionSetRequested(
    SpooferMapLastInjectedPositionSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (state.lastInjectedPosition == event.position) {
      return;
    }
    emit(state.copyWith(lastInjectedPosition: event.position));
  }

  void _onPolylinesSetRequested(
    SpooferMapPolylinesSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (setEquals(state.polylines, event.polylines)) {
      return;
    }
    emit(state.copyWith(polylines: Set.unmodifiable(event.polylines)));
  }

  void _onMarkersSetRequested(
    SpooferMapMarkersSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (setEquals(state.markers, event.markers)) {
      return;
    }
    emit(state.copyWith(markers: Set.unmodifiable(event.markers)));
  }

  void _onAutoFollowSetRequested(
    SpooferMapAutoFollowSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (state.autoFollowEnabled == event.value) {
      return;
    }
    emit(state.copyWith(autoFollowEnabled: event.value));
  }

  void _onPendingFitRouteSetRequested(
    SpooferMapPendingFitRouteSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (state.pendingFitRoute == event.value) {
      return;
    }
    emit(state.copyWith(pendingFitRoute: event.value));
  }

  void _onProgrammaticMoveSetRequested(
    SpooferMapProgrammaticMoveSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (state.isProgrammaticMove == event.value) {
      return;
    }
    emit(state.copyWith(isProgrammaticMove: event.value));
  }

  void _onLastMapStyleDarkSetRequested(
    SpooferMapLastMapStyleDarkSetRequested event,
    Emitter<SpooferMapState> emit,
  ) {
    if (state.lastMapStyleDark == event.value) {
      return;
    }
    emit(state.copyWith(lastMapStyleDark: event.value));
  }
}
