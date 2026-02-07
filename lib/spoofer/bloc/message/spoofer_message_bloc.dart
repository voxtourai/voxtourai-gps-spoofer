import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_message_event.dart';
import 'spoofer_message_state.dart';

class SpooferMessageBloc extends Bloc<SpooferMessageEvent, SpooferMessageState> {
  SpooferMessageBloc() : super(const SpooferMessageState()) {
    on<SpooferMessageShownRequested>(_onMessageShownRequested);
    on<SpooferMessageClearedRequested>(_onMessageClearedRequested);
  }

  int _nextId = 0;

  void _onMessageShownRequested(
    SpooferMessageShownRequested event,
    Emitter<SpooferMessageState> emit,
  ) {
    emit(
      state.copyWith(
        message: SpooferMessage(
          id: _nextId++,
          type: event.type,
          message: event.message,
        ),
      ),
    );
  }

  void _onMessageClearedRequested(
    SpooferMessageClearedRequested event,
    Emitter<SpooferMessageState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }
}
