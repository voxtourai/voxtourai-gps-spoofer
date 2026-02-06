import 'dart:math' as math;

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteController {
  List<LatLng> _points = [];
  List<double> _cumulativeMeters = [];
  double _totalDistanceMeters = 0;
  double _progress = 0;

  List<LatLng> get points => _points;
  double get totalDistanceMeters => _totalDistanceMeters;
  double get progress => _progress;

  bool get hasRoute => _points.length >= 2;
  bool get hasPoints => _points.isNotEmpty;

  double get progressDistance => _totalDistanceMeters * _progress;

  void clear() {
    _points = [];
    _cumulativeMeters = [];
    _totalDistanceMeters = 0;
    _progress = 0;
  }

  void setRoute(List<LatLng> points) {
    _points = points;
    _cumulativeMeters = _buildCumulativeMeters(points);
    _totalDistanceMeters = _cumulativeMeters.isEmpty ? 0 : _cumulativeMeters.last;
    _progress = 0;
  }

  void setProgress(double value) {
    _progress = _clamp01(value);
  }

  double distanceForProgress(double progress) {
    return _totalDistanceMeters * _clamp01(progress);
  }

  LatLng? positionForProgress(double progress) {
    if (_points.isEmpty) {
      return null;
    }
    if (_totalDistanceMeters == 0) {
      return _points.first;
    }
    return positionAtDistance(distanceForProgress(progress));
  }

  LatLng? positionForCurrentProgress() => positionForProgress(_progress);

  List<LatLng> decodePolyline(String encoded) {
    final points = PolylinePoints().decodePolyline(encoded);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  LatLng positionAtDistance(double meters) {
    if (meters <= 0) {
      return _points.first;
    }
    if (meters >= _totalDistanceMeters) {
      return _points.last;
    }

    final index = _upperBound(_cumulativeMeters, meters);
    final startIndex = math.max(0, index - 1);
    final endIndex = math.min(_points.length - 1, index);

    final startDistance = _cumulativeMeters[startIndex];
    final endDistance = _cumulativeMeters[endIndex];
    final segmentLength = endDistance - startDistance;

    if (segmentLength <= 0) {
      return _points[startIndex];
    }

    final t = (meters - startDistance) / segmentLength;
    return _interpolate(_points[startIndex], _points[endIndex], t);
  }

  List<double> _buildCumulativeMeters(List<LatLng> points) {
    if (points.isEmpty) {
      return [];
    }
    final cumulative = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      cumulative[i] = cumulative[i - 1] + _distanceMeters(points[i - 1], points[i]);
    }
    return cumulative;
  }

  int _upperBound(List<double> values, double target) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (values[mid] <= target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final aa = sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLng * sinDLng;
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return earthRadius * c;
  }

  double _degToRad(double degrees) => degrees * (math.pi / 180.0);

  LatLng _interpolate(LatLng start, LatLng end, double t) {
    final lat = start.latitude + (end.latitude - start.latitude) * t;
    final lng = start.longitude + (end.longitude - start.longitude) * t;
    return LatLng(lat, lng);
  }

  double _clamp01(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}
