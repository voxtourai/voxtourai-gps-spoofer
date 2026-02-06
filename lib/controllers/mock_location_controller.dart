import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockLocationController {
  const MockLocationController();

  static const MethodChannel _channel = MethodChannel('voxtourai_gps_spoofer/mock_location');

  Future<Map<String, Object?>?> setMockLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speedMps,
  }) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('setMockLocation', {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speedMps': speedMps,
    });
    return _stringify(result);
  }

  Future<Map<String, Object?>?> clearMockLocation() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('clearMockLocation');
    return _stringify(result);
  }

  Future<LatLng?> getCurrentLocation() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getCurrentLocation');
    return _locationFromResult(result);
  }

  Future<LatLng?> getLastKnownLocation() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getLastKnownLocation');
    return _locationFromResult(result);
  }

  Future<Map<String, Object?>?> getMockDebug() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getMockDebug');
    return _stringify(result);
  }

  Future<bool> isDeveloperModeEnabled() async {
    final enabled = await _channel.invokeMethod<bool>('isDeveloperModeEnabled');
    return enabled ?? false;
  }

  Future<bool> isMockLocationApp() async {
    final enabled = await _channel.invokeMethod<bool>('isMockLocationApp');
    return enabled ?? false;
  }

  Future<String?> getMockLocationApp() async {
    return _channel.invokeMethod<String>('getMockLocationApp');
  }

  Future<void> openDeveloperSettings() async {
    await _channel.invokeMethod('openDeveloperSettings');
  }

  Future<List<Map<String, Object?>>> geocodeAddress(String query, {int maxResults = 8}) async {
    final response = await _channel.invokeMethod<List<dynamic>>('geocodeAddress', {
      'query': query,
      'maxResults': maxResults,
    });
    final results = <Map<String, Object?>>[];
    for (final entry in response ?? []) {
      if (entry is Map) {
        results.add(entry.map((key, value) => MapEntry(key.toString(), value)));
      }
    }
    return results;
  }

  Map<String, Object?>? _stringify(Map<Object?, Object?>? map) {
    if (map == null) {
      return null;
    }
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  LatLng? _locationFromResult(Map<Object?, Object?>? result) {
    if (result == null) {
      return null;
    }
    final lat = result['latitude'];
    final lng = result['longitude'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    return null;
  }
}

const MockLocationController mockLocationController = MockLocationController();
