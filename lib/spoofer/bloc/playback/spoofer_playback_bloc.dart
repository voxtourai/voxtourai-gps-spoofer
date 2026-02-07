import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_playback_event.dart';
import 'spoofer_playback_state.dart';

class SpooferPlaybackBloc extends Bloc<SpooferPlaybackEvent, SpooferPlaybackState> {
  SpooferPlaybackBloc() : super(const SpooferPlaybackState()) {
    on<SpooferPlaybackInitialized>(_onInitialized);
  }

  void _onInitialized(
    SpooferPlaybackInitialized event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }
}
