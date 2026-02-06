import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesController {
  static const String _tosAcceptedKey = 'tos_accepted_v1';
  static const String _savedRoutesKey = 'saved_custom_routes_v1';

  Future<bool> isTosAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tosAcceptedKey) ?? false;
  }

  Future<void> setTosAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tosAcceptedKey, accepted);
  }

  Future<List<Map<String, Object?>>> loadSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoutesKey);
    if (raw == null) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((entry) => entry.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  Future<void> saveRoutes(List<Map<String, Object?>> routes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedRoutesKey, jsonEncode(routes));
  }

  Future<void> upsertSavedRoute({
    required String name,
    required List<LatLng> points,
    required List<String> names,
  }) async {
    final routes = await loadSavedRoutes();
    final entry = {
      'name': name,
      'points': [
        for (final p in points)
          {
            'lat': p.latitude,
            'lng': p.longitude,
          }
      ],
      'names': List<String>.from(names),
    };
    final index = routes.indexWhere((e) => e['name'] == name);
    if (index >= 0) {
      routes[index] = entry;
    } else {
      routes.add(entry);
    }
    await saveRoutes(routes);
  }
}
