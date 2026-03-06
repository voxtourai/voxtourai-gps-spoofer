import 'package:flutter/foundation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'spoofer_mock_state.g.dart';

@immutable
class SpooferMockStateMessage {
  const SpooferMockStateMessage({required this.id, required this.text});

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
@CopyWith()
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
}
