import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/bloc/mock/spoofer_mock_bloc.dart';
import 'package:voxtourai_gps_spoofer/bloc/mock/spoofer_mock_event.dart';
import 'package:voxtourai_gps_spoofer/bloc/mock/spoofer_mock_state.dart';
import 'package:voxtourai_gps_spoofer/service/infrastructure/mock_location_gateway.dart';

void main() {
  group('SpooferMockBloc', () {
    blocTest<SpooferMockBloc, SpooferMockState>(
      'startup checks prompt app settings when location permission is denied',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(),
        requestLocationPermission: () async => false,
      ),
      act: (bloc) =>
          bloc.add(const SpooferMockStartupChecksRequested(showDialogs: true)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.startupChecksRunning, false);
        expect(bloc.state.hasLocationPermission, false);
        expect(bloc.state.prompt?.type, SpooferMockPromptType.openAppSettings);
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'startup checks prompt developer settings when developer mode is disabled',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(
          isDeveloperModeEnabledValue: false,
        ),
        requestLocationPermission: () async => true,
      ),
      act: (bloc) =>
          bloc.add(const SpooferMockStartupChecksRequested(showDialogs: true)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.hasLocationPermission, true);
        expect(bloc.state.isDeveloperModeEnabled, false);
        expect(
          bloc.state.prompt?.type,
          SpooferMockPromptType.openDeveloperOptions,
        );
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'startup checks prompt mock app selection when app is not selected',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(isMockApp: false),
        requestLocationPermission: () async => true,
      ),
      act: (bloc) =>
          bloc.add(const SpooferMockStartupChecksRequested(showDialogs: true)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.isDeveloperModeEnabled, true);
        expect(bloc.state.isMockLocationApp, false);
        expect(
          bloc.state.prompt?.type,
          SpooferMockPromptType.selectMockLocationApp,
        );
      },
    );

    var openedAppSettings = false;
    blocTest<SpooferMockBloc, SpooferMockState>(
      'prompt resolution invokes app settings action',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(),
        requestLocationPermission: () async => false,
        openAppSettingsAction: () async {
          openedAppSettings = true;
          return true;
        },
      ),
      act: (bloc) async {
        bloc.add(const SpooferMockStartupChecksRequested(showDialogs: true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final promptId = bloc.state.prompt?.id;
        expect(promptId, isNotNull);
        bloc.add(
          SpooferMockPromptResolved(promptId: promptId!, accepted: true),
        );
      },
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(openedAppSettings, true);
        expect(bloc.state.prompt, isNull);
      },
    );

    late _FakeMockLocationGateway developerSettingsGateway;
    blocTest<SpooferMockBloc, SpooferMockState>(
      'prompt resolution opens developer settings for developer prompts',
      build: () => SpooferMockBloc(
        mockGateway: developerSettingsGateway = _FakeMockLocationGateway(
          isDeveloperModeEnabledValue: false,
        ),
        requestLocationPermission: () async => true,
      ),
      act: (bloc) async {
        bloc.add(const SpooferMockStartupChecksRequested(showDialogs: true));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final promptId = bloc.state.prompt?.id;
        expect(promptId, isNotNull);
        bloc.add(
          SpooferMockPromptResolved(promptId: promptId!, accepted: true),
        );
      },
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(developerSettingsGateway.openDeveloperSettingsCalls, 1);
        expect(bloc.state.prompt, isNull);
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'apply location reports gps not applied error',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(
          applyResult: <String, Object?>{
            'gpsApplied': false,
            'mockAppSelected': true,
            'gpsError': 'gps provider is not a test provider',
          },
        ),
      ),
      act: (bloc) => bloc.add(
        const SpooferMockApplyLocationRequested(
          latitude: 40.0,
          longitude: -73.0,
          accuracy: 3,
          speedMps: 4,
        ),
      ),
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(bloc.state.mockError, contains('Mock GPS not applied'));
        expect(bloc.state.lastMockStatus?['gpsApplied'], false);
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'successful apply clears prior mock errors',
      build: () => SpooferMockBloc(mockGateway: _FakeMockLocationGateway()),
      act: (bloc) {
        bloc
          ..add(const SpooferMockErrorSetRequested(message: 'previous error'))
          ..add(
            const SpooferMockApplyLocationRequested(
              latitude: 40.0,
              longitude: -73.0,
              accuracy: 3,
              speedMps: 4,
            ),
          );
      },
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(bloc.state.mockError, isNull);
        expect(bloc.state.debugLog.last, contains('Mock apply ok.'));
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'apply location failure surfaces a throttled mock error',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(
          applyException: PlatformException(
            code: 'apply_failed',
            message: 'apply boom',
          ),
        ),
      ),
      act: (bloc) => bloc.add(
        const SpooferMockApplyLocationRequested(
          latitude: 40.0,
          longitude: -73.0,
          accuracy: 3,
          speedMps: 4,
        ),
      ),
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(
          bloc.state.mockError,
          contains('Mock location failed: apply boom'),
        );
        expect(
          bloc.state.debugLog.last,
          contains('Mock exception: apply boom'),
        );
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'refresh status updates selected package and selection state',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(
          selectedMockApp: 'ai.voxtour.voxtourai_gps_spoofer',
          isMockApp: true,
        ),
      ),
      act: (bloc) => bloc.add(const SpooferMockRefreshStatusRequested()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.selectedMockApp, 'ai.voxtour.voxtourai_gps_spoofer');
        expect(bloc.state.isMockLocationApp, true);
      },
    );

    blocTest<SpooferMockBloc, SpooferMockState>(
      'clear location failure surfaces a user message',
      build: () => SpooferMockBloc(
        mockGateway: _FakeMockLocationGateway(
          clearException: PlatformException(
            code: 'clear_failed',
            message: 'clear boom',
          ),
        ),
      ),
      act: (bloc) => bloc.add(const SpooferMockClearLocationRequested()),
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(
          bloc.state.message?.text,
          contains('Failed to clear mock location'),
        );
        expect(
          bloc.state.debugLog.last,
          contains('Clear mock failed: clear boom'),
        );
      },
    );
  });
}

class _FakeMockLocationGateway extends MockLocationGateway {
  _FakeMockLocationGateway({
    this.applyResult,
    this.isMockApp = true,
    this.isDeveloperModeEnabledValue = true,
    this.selectedMockApp,
    this.applyException,
    this.clearException,
  });

  final Map<String, Object?>? applyResult;
  final bool isMockApp;
  final bool isDeveloperModeEnabledValue;
  final String? selectedMockApp;
  final PlatformException? applyException;
  final PlatformException? clearException;
  int openDeveloperSettingsCalls = 0;

  @override
  Future<Map<String, Object?>?> setMockLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speedMps,
  }) async {
    if (applyException != null) {
      throw applyException!;
    }
    return applyResult ??
        <String, Object?>{'gpsApplied': true, 'mockAppSelected': true};
  }

  @override
  Future<Map<String, Object?>?> clearMockLocation() async {
    if (clearException != null) {
      throw clearException!;
    }
    return <String, Object?>{'gpsApplied': true, 'fusedApplied': true};
  }

  @override
  Future<bool> isDeveloperModeEnabled() async => isDeveloperModeEnabledValue;

  @override
  Future<bool> isMockLocationApp() async => isMockApp;

  @override
  Future<String?> getMockLocationApp() async => selectedMockApp;

  @override
  Future<void> openDeveloperSettings() async {
    openDeveloperSettingsCalls += 1;
  }
}
