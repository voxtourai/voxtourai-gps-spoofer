import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@immutable
class SavedRoute {
  const SavedRoute({
    required this.name,
    required this.points,
    required this.waypointNames,
  });

  final String name;
  final List<LatLng> points;
  final List<String> waypointNames;

  factory SavedRoute.fromJson(Map<String, Object?> json) {
    final name = json['name']?.toString().trim() ?? '';
    return SavedRoute(
      name: name.isEmpty ? 'Route' : name,
      points: List<LatLng>.unmodifiable(_parsePoints(json['points'])),
      waypointNames: List<String>.unmodifiable(
        _parseNames(json['names'] ?? json['waypointNames']),
      ),
    );
  }

  static SavedRoute? maybeFromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return SavedRoute.fromJson(
      value.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'points': <Map<String, double>>[
        for (final point in points)
          <String, double>{'lat': point.latitude, 'lng': point.longitude},
      ],
      'names': List<String>.from(waypointNames),
    };
  }

  static List<LatLng> _parsePoints(dynamic rawPoints) {
    if (rawPoints is! List) {
      return const <LatLng>[];
    }

    final points = <LatLng>[];
    for (final point in rawPoints) {
      if (point is! Map) {
        continue;
      }
      final lat = point['lat'];
      final lng = point['lng'];
      if (lat is num && lng is num) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    return points;
  }

  static List<String> _parseNames(dynamic rawNames) {
    if (rawNames is! List) {
      return const <String>[];
    }
    return rawNames.map((name) => name.toString()).toList();
  }
}
