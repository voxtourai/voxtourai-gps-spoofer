import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/saved_route.dart';

class PreferencesStore {
  static const String _tosAcceptedKey = 'tos_accepted_v1';
  static const String _savedRoutesKey = 'saved_custom_routes_v1';
  static const String _startupPromptsShownKey = 'startup_prompts_shown_v1';

  Future<bool> isTosAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tosAcceptedKey) ?? false;
  }

  Future<void> setTosAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tosAcceptedKey, accepted);
  }

  Future<bool> isStartupPromptsShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_startupPromptsShownKey) ?? false;
  }

  Future<void> setStartupPromptsShown(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_startupPromptsShownKey, shown);
  }

  Future<List<SavedRoute>> loadSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoutesKey);
    if (raw == null) {
      return const <SavedRoute>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <SavedRoute>[];
    }
    return decoded
        .map(SavedRoute.maybeFromJson)
        .whereType<SavedRoute>()
        .toList();
  }

  Future<void> saveRoutes(List<SavedRoute> routes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedRoutesKey,
      jsonEncode(routes.map((route) => route.toJson()).toList()),
    );
  }

  Future<void> upsertSavedRoute({
    required String name,
    required List<LatLng> points,
    required List<String> names,
  }) async {
    final routes = await loadSavedRoutes();
    final entry = SavedRoute(
      name: name,
      points: List<LatLng>.unmodifiable(points),
      waypointNames: List<String>.unmodifiable(names),
    );
    final index = routes.indexWhere((route) => route.name == name);
    if (index >= 0) {
      routes[index] = entry;
    } else {
      routes.add(entry);
    }
    await saveRoutes(routes);
  }
}
