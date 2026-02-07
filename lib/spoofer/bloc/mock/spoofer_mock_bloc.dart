import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_mock_event.dart';
import 'spoofer_mock_state.dart';

class SpooferMockBloc extends Bloc<SpooferMockEvent, SpooferMockState> {
  SpooferMockBloc() : super(const SpooferMockState()) {
    on<SpooferMockInitialized>(_onInitialized);
  }

  void _onInitialized(
    SpooferMockInitialized event,
    Emitter<SpooferMockState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }
}
