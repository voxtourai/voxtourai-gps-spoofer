import 'package:flutter/foundation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'spoofer_settings_state.g.dart';

enum DarkModeSetting { on, uiOnly, mapOnly, off }

@immutable
@CopyWith()
class SpooferSettingsState {
  const SpooferSettingsState({
    this.showMockMarker = false,
    this.showSetupBar = false,
    this.showDebugPanel = false,
    this.backgroundEnabled = true,
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
}
