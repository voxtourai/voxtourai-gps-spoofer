import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/settings/spoofer_settings_bloc.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/settings/spoofer_settings_event.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/settings/spoofer_settings_state.dart';

void main() {
  group('SpooferSettingsBloc', () {
    blocTest<SpooferSettingsBloc, SpooferSettingsState>(
      'updates toggles and dark mode from events',
      build: SpooferSettingsBloc.new,
      act: (bloc) {
        bloc
          ..add(const SpooferSettingsShowSetupBarSetRequested(value: true))
          ..add(const SpooferSettingsShowDebugPanelSetRequested(value: true))
          ..add(const SpooferSettingsShowMockMarkerSetRequested(value: true))
          ..add(const SpooferSettingsBackgroundEnabledSetRequested(value: true))
          ..add(const SpooferSettingsBackgroundBusySetRequested(value: true))
          ..add(
            const SpooferSettingsBackgroundNotificationShownSetRequested(
              value: true,
            ),
          )
          ..add(const SpooferSettingsDarkModeSetRequested(value: DarkModeSetting.mapOnly));
      },
      verify: (bloc) {
        expect(bloc.state.showSetupBar, true);
        expect(bloc.state.showDebugPanel, true);
        expect(bloc.state.showMockMarker, true);
        expect(bloc.state.backgroundEnabled, true);
        expect(bloc.state.backgroundBusy, true);
        expect(bloc.state.backgroundNotificationShown, true);
        expect(bloc.state.darkModeSetting, DarkModeSetting.mapOnly);
      },
    );
  });
}
