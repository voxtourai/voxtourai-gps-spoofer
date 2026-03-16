import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/service/route_input_parser.dart';
import 'package:voxtourai_gps_spoofer/ui/widgets/route_input_dialog.dart';

void main() {
  group('RouteInputDialog', () {
    testWidgets(
      'opens clean and only shows required message after load click',
      (tester) async {
        await _pumpDialog(
          tester,
          initialValue: '',
          sampleRoute: 'demo_polyline',
        );

        expect(find.text('Input required to load a route.'), findsNothing);

        final loadButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Load'),
        );
        expect(loadButton.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Load'));
        await tester.pump();

        expect(find.text('Input required to load a route.'), findsOneWidget);
      },
    );

    testWidgets('shows polyline detected when parser resolves input', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        initialValue: '{"routes":[{"polyline":{"encodedPolyline":"abc"}}]}',
        sampleRoute: 'demo_polyline',
      );

      expect(find.text('Polyline detected.'), findsOneWidget);

      final loadButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Load'),
      );
      expect(loadButton.onPressed, isNotNull);
    });

    testWidgets('demo fills the sample route and invokes callback', (
      tester,
    ) async {
      var demoTapped = 0;
      const sampleRoute = 'encoded_demo_polyline';

      await _pumpDialog(
        tester,
        initialValue: '',
        sampleRoute: sampleRoute,
        onDemoFilled: () {
          demoTapped += 1;
        },
      );

      await tester.tap(find.text('Demo'));
      await tester.pump();

      expect(find.text(sampleRoute), findsOneWidget);
      expect(find.text('Polyline detected.'), findsOneWidget);
      expect(demoTapped, 1);
    });

    testWidgets('file import fills the input and shows the loaded file name', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        initialValue: '',
        sampleRoute: 'demo_polyline',
        pickFile: () async => const RouteInputPickedFile(
          text: '{"routes":[{"polyline":{"encodedPolyline":"abc"}}]}',
          name: 'route.json',
        ),
      );

      await tester.tap(find.text('File'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Loaded file: route.json'), findsOneWidget);
      expect(find.text('Polyline detected.'), findsOneWidget);
    });

    testWidgets('clear button removes input and resets validation state', (
      tester,
    ) async {
      await _pumpDialog(tester, initialValue: '', sampleRoute: 'demo_polyline');

      await tester.tap(find.widgetWithText(FilledButton, 'Load'));
      await tester.pump();

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();

      expect(find.text('Input required to load a route.'), findsNothing);
      final loadButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Load'),
      );
      expect(loadButton.onPressed, isNotNull);
    });
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required String initialValue,
  required String sampleRoute,
  VoidCallback? onDemoFilled,
  RouteInputFilePicker? pickFile,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RouteInputDialog(
          initialValue: initialValue,
          sampleRoute: sampleRoute,
          detectPolyline: extractPolylineFromInput,
          onDemoFilled: onDemoFilled,
          pickFile: pickFile,
        ),
      ),
    ),
  );
}
