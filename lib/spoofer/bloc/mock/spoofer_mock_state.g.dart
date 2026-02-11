// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_mock_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferMockStateCWProxy {
  SpooferMockState initialized(bool initialized);

  SpooferMockState startupChecksRunning(bool startupChecksRunning);

  SpooferMockState hasLocationPermission(bool? hasLocationPermission);

  SpooferMockState isDeveloperModeEnabled(bool? isDeveloperModeEnabled);

  SpooferMockState isMockLocationApp(bool? isMockLocationApp);

  SpooferMockState lastMockStatus(Map<String, Object?>? lastMockStatus);

  SpooferMockState selectedMockApp(String? selectedMockApp);

  SpooferMockState mockError(String? mockError);

  SpooferMockState debugLog(List<String> debugLog);

  SpooferMockState prompt(SpooferMockStatePrompt? prompt);

  SpooferMockState message(SpooferMockStateMessage? message);

  /// Creates a new instance with the provided field values.
  SpooferMockState call({
    bool initialized,
    bool startupChecksRunning,
    bool? hasLocationPermission,
    bool? isDeveloperModeEnabled,
    bool? isMockLocationApp,
    Map<String, Object?>? lastMockStatus,
    String? selectedMockApp,
    String? mockError,
    List<String> debugLog,
    SpooferMockStatePrompt? prompt,
    SpooferMockStateMessage? message,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferMockState.copyWith(...)` or
/// `instanceOfSpooferMockState.copyWith.fieldName(...)`.
class _$SpooferMockStateCWProxyImpl implements _$SpooferMockStateCWProxy {
  const _$SpooferMockStateCWProxyImpl(this._value);

  final SpooferMockState _value;

  @override
  SpooferMockState initialized(bool initialized) => call(initialized: initialized);

  @override
  SpooferMockState startupChecksRunning(bool startupChecksRunning) =>
      call(startupChecksRunning: startupChecksRunning);

  @override
  SpooferMockState hasLocationPermission(bool? hasLocationPermission) =>
      call(hasLocationPermission: hasLocationPermission);

  @override
  SpooferMockState isDeveloperModeEnabled(bool? isDeveloperModeEnabled) =>
      call(isDeveloperModeEnabled: isDeveloperModeEnabled);

  @override
  SpooferMockState isMockLocationApp(bool? isMockLocationApp) =>
      call(isMockLocationApp: isMockLocationApp);

  @override
  SpooferMockState lastMockStatus(Map<String, Object?>? lastMockStatus) =>
      call(lastMockStatus: lastMockStatus);

  @override
  SpooferMockState selectedMockApp(String? selectedMockApp) =>
      call(selectedMockApp: selectedMockApp);

  @override
  SpooferMockState mockError(String? mockError) => call(mockError: mockError);

  @override
  SpooferMockState debugLog(List<String> debugLog) => call(debugLog: debugLog);

  @override
  SpooferMockState prompt(SpooferMockStatePrompt? prompt) => call(prompt: prompt);

  @override
  SpooferMockState message(SpooferMockStateMessage? message) => call(message: message);

  @override
  SpooferMockState call({
    Object? initialized = const $CopyWithPlaceholder(),
    Object? startupChecksRunning = const $CopyWithPlaceholder(),
    Object? hasLocationPermission = const $CopyWithPlaceholder(),
    Object? isDeveloperModeEnabled = const $CopyWithPlaceholder(),
    Object? isMockLocationApp = const $CopyWithPlaceholder(),
    Object? lastMockStatus = const $CopyWithPlaceholder(),
    Object? selectedMockApp = const $CopyWithPlaceholder(),
    Object? mockError = const $CopyWithPlaceholder(),
    Object? debugLog = const $CopyWithPlaceholder(),
    Object? prompt = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return SpooferMockState(
      initialized: initialized == const $CopyWithPlaceholder() || initialized == null
          ? _value.initialized
          : initialized as bool,
      startupChecksRunning:
          startupChecksRunning == const $CopyWithPlaceholder() || startupChecksRunning == null
              ? _value.startupChecksRunning
              : startupChecksRunning as bool,
      hasLocationPermission: hasLocationPermission == const $CopyWithPlaceholder()
          ? _value.hasLocationPermission
          : hasLocationPermission as bool?,
      isDeveloperModeEnabled: isDeveloperModeEnabled == const $CopyWithPlaceholder()
          ? _value.isDeveloperModeEnabled
          : isDeveloperModeEnabled as bool?,
      isMockLocationApp: isMockLocationApp == const $CopyWithPlaceholder()
          ? _value.isMockLocationApp
          : isMockLocationApp as bool?,
      lastMockStatus: lastMockStatus == const $CopyWithPlaceholder()
          ? _value.lastMockStatus
          : lastMockStatus as Map<String, Object?>?,
      selectedMockApp: selectedMockApp == const $CopyWithPlaceholder()
          ? _value.selectedMockApp
          : selectedMockApp as String?,
      mockError: mockError == const $CopyWithPlaceholder()
          ? _value.mockError
          : mockError as String?,
      debugLog: debugLog == const $CopyWithPlaceholder() || debugLog == null
          ? _value.debugLog
          : debugLog as List<String>,
      prompt: prompt == const $CopyWithPlaceholder()
          ? _value.prompt
          : prompt as SpooferMockStatePrompt?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          : message as SpooferMockStateMessage?,
    );
  }
}

extension $SpooferMockStateCopyWith on SpooferMockState {
  /// Returns a callable class used to build a new instance with modified fields.
  _$SpooferMockStateCWProxy get copyWith => _$SpooferMockStateCWProxyImpl(this);
}
