import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voxtourai_gps_spoofer/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots and shows primary controls', (tester) async {
    app.main();

    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(find.text('GPS Spoofer'), findsOneWidget);
    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.byTooltip('Help'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });
}
