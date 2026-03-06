import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/bloc/mock/spoofer_mock_bloc.dart';
import 'package:voxtourai_gps_spoofer/bloc/mock/spoofer_mock_event.dart';
import 'package:voxtourai_gps_spoofer/bloc/mock/spoofer_mock_state.dart';
import 'package:voxtourai_gps_spoofer/infrastructure/mock_location_gateway.dart';

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
  });
}

class _FakeMockLocationGateway extends MockLocationGateway {
  _FakeMockLocationGateway({
    this.applyResult,
    this.isMockApp = true,
    this.selectedMockApp,
  });

  final Map<String, Object?>? applyResult;
  final bool isMockApp;
  final String? selectedMockApp;

  @override
  Future<Map<String, Object?>?> setMockLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speedMps,
  }) async {
    return applyResult ??
        <String, Object?>{'gpsApplied': true, 'mockAppSelected': true};
  }

  @override
  Future<Map<String, Object?>?> clearMockLocation() async {
    return <String, Object?>{'gpsApplied': true, 'fusedApplied': true};
  }

  @override
  Future<bool> isDeveloperModeEnabled() async => true;

  @override
  Future<bool> isMockLocationApp() async => isMockApp;

  @override
  Future<String?> getMockLocationApp() async => selectedMockApp;

  @override
  Future<void> openDeveloperSettings() async {}
}
