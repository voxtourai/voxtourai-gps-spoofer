import 'dart:convert';

String? extractPolylineFromInput(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final unquoted = _stripSurroundingQuotes(trimmed);
  if (unquoted.startsWith('{') || unquoted.startsWith('[')) {
    try {
      final dynamic data = jsonDecode(unquoted);
      final extracted = _extractPolylineFromJson(data);
      if (extracted != null && extracted.isNotEmpty) {
        return extracted;
      }
    } catch (_) {
      // Fall back to regex or raw input.
    }
    final match = RegExp(
      r'encodedPolyline\"?\s*:\s*\"([^\"]+)\"',
    ).firstMatch(unquoted);
    if (match != null) {
      return match.group(1);
    }
  }

  return unquoted;
}

String _stripSurroundingQuotes(String value) {
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

String? _extractPolylineFromJson(dynamic data) {
  if (data is Map) {
    final direct = _extractPolylineFromMap(data.cast<String, dynamic>());
    if (direct != null) {
      return direct;
    }
  }
  if (data is List) {
    for (final item in data) {
      final found = _extractPolylineFromJson(item);
      if (found != null) {
        return found;
      }
    }
  }
  return null;
}

String? _extractPolylineFromMap(Map<String, dynamic> map) {
  final direct =
      map['encodedPolyline'] ?? map['routePolyline'] ?? map['polyline'];
  if (direct is String) {
    return direct;
  }
  final polylineNode = map['polyline'];
  if (polylineNode is Map) {
    final encoded = polylineNode['encodedPolyline'];
    if (encoded is String) {
      return encoded;
    }
  }
  final routes = map['routes'];
  if (routes is List && routes.isNotEmpty) {
    return _extractPolylineFromJson(routes);
  }
  return null;
}
