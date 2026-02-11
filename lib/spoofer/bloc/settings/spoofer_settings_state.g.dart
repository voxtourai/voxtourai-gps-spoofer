// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_settings_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferSettingsStateCWProxy {
  SpooferSettingsState showMockMarker(bool showMockMarker);

  SpooferSettingsState showSetupBar(bool showSetupBar);

  SpooferSettingsState showDebugPanel(bool showDebugPanel);

  SpooferSettingsState backgroundEnabled(bool backgroundEnabled);

  SpooferSettingsState backgroundBusy(bool backgroundBusy);

  SpooferSettingsState backgroundNotificationShown(bool backgroundNotificationShown);

  SpooferSettingsState darkModeSetting(DarkModeSetting darkModeSetting);

  /// Creates a new instance with the provided field values.
  SpooferSettingsState call({
    bool showMockMarker,
    bool showSetupBar,
    bool showDebugPanel,
    bool backgroundEnabled,
    bool backgroundBusy,
    bool backgroundNotificationShown,
    DarkModeSetting darkModeSetting,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferSettingsState.copyWith(...)` or
/// `instanceOfSpooferSettingsState.copyWith.fieldName(...)`.
class _$SpooferSettingsStateCWProxyImpl implements _$SpooferSettingsStateCWProxy {
  const _$SpooferSettingsStateCWProxyImpl(this._value);

  final SpooferSettingsState _value;

  @override
  SpooferSettingsState showMockMarker(bool showMockMarker) => call(showMockMarker: showMockMarker);

  @override
  SpooferSettingsState showSetupBar(bool showSetupBar) => call(showSetupBar: showSetupBar);

  @override
  SpooferSettingsState showDebugPanel(bool showDebugPanel) => call(showDebugPanel: showDebugPanel);

  @override
  SpooferSettingsState backgroundEnabled(bool backgroundEnabled) => call(backgroundEnabled: backgroundEnabled);

  @override
  SpooferSettingsState backgroundBusy(bool backgroundBusy) => call(backgroundBusy: backgroundBusy);

  @override
  SpooferSettingsState backgroundNotificationShown(bool backgroundNotificationShown) =>
      call(backgroundNotificationShown: backgroundNotificationShown);

  @override
  SpooferSettingsState darkModeSetting(DarkModeSetting darkModeSetting) =>
      call(darkModeSetting: darkModeSetting);

  @override
  SpooferSettingsState call({
    Object? showMockMarker = const $CopyWithPlaceholder(),
    Object? showSetupBar = const $CopyWithPlaceholder(),
    Object? showDebugPanel = const $CopyWithPlaceholder(),
    Object? backgroundEnabled = const $CopyWithPlaceholder(),
    Object? backgroundBusy = const $CopyWithPlaceholder(),
    Object? backgroundNotificationShown = const $CopyWithPlaceholder(),
    Object? darkModeSetting = const $CopyWithPlaceholder(),
  }) {
    return SpooferSettingsState(
      showMockMarker: showMockMarker == const $CopyWithPlaceholder() || showMockMarker == null
          ? _value.showMockMarker
          : showMockMarker as bool,
      showSetupBar: showSetupBar == const $CopyWithPlaceholder() || showSetupBar == null
          ? _value.showSetupBar
          : showSetupBar as bool,
      showDebugPanel: showDebugPanel == const $CopyWithPlaceholder() || showDebugPanel == null
          ? _value.showDebugPanel
          : showDebugPanel as bool,
      backgroundEnabled: backgroundEnabled == const $CopyWithPlaceholder() || backgroundEnabled == null
          ? _value.backgroundEnabled
          : backgroundEnabled as bool,
      backgroundBusy: backgroundBusy == const $CopyWithPlaceholder() || backgroundBusy == null
          ? _value.backgroundBusy
          : backgroundBusy as bool,
      backgroundNotificationShown:
          backgroundNotificationShown == const $CopyWithPlaceholder() || backgroundNotificationShown == null
              ? _value.backgroundNotificationShown
              : backgroundNotificationShown as bool,
      darkModeSetting: darkModeSetting == const $CopyWithPlaceholder() || darkModeSetting == null
          ? _value.darkModeSetting
          : darkModeSetting as DarkModeSetting,
    );
  }
}

extension $SpooferSettingsStateCopyWith on SpooferSettingsState {
  /// Returns a callable class used to build a new instance with modified fields.
  _$SpooferSettingsStateCWProxy get copyWith => _$SpooferSettingsStateCWProxyImpl(this);
}
