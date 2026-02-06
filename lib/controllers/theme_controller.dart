import 'package:flutter/material.dart';

class ThemeController {
  ThemeController();

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);
}

final ThemeController themeController = ThemeController();
