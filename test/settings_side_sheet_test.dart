import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/bloc/settings/spoofer_settings_state.dart';
import 'package:voxtourai_gps_spoofer/ui/widgets/settings_side_sheet.dart';

void main() {
  group('showSpooferSettingsSideSheet', () {
    testWidgets('toggle callbacks update from the settings sheet', (
      tester,
    ) async {
      final harness = _SettingsSheetCallbacks();
      await _pumpHost(
        tester,
        callbacks: harness,
        initialSettings: const SpooferSettingsState(),
      );

      await _openSettingsSheet(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Show setup bar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Show mocked marker'));
      await tester.pump();

      expect(harness.showSetupBarValues, <bool>[true]);
      expect(harness.showMockMarkerValues, <bool>[true]);
    });

    testWidgets('dark mode dropdown invokes callback with selected value', (
      tester,
    ) async {
      final harness = _SettingsSheetCallbacks();
      await _pumpHost(
        tester,
        callbacks: harness,
        initialSettings: const SpooferSettingsState(),
      );

      await _openSettingsSheet(tester);

      await tester.tap(find.text('On'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Map only').last);
      await tester.pumpAndSettle();

      expect(harness.darkModeValues, <DarkModeSetting>[
        DarkModeSetting.mapOnly,
      ]);
    });

    testWidgets('action buttons invoke callbacks and close on setup run', (
      tester,
    ) async {
      final harness = _SettingsSheetCallbacks();
      await _pumpHost(
        tester,
        callbacks: harness,
        initialSettings: const SpooferSettingsState(),
      );

      await _openSettingsSheet(tester);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Disable mock location'),
      );
      await tester.pump();
      expect(harness.disableMockLocationCalls, 1);

      await tester.tap(find.widgetWithText(FilledButton, 'Run setup checks'));
      await tester.pumpAndSettle();

      expect(harness.runSetupChecksCalls, 1);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('privacy policy button invokes callback and closes sheet', (
      tester,
    ) async {
      final harness = _SettingsSheetCallbacks();
      await _pumpHost(
        tester,
        callbacks: harness,
        initialSettings: const SpooferSettingsState(),
      );

      await _openSettingsSheet(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Privacy policy'));
      await tester.pumpAndSettle();

      expect(harness.openPrivacyPolicyCalls, 1);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('developer options button invokes callback and closes sheet', (
      tester,
    ) async {
      final harness = _SettingsSheetCallbacks();
      await _pumpHost(
        tester,
        callbacks: harness,
        initialSettings: const SpooferSettingsState(),
      );

      await _openSettingsSheet(tester);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Open developer options'),
      );
      await tester.pumpAndSettle();

      expect(harness.openDeveloperOptionsCalls, 1);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('debug panel button invokes callback and closes sheet', (
      tester,
    ) async {
      final harness = _SettingsSheetCallbacks();
      await _pumpHost(
        tester,
        callbacks: harness,
        initialSettings: const SpooferSettingsState(),
      );

      await _openSettingsSheet(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Open debug panel'));
      await tester.pumpAndSettle();

      expect(harness.openDebugPanelCalls, 1);
      expect(find.text('Settings'), findsNothing);
    });
  });
}

class _SettingsSheetCallbacks {
  final List<bool> showSetupBarValues = <bool>[];
  final List<bool> showMockMarkerValues = <bool>[];
  final List<DarkModeSetting> darkModeValues = <DarkModeSetting>[];
  int disableMockLocationCalls = 0;
  int openDeveloperOptionsCalls = 0;
  int openPrivacyPolicyCalls = 0;
  int openDebugPanelCalls = 0;
  int runSetupChecksCalls = 0;
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required _SettingsSheetCallbacks callbacks,
  required SpooferSettingsState initialSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  showSpooferSettingsSideSheet(
                    context: context,
                    initialSettings: initialSettings,
                    onShowSetupBarChanged: callbacks.showSetupBarValues.add,
                    onShowMockMarkerChanged: callbacks.showMockMarkerValues.add,
                    onDarkModeChanged: callbacks.darkModeValues.add,
                    onDisableMockLocation: () async {
                      callbacks.disableMockLocationCalls += 1;
                    },
                    onOpenDeveloperOptions: () async {
                      callbacks.openDeveloperOptionsCalls += 1;
                    },
                    onOpenPrivacyPolicy: () async {
                      callbacks.openPrivacyPolicyCalls += 1;
                    },
                    onOpenDebugPanel: () async {
                      callbacks.openDebugPanelCalls += 1;
                    },
                    onRunSetupChecks: () {
                      callbacks.runSetupChecksCalls += 1;
                    },
                  );
                },
                child: const Text('Open settings'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> _openSettingsSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open settings'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}
