import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_settings_state.dart';

class SpooferSettingsCubit extends Cubit<SpooferSettingsState> {
  SpooferSettingsCubit() : super(const SpooferSettingsState());

  void setShowMockMarker(bool value) {
    if (state.showMockMarker == value) {
      return;
    }
    emit(state.copyWith(showMockMarker: value));
  }

  void setShowSetupBar(bool value) {
    if (state.showSetupBar == value) {
      return;
    }
    emit(state.copyWith(showSetupBar: value));
  }

  void setShowDebugPanel(bool value) {
    if (state.showDebugPanel == value) {
      return;
    }
    emit(state.copyWith(showDebugPanel: value));
  }

  void setBackgroundEnabled(bool value) {
    if (state.backgroundEnabled == value) {
      return;
    }
    emit(state.copyWith(backgroundEnabled: value));
  }

  void setBackgroundBusy(bool value) {
    if (state.backgroundBusy == value) {
      return;
    }
    emit(state.copyWith(backgroundBusy: value));
  }

  void setBackgroundNotificationShown(bool value) {
    if (state.backgroundNotificationShown == value) {
      return;
    }
    emit(state.copyWith(backgroundNotificationShown: value));
  }

  void setDarkModeSetting(DarkModeSetting value) {
    if (state.darkModeSetting == value) {
      return;
    }
    emit(state.copyWith(darkModeSetting: value));
  }
}
