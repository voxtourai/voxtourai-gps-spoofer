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
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SpooferMockState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SpooferMockState(...).copyWith(id: 12, name: "My name")
  /// ```
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
/// Use as `instanceOfSpooferMockState.copyWith(...)` or call `instanceOfSpooferMockState.copyWith.fieldName(value)` for a single field.
class _$SpooferMockStateCWProxyImpl implements _$SpooferMockStateCWProxy {
  const _$SpooferMockStateCWProxyImpl(this._value);

  final SpooferMockState _value;

  @override
  SpooferMockState initialized(bool initialized) =>
      call(initialized: initialized);

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
  SpooferMockState prompt(SpooferMockStatePrompt? prompt) =>
      call(prompt: prompt);

  @override
  SpooferMockState message(SpooferMockStateMessage? message) =>
      call(message: message);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SpooferMockState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SpooferMockState(...).copyWith(id: 12, name: "My name")
  /// ```
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
      initialized:
          initialized == const $CopyWithPlaceholder() || initialized == null
          ? _value.initialized
          // ignore: cast_nullable_to_non_nullable
          : initialized as bool,
      startupChecksRunning:
          startupChecksRunning == const $CopyWithPlaceholder() ||
              startupChecksRunning == null
          ? _value.startupChecksRunning
          // ignore: cast_nullable_to_non_nullable
          : startupChecksRunning as bool,
      hasLocationPermission:
          hasLocationPermission == const $CopyWithPlaceholder()
          ? _value.hasLocationPermission
          // ignore: cast_nullable_to_non_nullable
          : hasLocationPermission as bool?,
      isDeveloperModeEnabled:
          isDeveloperModeEnabled == const $CopyWithPlaceholder()
          ? _value.isDeveloperModeEnabled
          // ignore: cast_nullable_to_non_nullable
          : isDeveloperModeEnabled as bool?,
      isMockLocationApp: isMockLocationApp == const $CopyWithPlaceholder()
          ? _value.isMockLocationApp
          // ignore: cast_nullable_to_non_nullable
          : isMockLocationApp as bool?,
      lastMockStatus: lastMockStatus == const $CopyWithPlaceholder()
          ? _value.lastMockStatus
          // ignore: cast_nullable_to_non_nullable
          : lastMockStatus as Map<String, Object?>?,
      selectedMockApp: selectedMockApp == const $CopyWithPlaceholder()
          ? _value.selectedMockApp
          // ignore: cast_nullable_to_non_nullable
          : selectedMockApp as String?,
      mockError: mockError == const $CopyWithPlaceholder()
          ? _value.mockError
          // ignore: cast_nullable_to_non_nullable
          : mockError as String?,
      debugLog: debugLog == const $CopyWithPlaceholder() || debugLog == null
          ? _value.debugLog
          // ignore: cast_nullable_to_non_nullable
          : debugLog as List<String>,
      prompt: prompt == const $CopyWithPlaceholder()
          ? _value.prompt
          // ignore: cast_nullable_to_non_nullable
          : prompt as SpooferMockStatePrompt?,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as SpooferMockStateMessage?,
    );
  }
}

extension $SpooferMockStateCopyWith on SpooferMockState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSpooferMockState.copyWith(...)` or `instanceOfSpooferMockState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SpooferMockStateCWProxy get copyWith => _$SpooferMockStateCWProxyImpl(this);
}
