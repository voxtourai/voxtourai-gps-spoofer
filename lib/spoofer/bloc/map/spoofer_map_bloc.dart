import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_map_event.dart';
import 'spoofer_map_state.dart';

class SpooferMapBloc extends Bloc<SpooferMapEvent, SpooferMapState> {
  SpooferMapBloc() : super(const SpooferMapState()) {
    on<SpooferMapInitialized>(_onInitialized);
  }

  void _onInitialized(
    SpooferMapInitialized event,
    Emitter<SpooferMapState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }
}
