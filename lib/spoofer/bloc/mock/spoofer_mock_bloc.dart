import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../controllers/mock_location_controller.dart';

import 'spoofer_mock_event.dart';
import 'spoofer_mock_state.dart';

typedef RequestLocationPermission = Future<bool> Function();
typedef OpenAppSettingsAction = Future<bool> Function();

class SpooferMockBloc extends Bloc<SpooferMockEvent, SpooferMockState> {
  SpooferMockBloc({
    required MockLocationController mockController,
    RequestLocationPermission? requestLocationPermission,
    OpenAppSettingsAction? openAppSettingsAction,
  })  : _mockController = mockController,
        _requestLocationPermission =
            requestLocationPermission ?? _defaultRequestLocationPermission,
        _openAppSettingsAction = openAppSettingsAction ?? openAppSettings,
        super(const SpooferMockState()) {
    on<SpooferMockInitialized>(_onInitialized);
    on<SpooferMockStartupChecksRequested>(_onStartupChecksRequested);
    on<SpooferMockPromptResolved>(_onPromptResolved);
    on<SpooferMockRefreshStatusRequested>(_onRefreshStatusRequested);
    on<SpooferMockApplyLocationRequested>(_onApplyLocationRequested);
    on<SpooferMockClearLocationRequested>(_onClearLocationRequested);
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

  final MockLocationController _mockController;
  final RequestLocationPermission _requestLocationPermission;
  final OpenAppSettingsAction _openAppSettingsAction;

  int _messageId = 0;
  int _promptId = 0;
  DateTime? _lastMockErrorAt;
  String? _lastDebugMessage;
  DateTime? _lastDebugAt;

  static Future<bool> _defaultRequestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  void _onInitialized(
    SpooferMockInitialized event,
    Emitter<SpooferMockState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }

  Future<void> _onStartupChecksRequested(
    SpooferMockStartupChecksRequested event,
    Emitter<SpooferMockState> emit,
  ) async {
    if (state.startupChecksRunning) {
      return;
    }

    emit(
      state.copyWith(
        startupChecksRunning: true,
        clearPrompt: true,
      ),
    );

    try {
      final locationGranted = await _requestLocationPermission();
      emit(state.copyWith(hasLocationPermission: locationGranted));
      if (!locationGranted) {
        if (event.showDialogs) {
          emit(
            state.copyWith(
              prompt: SpooferMockStatePrompt(
                id: ++_promptId,
                type: SpooferMockPromptType.openAppSettings,
                title: 'Location Permission Required',
                message: 'Grant location permission so the mock GPS updates can be applied.',
                actionLabel: 'Open App Settings',
              ),
            ),
          );
        }
        return;
      }

      final devEnabled = await _safeBool(_mockController.isDeveloperModeEnabled);
      emit(state.copyWith(isDeveloperModeEnabled: devEnabled));
      if (!devEnabled) {
        if (event.showDialogs) {
          emit(
            state.copyWith(
              prompt: SpooferMockStatePrompt(
                id: ++_promptId,
                type: SpooferMockPromptType.openDeveloperOptions,
                title: 'Enable Developer Options',
                message: 'Developer options must be enabled to select a mock location app.',
                actionLabel: 'Open Developer Options',
              ),
            ),
          );
        }
        return;
      }

      final isMockApp = await _safeBool(_mockController.isMockLocationApp);
      emit(state.copyWith(isMockLocationApp: isMockApp));
      if (!isMockApp && event.showDialogs) {
        emit(
          state.copyWith(
            prompt: SpooferMockStatePrompt(
              id: ++_promptId,
              type: SpooferMockPromptType.selectMockLocationApp,
              title: 'Select Mock Location App',
              message: 'Choose this app as the mock location provider.',
              actionLabel: 'Open Developer Options',
            ),
          ),
        );
      }
    } finally {
      emit(state.copyWith(startupChecksRunning: false));
    }
  }

  Future<void> _onPromptResolved(
    SpooferMockPromptResolved event,
    Emitter<SpooferMockState> emit,
  ) async {
    final prompt = state.prompt;
    if (prompt == null || prompt.id != event.promptId) {
      return;
    }

    emit(state.copyWith(clearPrompt: true));

    if (!event.accepted) {
      return;
    }

    try {
      if (prompt.type == SpooferMockPromptType.openAppSettings) {
        await _openAppSettingsAction();
      } else {
        await _mockController.openDeveloperSettings();
      }
    } on PlatformException catch (error) {
      add(
        SpooferMockMessageRequested(
          message: 'Failed to open settings: ${error.message ?? error.code}',
        ),
      );
    }
  }

  Future<void> _onRefreshStatusRequested(
    SpooferMockRefreshStatusRequested event,
    Emitter<SpooferMockState> emit,
  ) async {
    try {
      final selected = await _mockController.getMockLocationApp();
      final isSelected = await _safeBool(_mockController.isMockLocationApp);
      emit(
        state.copyWith(
          selectedMockApp: selected,
          isMockLocationApp: isSelected,
        ),
      );
      add(
        SpooferMockDebugLogAppended(
          message: 'Mock app: ${selected ?? '—'} selected=${isSelected ? 'YES' : 'NO'}',
        ),
      );
    } catch (_) {
      // Ignore refresh failures.
    }
  }

  Future<void> _onApplyLocationRequested(
    SpooferMockApplyLocationRequested event,
    Emitter<SpooferMockState> emit,
  ) async {
    final hadError = state.mockError != null;
    try {
      final result = await _mockController.setMockLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        accuracy: event.accuracy,
        speedMps: event.speedMps,
      );
      emit(state.copyWith(lastMockStatus: result));

      final gpsApplied = result?['gpsApplied'] == true;
      final mockAppSelected = result?['mockAppSelected'] == true;
      final gpsError = result?['gpsError']?.toString();
      final fusedError = result?['fusedError']?.toString();

      if (!gpsApplied) {
        final details = gpsError ?? fusedError ?? 'GPS mock not applied';
        final hint = mockAppSelected ? 'Mock app set, but GPS mock failed.' : 'Select this app as mock location.';
        add(SpooferMockErrorSetRequested(message: 'Mock GPS not applied: $details. $hint'));
        add(SpooferMockDebugLogAppended(message: 'Mock apply failed: $details'));
      } else if (state.mockError != null) {
        add(const SpooferMockErrorClearedRequested());
        if (hadError) {
          add(const SpooferMockDebugLogAppended(message: 'Mock apply ok.'));
        }
      }
    } on PlatformException catch (error) {
      add(
        SpooferMockErrorSetRequested(
          message: 'Mock location failed: ${error.message ?? error.code}',
          throttle: const Duration(seconds: 5),
        ),
      );
      add(SpooferMockDebugLogAppended(message: 'Mock exception: ${error.message ?? error.code}'));
    }
  }

  Future<void> _onClearLocationRequested(
    SpooferMockClearLocationRequested event,
    Emitter<SpooferMockState> emit,
  ) async {
    try {
      final result = await _mockController.clearMockLocation();
      emit(
        state.copyWith(
          lastMockStatus: result,
          clearMockError: true,
        ),
      );
      add(const SpooferMockDebugLogAppended(message: 'Cleared mock location.'));
    } on PlatformException catch (error) {
      add(
        SpooferMockMessageRequested(
          message: 'Failed to clear mock location: ${error.message ?? error.code}',
        ),
      );
      add(SpooferMockDebugLogAppended(message: 'Clear mock failed: ${error.message ?? error.code}'));
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

  Future<bool> _safeBool(Future<bool> Function() callback) async {
    try {
      return await callback();
    } catch (_) {
      return false;
    }
  }
}
