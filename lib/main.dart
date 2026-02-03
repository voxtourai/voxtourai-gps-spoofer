import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const String _defaultApiBase = 'https://api.voxtour.ai';
const double _feetToMeters = 0.3048;

void main() {
  runApp(const SpooferApp());
}

class SpooferApp extends StatelessWidget {
  const SpooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoxTour GPS Spoofer',
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const SpooferScreen(),
    );
  }
}

class SpooferScreen extends StatefulWidget {
  const SpooferScreen({super.key});

  @override
  State<SpooferScreen> createState() => _SpooferScreenState();
}

class _SpooferScreenState extends State<SpooferScreen> with TickerProviderStateMixin {
  final TextEditingController _apiBaseController = TextEditingController(text: _defaultApiBase);
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _tourIdController = TextEditingController();

  final MethodChannel _mockChannel = const MethodChannel('voxtourai_gps_spoofer/mock_location');

  GoogleMapController? _mapController;
  bool _pendingFitRoute = false;

  List<LatLng> _routePoints = [];
  List<double> _cumulativeMeters = [];
  double _totalDistanceMeters = 0;
  double _progress = 0;
  double _speedFtPerSec = 4;

  LatLng? _currentPosition;
  Set<Polyline> _polylines = const {};
  Set<Marker> _markers = const {};

  bool _isLoading = false;
  bool _isPlaying = false;
  Ticker? _ticker;
  Duration? _lastTick;

  @override
  void dispose() {
    _ticker?.dispose();
    _apiBaseController.dispose();
    _apiKeyController.dispose();
    _tourIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VoxTour GPS Spoofer'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(0, 0),
                zoom: _currentPosition == null ? 2 : 16,
              ),
              onMapCreated: _onMapCreated,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildControls(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final bool hasRoute = _routePoints.length >= 2;
    final progressLabel = '${(_progress * 100).toStringAsFixed(0)}%';
    final distanceLabel = _totalDistanceMeters > 0
        ? '${_formatDistance(_progress * _totalDistanceMeters)} / ${_formatDistance(_totalDistanceMeters)}'
        : '0 m';

    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tourIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tour ID',
                      hintText: 'Journey/tour UUID',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _loadRoute,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Partner API key',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiBaseController,
              decoration: const InputDecoration(
                labelText: 'API Base',
                hintText: 'https://api-stage.voxtour.ai',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: hasRoute ? _togglePlayback : null,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Slider(
                    value: _clamp01(_progress),
                    min: 0,
                    max: 1,
                    onChanged: hasRoute
                        ? (value) {
                            _lastTick = null;
                            _setProgress(value);
                          }
                        : null,
                  ),
                ),
                Text(progressLabel),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
              child: Text(distanceLabel, textAlign: TextAlign.right),
            ),
            Row(
              children: [
                const Icon(Icons.speed),
                Expanded(
                  child: Slider(
                    value: _speedFtPerSec,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        _speedFtPerSec = value;
                      });
                    },
                  ),
                ),
                Text('${_speedFtPerSec.toStringAsFixed(1)} ft/s'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Enable Developer Options and set this app as the mock location provider.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pendingFitRoute) {
      _fitRouteToMap();
    }
  }

  Future<void> _loadRoute() async {
    final tourId = _tourIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final apiBase = _normalizeApiBase(_apiBaseController.text.trim());

    if (tourId.isEmpty || apiKey.isEmpty || apiBase.isEmpty) {
      _showSnack('Enter tour ID, API key, and API base.');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _stopPlayback();

    try {
      final response = await http.post(
        Uri.parse('$apiBase/v1/getTour'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'tourId': tourId, 'apiKey': apiKey}),
      );

      if (response.statusCode != 200) {
        _showSnack('Request failed (${response.statusCode}).');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final polyline = data['routePolyline'] as String? ?? '';
      if (polyline.isEmpty) {
        _showSnack('No routePolyline found for this tour.');
        return;
      }

      final points = _decodePolyline(polyline);
      if (points.length < 2) {
        _showSnack('Failed to decode route polyline.');
        return;
      }

      _setRoute(points);
      _fitRouteToMap();
    } catch (error) {
      _showSnack('Failed to load route: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setRoute(List<LatLng> points) {
    _routePoints = points;
    _cumulativeMeters = _buildCumulativeMeters(points);
    _totalDistanceMeters = _cumulativeMeters.isEmpty ? 0 : _cumulativeMeters.last;
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blueAccent,
        width: 4,
        points: points,
      ),
    };
    _setProgress(0);
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_routePoints.length < 2 || _totalDistanceMeters == 0) {
      return;
    }
    setState(() {
      _isPlaying = true;
    });
    _lastTick = null;
    _ticker ??= createTicker(_onTick);
    _ticker!.start();
  }

  void _stopPlayback() {
    if (!_isPlaying) {
      return;
    }
    _ticker?.stop();
    _lastTick = null;
    setState(() {
      _isPlaying = false;
    });
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _routePoints.length < 2) {
      return;
    }

    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }

    final deltaSeconds = (elapsed - _lastTick!).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    final speedMps = _speedFtPerSec * _feetToMeters;
    final currentDistance = _progress * _totalDistanceMeters;
    final nextDistance = currentDistance + speedMps * deltaSeconds;

    if (nextDistance >= _totalDistanceMeters) {
      _setProgress(1);
      _stopPlayback();
      return;
    }

    _setProgress(nextDistance / _totalDistanceMeters);
  }

  void _setProgress(double value) {
    if (_routePoints.isEmpty) {
      return;
    }

    final clamped = _clamp01(value);
    final distance = _totalDistanceMeters * clamped;
    final position = _totalDistanceMeters == 0 ? _routePoints.first : _positionAtDistance(distance);

    setState(() {
      _progress = clamped;
      _currentPosition = position;
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: position,
        ),
      };
    });

    unawaited(_sendMockLocation(position));
    _followCamera(position);
  }

  void _followCamera(LatLng position) {
    if (_mapController == null) {
      return;
    }
    _mapController!.moveCamera(CameraUpdate.newLatLng(position));
  }

  void _fitRouteToMap() {
    if (_mapController == null) {
      _pendingFitRoute = true;
      return;
    }
    if (_routePoints.isEmpty) {
      return;
    }
    _pendingFitRoute = false;

    if (_routePoints.length == 1) {
      _mapController!.moveCamera(CameraUpdate.newLatLngZoom(_routePoints.first, 16));
      return;
    }

    final bounds = _boundsFromLatLngs(_routePoints);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  Future<void> _sendMockLocation(LatLng position) async {
    final speedMps = _speedFtPerSec * _feetToMeters;
    await _mockChannel.invokeMethod('setMockLocation', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': 3.0,
      'speedMps': speedMps,
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = PolylinePoints().decodePolyline(encoded);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
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

  LatLng _positionAtDistance(double meters) {
    if (meters <= 0) {
      return _routePoints.first;
    }
    if (meters >= _totalDistanceMeters) {
      return _routePoints.last;
    }

    final index = _upperBound(_cumulativeMeters, meters);
    final startIndex = math.max(0, index - 1);
    final endIndex = math.min(_routePoints.length - 1, index);

    final startDistance = _cumulativeMeters[startIndex];
    final endDistance = _cumulativeMeters[endIndex];
    final segmentLength = endDistance - startDistance;

    if (segmentLength <= 0) {
      return _routePoints[startIndex];
    }

    final t = (meters - startDistance) / segmentLength;
    return _interpolate(_routePoints[startIndex], _routePoints[endIndex], t);
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

  LatLngBounds _boundsFromLatLngs(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  String _normalizeApiBase(String base) {
    if (base.endsWith('/')) {
      return base.substring(0, base.length - 1);
    }
    return base;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
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

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
