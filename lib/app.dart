import 'package:flutter/material.dart';

import 'controllers/mock_location_controller.dart';
import 'controllers/theme_controller.dart';
import 'ui/screens/spoofer_screen.dart';

class GpsSpooferApp extends StatelessWidget {
  const GpsSpooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'GPS Spoofer',
          theme: ThemeData(
            colorSchemeSeed: Colors.blueGrey,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.blueGrey,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: mode,
          home: SpooferScreen(mockController: mockLocationController),
        );
      },
    );
  }
}
