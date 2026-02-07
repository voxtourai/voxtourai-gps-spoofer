import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_route_event.dart';
import 'spoofer_route_state.dart';

class SpooferRouteBloc extends Bloc<SpooferRouteEvent, SpooferRouteState> {
  SpooferRouteBloc() : super(const SpooferRouteState()) {
    on<SpooferRouteInitialized>(_onInitialized);
  }

  void _onInitialized(
    SpooferRouteInitialized event,
    Emitter<SpooferRouteState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }
}
