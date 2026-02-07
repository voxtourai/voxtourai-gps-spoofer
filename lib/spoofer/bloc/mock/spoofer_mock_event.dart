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
