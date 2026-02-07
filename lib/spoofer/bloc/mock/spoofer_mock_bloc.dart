import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_mock_event.dart';
import 'spoofer_mock_state.dart';

class SpooferMockBloc extends Bloc<SpooferMockEvent, SpooferMockState> {
  SpooferMockBloc() : super(const SpooferMockState()) {
    on<SpooferMockInitialized>(_onInitialized);
    on<SpooferMockLocationPermissionSetRequested>(_onLocationPermissionSetRequested);
    on<SpooferMockDeveloperModeSetRequested>(_onDeveloperModeSetRequested);
    on<SpooferMockLocationAppSetRequested>(_onMockLocationAppSetRequested);
    on<SpooferMockSelectedAppSetRequested>(_onSelectedAppSetRequested);
    on<SpooferMockStatusSetRequested>(_onStatusSetRequested);
    on<SpooferMockErrorSetRequested>(_onErrorSetRequested);
    on<SpooferMockErrorClearedRequested>(_onErrorClearedRequested);
    on<SpooferMockDebugLogAppended>(_onDebugLogAppended);
    on<SpooferMockMessageRequested>(_onMessageRequested);
  }

  int _messageId = 0;
  DateTime? _lastMockErrorAt;
  String? _lastDebugMessage;
  DateTime? _lastDebugAt;

  void _onInitialized(
    SpooferMockInitialized event,
    Emitter<SpooferMockState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }

  void _onLocationPermissionSetRequested(
    SpooferMockLocationPermissionSetRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    if (state.hasLocationPermission == event.value) {
      return;
    }
    emit(state.copyWith(hasLocationPermission: event.value));
  }

  void _onDeveloperModeSetRequested(
    SpooferMockDeveloperModeSetRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    if (state.isDeveloperModeEnabled == event.value) {
      return;
    }
    emit(state.copyWith(isDeveloperModeEnabled: event.value));
  }

  void _onMockLocationAppSetRequested(
    SpooferMockLocationAppSetRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    if (state.isMockLocationApp == event.value) {
      return;
    }
    emit(state.copyWith(isMockLocationApp: event.value));
  }

  void _onSelectedAppSetRequested(
    SpooferMockSelectedAppSetRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    if (state.selectedMockApp == event.value) {
      return;
    }
    emit(state.copyWith(selectedMockApp: event.value));
  }

  void _onStatusSetRequested(
    SpooferMockStatusSetRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    emit(state.copyWith(lastMockStatus: event.value));
  }

  void _onErrorSetRequested(
    SpooferMockErrorSetRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    final now = DateTime.now();
    if (event.throttle != null &&
        _lastMockErrorAt != null &&
        now.difference(_lastMockErrorAt!) <= event.throttle!) {
      return;
    }
    _lastMockErrorAt = now;
    if (state.mockError == event.message) {
      return;
    }
    emit(state.copyWith(mockError: event.message));
  }

  void _onErrorClearedRequested(
    SpooferMockErrorClearedRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    if (state.mockError == null) {
      return;
    }
    emit(state.copyWith(clearMockError: true));
  }

  void _onDebugLogAppended(
    SpooferMockDebugLogAppended event,
    Emitter<SpooferMockState> emit,
  ) {
    final now = DateTime.now();
    if (_lastDebugMessage == event.message &&
        _lastDebugAt != null &&
        now.difference(_lastDebugAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastDebugMessage = event.message;
    _lastDebugAt = now;
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final entry = '[$stamp] ${event.message}';
    final next = List<String>.from(state.debugLog)..add(entry);
    if (next.length > 50) {
      next.removeRange(0, next.length - 50);
    }
    emit(state.copyWith(debugLog: List<String>.unmodifiable(next)));
  }

  void _onMessageRequested(
    SpooferMockMessageRequested event,
    Emitter<SpooferMockState> emit,
  ) {
    emit(
      state.copyWith(
        message: SpooferMockStateMessage(
          id: ++_messageId,
          text: event.message,
        ),
      ),
    );
  }
}
