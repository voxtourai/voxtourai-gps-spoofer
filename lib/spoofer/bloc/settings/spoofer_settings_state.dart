import 'package:flutter/foundation.dart';

enum DarkModeSetting {
  on,
  uiOnly,
  mapOnly,
  off,
}

@immutable
class SpooferSettingsState {
  const SpooferSettingsState({
    this.showMockMarker = false,
    this.showSetupBar = false,
    this.showDebugPanel = false,
    this.backgroundEnabled = false,
    this.backgroundBusy = false,
    this.backgroundNotificationShown = false,
    this.darkModeSetting = DarkModeSetting.on,
  });

  final bool showMockMarker;
  final bool showSetupBar;
  final bool showDebugPanel;
  final bool backgroundEnabled;
  final bool backgroundBusy;
  final bool backgroundNotificationShown;
  final DarkModeSetting darkModeSetting;

  SpooferSettingsState copyWith({
    bool? showMockMarker,
    bool? showSetupBar,
    bool? showDebugPanel,
    bool? backgroundEnabled,
    bool? backgroundBusy,
    bool? backgroundNotificationShown,
    DarkModeSetting? darkModeSetting,
  }) {
    return SpooferSettingsState(
      showMockMarker: showMockMarker ?? this.showMockMarker,
      showSetupBar: showSetupBar ?? this.showSetupBar,
      showDebugPanel: showDebugPanel ?? this.showDebugPanel,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      backgroundBusy: backgroundBusy ?? this.backgroundBusy,
      backgroundNotificationShown:
          backgroundNotificationShown ?? this.backgroundNotificationShown,
      darkModeSetting: darkModeSetting ?? this.darkModeSetting,
    );
  }
}
