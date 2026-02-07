import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_message_state.dart';

class SpooferMessageCubit extends Cubit<SpooferMessageState> {
  SpooferMessageCubit() : super(const SpooferMessageState());

  int _nextId = 0;

  void showSnack(String message) {
    _emit(SpooferMessageType.snack, message);
  }

  void showOverlay(String message) {
    _emit(SpooferMessageType.overlay, message);
  }

  void clear() {
    emit(state.copyWith(clearMessage: true));
  }

  void _emit(SpooferMessageType type, String message) {
    emit(
      state.copyWith(
        message: SpooferMessage(
          id: _nextId++,
          type: type,
          message: message,
        ),
      ),
    );
  }
}
