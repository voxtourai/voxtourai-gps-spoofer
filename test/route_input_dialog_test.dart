import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/domain/route_input_parser.dart';
import 'package:voxtourai_gps_spoofer/ui/widgets/route_input_dialog.dart';

void main() {
  group('RouteInputDialog', () {
    testWidgets('shows required message and disables load when empty', (
      tester,
    ) async {
      await _pumpDialog(tester, initialValue: '', sampleRoute: 'demo_polyline');

      expect(find.text('Input required to load a route.'), findsOneWidget);

      final loadButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Load'),
      );
      expect(loadButton.onPressed, isNull);
    });

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

    testWidgets('clear button removes input and disables load again', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        initialValue: 'prefilled_polyline',
        sampleRoute: 'demo_polyline',
      );

      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();

      expect(find.text('Input required to load a route.'), findsOneWidget);
      final loadButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Load'),
      );
      expect(loadButton.onPressed, isNull);
    });
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required String initialValue,
  required String sampleRoute,
  VoidCallback? onDemoFilled,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RouteInputDialog(
          initialValue: initialValue,
          sampleRoute: sampleRoute,
          detectPolyline: extractPolylineFromInput,
          onDemoFilled: onDemoFilled,
        ),
      ),
    ),
  );
}
