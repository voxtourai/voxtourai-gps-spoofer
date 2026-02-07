import 'package:flutter/foundation.dart';

@immutable
class SpooferMockStateMessage {
  const SpooferMockStateMessage({
    required this.id,
    required this.text,
  });

  final int id;
  final String text;
}

enum SpooferMockPromptType {
  openAppSettings,
  openDeveloperOptions,
  selectMockLocationApp,
}

@immutable
class SpooferMockStatePrompt {
  const SpooferMockStatePrompt({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final int id;
  final SpooferMockPromptType type;
  final String title;
  final String message;
  final String actionLabel;
}

@immutable
class SpooferMockState {
  const SpooferMockState({
    this.initialized = false,
    this.startupChecksRunning = false,
    this.hasLocationPermission,
    this.isDeveloperModeEnabled,
    this.isMockLocationApp,
    this.lastMockStatus,
    this.selectedMockApp,
    this.mockError,
    this.debugLog = const <String>[],
    this.prompt,
    this.message,
  });

  final bool initialized;
  final bool startupChecksRunning;
  final bool? hasLocationPermission;
  final bool? isDeveloperModeEnabled;
  final bool? isMockLocationApp;
  final Map<String, Object?>? lastMockStatus;
  final String? selectedMockApp;
  final String? mockError;
  final List<String> debugLog;
  final SpooferMockStatePrompt? prompt;
  final SpooferMockStateMessage? message;

  SpooferMockState copyWith({
    bool? initialized,
    bool? startupChecksRunning,
    bool? hasLocationPermission,
    bool clearLocationPermission = false,
    bool? isDeveloperModeEnabled,
    bool clearDeveloperModeEnabled = false,
    bool? isMockLocationApp,
    bool clearMockLocationApp = false,
    Map<String, Object?>? lastMockStatus,
    bool clearLastMockStatus = false,
    String? selectedMockApp,
    bool clearSelectedMockApp = false,
    String? mockError,
    bool clearMockError = false,
    List<String>? debugLog,
    SpooferMockStatePrompt? prompt,
    bool clearPrompt = false,
    SpooferMockStateMessage? message,
    bool clearMessage = false,
  }) {
    return SpooferMockState(
      initialized: initialized ?? this.initialized,
      startupChecksRunning: startupChecksRunning ?? this.startupChecksRunning,
      hasLocationPermission: clearLocationPermission
          ? null
          : (hasLocationPermission ?? this.hasLocationPermission),
      isDeveloperModeEnabled: clearDeveloperModeEnabled
          ? null
          : (isDeveloperModeEnabled ?? this.isDeveloperModeEnabled),
      isMockLocationApp: clearMockLocationApp ? null : (isMockLocationApp ?? this.isMockLocationApp),
      lastMockStatus: clearLastMockStatus ? null : (lastMockStatus ?? this.lastMockStatus),
      selectedMockApp: clearSelectedMockApp ? null : (selectedMockApp ?? this.selectedMockApp),
      mockError: clearMockError ? null : (mockError ?? this.mockError),
      debugLog: debugLog ?? this.debugLog,
      prompt: clearPrompt ? null : (prompt ?? this.prompt),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
