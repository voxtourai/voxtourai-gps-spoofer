import 'package:flutter/foundation.dart';

import 'spoofer_settings_state.dart';

@immutable
abstract class SpooferSettingsEvent {
  const SpooferSettingsEvent();
}

class SpooferSettingsShowMockMarkerSetRequested extends SpooferSettingsEvent {
  const SpooferSettingsShowMockMarkerSetRequested({required this.value});

  final bool value;
}

class SpooferSettingsShowSetupBarSetRequested extends SpooferSettingsEvent {
  const SpooferSettingsShowSetupBarSetRequested({required this.value});

  final bool value;
}

class SpooferSettingsShowDebugPanelSetRequested extends SpooferSettingsEvent {
  const SpooferSettingsShowDebugPanelSetRequested({required this.value});

  final bool value;
}

class SpooferSettingsBackgroundEnabledSetRequested extends SpooferSettingsEvent {
  const SpooferSettingsBackgroundEnabledSetRequested({required this.value});

  final bool value;
}

class SpooferSettingsBackgroundBusySetRequested extends SpooferSettingsEvent {
  const SpooferSettingsBackgroundBusySetRequested({required this.value});

  final bool value;
}

class SpooferSettingsBackgroundNotificationShownSetRequested
    extends SpooferSettingsEvent {
  const SpooferSettingsBackgroundNotificationShownSetRequested({
    required this.value,
  });

  final bool value;
}

class SpooferSettingsDarkModeSetRequested extends SpooferSettingsEvent {
  const SpooferSettingsDarkModeSetRequested({required this.value});

  final DarkModeSetting value;
}
