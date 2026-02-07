import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_settings_event.dart';
import 'spoofer_settings_state.dart';

class SpooferSettingsBloc
    extends Bloc<SpooferSettingsEvent, SpooferSettingsState> {
  SpooferSettingsBloc() : super(const SpooferSettingsState()) {
    on<SpooferSettingsShowMockMarkerSetRequested>(_onShowMockMarkerSetRequested);
    on<SpooferSettingsShowSetupBarSetRequested>(_onShowSetupBarSetRequested);
    on<SpooferSettingsShowDebugPanelSetRequested>(_onShowDebugPanelSetRequested);
    on<SpooferSettingsBackgroundEnabledSetRequested>(
      _onBackgroundEnabledSetRequested,
    );
    on<SpooferSettingsBackgroundBusySetRequested>(
      _onBackgroundBusySetRequested,
    );
    on<SpooferSettingsBackgroundNotificationShownSetRequested>(
      _onBackgroundNotificationShownSetRequested,
    );
    on<SpooferSettingsDarkModeSetRequested>(_onDarkModeSetRequested);
  }

  void _onShowMockMarkerSetRequested(
    SpooferSettingsShowMockMarkerSetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.showMockMarker == event.value) {
      return;
    }
    emit(state.copyWith(showMockMarker: event.value));
  }

  void _onShowSetupBarSetRequested(
    SpooferSettingsShowSetupBarSetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.showSetupBar == event.value) {
      return;
    }
    emit(state.copyWith(showSetupBar: event.value));
  }

  void _onShowDebugPanelSetRequested(
    SpooferSettingsShowDebugPanelSetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.showDebugPanel == event.value) {
      return;
    }
    emit(state.copyWith(showDebugPanel: event.value));
  }

  void _onBackgroundEnabledSetRequested(
    SpooferSettingsBackgroundEnabledSetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.backgroundEnabled == event.value) {
      return;
    }
    emit(state.copyWith(backgroundEnabled: event.value));
  }

  void _onBackgroundBusySetRequested(
    SpooferSettingsBackgroundBusySetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.backgroundBusy == event.value) {
      return;
    }
    emit(state.copyWith(backgroundBusy: event.value));
  }

  void _onBackgroundNotificationShownSetRequested(
    SpooferSettingsBackgroundNotificationShownSetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.backgroundNotificationShown == event.value) {
      return;
    }
    emit(state.copyWith(backgroundNotificationShown: event.value));
  }

  void _onDarkModeSetRequested(
    SpooferSettingsDarkModeSetRequested event,
    Emitter<SpooferSettingsState> emit,
  ) {
    if (state.darkModeSetting == event.value) {
      return;
    }
    emit(state.copyWith(darkModeSetting: event.value));
  }
}
