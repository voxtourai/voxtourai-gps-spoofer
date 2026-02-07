import 'package:flutter/foundation.dart';

@immutable
abstract class SpooferMockEvent {
  const SpooferMockEvent();
}

class SpooferMockInitialized extends SpooferMockEvent {
  const SpooferMockInitialized();
}

class SpooferMockLocationPermissionSetRequested extends SpooferMockEvent {
  const SpooferMockLocationPermissionSetRequested({required this.value});

  final bool? value;
}

class SpooferMockDeveloperModeSetRequested extends SpooferMockEvent {
  const SpooferMockDeveloperModeSetRequested({required this.value});

  final bool? value;
}

class SpooferMockLocationAppSetRequested extends SpooferMockEvent {
  const SpooferMockLocationAppSetRequested({required this.value});

  final bool? value;
}

class SpooferMockSelectedAppSetRequested extends SpooferMockEvent {
  const SpooferMockSelectedAppSetRequested({required this.value});

  final String? value;
}

class SpooferMockStatusSetRequested extends SpooferMockEvent {
  const SpooferMockStatusSetRequested({required this.value});

  final Map<String, Object?>? value;
}

class SpooferMockErrorSetRequested extends SpooferMockEvent {
  const SpooferMockErrorSetRequested({
    required this.message,
    this.throttle,
  });

  final String message;
  final Duration? throttle;
}

class SpooferMockErrorClearedRequested extends SpooferMockEvent {
  const SpooferMockErrorClearedRequested();
}

class SpooferMockDebugLogAppended extends SpooferMockEvent {
  const SpooferMockDebugLogAppended({required this.message});

  final String message;
}

class SpooferMockMessageRequested extends SpooferMockEvent {
  const SpooferMockMessageRequested({required this.message});

  final String message;
}

class SpooferMockStartupChecksRequested extends SpooferMockEvent {
  const SpooferMockStartupChecksRequested({required this.showDialogs});

  final bool showDialogs;
}

class SpooferMockPromptResolved extends SpooferMockEvent {
  const SpooferMockPromptResolved({
    required this.promptId,
    required this.accepted,
  });

  final int promptId;
  final bool accepted;
}

class SpooferMockRefreshStatusRequested extends SpooferMockEvent {
  const SpooferMockRefreshStatusRequested();
}

class SpooferMockApplyLocationRequested extends SpooferMockEvent {
  const SpooferMockApplyLocationRequested({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speedMps,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double speedMps;
}

class SpooferMockClearLocationRequested extends SpooferMockEvent {
  const SpooferMockClearLocationRequested();
}
