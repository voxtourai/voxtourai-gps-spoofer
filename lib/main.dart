import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

const double _feetToMeters = 0.3048;
const String _samplePolyline =
    'kenpGym~}@IsJo@Cm@Qm@_@e@i@Wa@EMYV?BWyC?EzFmA@?^u@nAcEpA_FD?CAAKDSF?^gBD@DU@?@I@?D[NHB@`@cB@?y@m@m@e@AQCC@??Pj@b@DDd@uBDAHFFEDF?DTRJFz@gD@?QIJoB@?yBe@vBd@@?HcB@?zBXFAB@@c@?e@RuCD??[@?VD@@YGDq@?IB?HK@?AOPqA@?b@gC@?Xo@@?X}@@?z@uC@?nFfBlARBBVgC^iCB?o@hEa@pE?DgAdK_A|G?BgA_@MxA?BA?';

void main() {
  runApp(const SpooferApp());
}

class SpooferApp extends StatelessWidget {
  const SpooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Spoofer',
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
  final TextEditingController _routeController = TextEditingController(text: _samplePolyline);

  final MethodChannel _mockChannel = const MethodChannel('voxtourai_gps_spoofer/mock_location');

  GoogleMapController? _mapController;
  bool _pendingFitRoute = false;
  bool _autoFollow = true;

  List<LatLng> _routePoints = [];
  List<double> _cumulativeMeters = [];
  double _totalDistanceMeters = 0;
  double _progress = 0;
  double _speedFtPerSec = 4;

  LatLng? _currentPosition;
  Set<Polyline> _polylines = const {};
  Set<Marker> _markers = const {};

  bool _isPlaying = false;
  Ticker? _ticker;
  Duration? _lastTick;
  String? _mockError;
  DateTime? _lastMockErrorAt;
  bool? _hasLocationPermission;
  bool? _isDeveloperModeEnabled;
  bool? _isMockLocationApp;
  bool _startupChecksRunning = false;
  Map<String, Object?>? _lastMockStatus;
  String? _selectedMockApp;
  LatLng? _lastInjectedPosition;
  bool _showMockMarker = false;
  bool _showSetupBar = false;
  bool _showDebugPanel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runStartupChecks(showDialogs: true));
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Spoofer'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                GoogleMap(
                  key: ValueKey('map-${_hasLocationPermission == true ? 'loc-on' : 'loc-off'}'),
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(0, 0),
                    zoom: _currentPosition == null ? 2 : 16,
                  ),
                  onMapCreated: _onMapCreated,
                  onCameraMoveStarted: () {
                    if (_autoFollow) {
                      setState(() {
                        _autoFollow = false;
                      });
                    }
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: _hasLocationPermission == true,
                  myLocationButtonEnabled: _hasLocationPermission == true,
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    onPressed: _currentPosition == null
                        ? null
                        : () {
                            setState(() {
                              _autoFollow = true;
                            });
                            _followCamera(_currentPosition!);
                          },
                    tooltip: 'Recenter',
                    child: Icon(_autoFollow ? Icons.my_location : Icons.center_focus_strong),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: SafeArea(
              top: false,
              child: _buildControls(context),
            ),
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
            TextFormField(
              controller: _routeController,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Route input',
                hintText: 'Paste encoded polyline or Routes API JSON',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _routeController.text.trim().isEmpty ? null : _loadRouteFromInput,
                    child: const Text('Load route'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _routeController.text.isEmpty
                      ? null
                      : () {
                          _routeController.clear();
                          setState(() {});
                        },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Accepts encoded polyline or Google Routes API JSON (routes[0].polyline.encodedPolyline).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_showSetupBar)
              OutlinedButton.icon(
                onPressed: () => _runStartupChecks(showDialogs: true),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  'Setup: '
                  'location ${_statusLabel(_hasLocationPermission)} · '
                  'dev ${_statusLabel(_isDeveloperModeEnabled)} · '
                  'mock ${_statusLabel(_isMockLocationApp)}',
                ),
              ),
            const SizedBox(height: 8),
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
                    max: 200,
                    divisions: 199,
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
            if (_mockError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _mockError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 8),
            if (_showDebugPanel) _buildDebugPanel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPanel(BuildContext context) {
    final status = _lastMockStatus;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Debug', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Injected: ${_lastInjectedPosition == null ? '—' : '${_lastInjectedPosition!.latitude.toStringAsFixed(6)}, ${_lastInjectedPosition!.longitude.toStringAsFixed(6)}'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Mock app selected: ${_isMockLocationApp == null ? '—' : _isMockLocationApp == true ? 'YES' : 'NO'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Selected package: ${_selectedMockApp ?? '—'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'GPS applied: ${status?['gpsApplied'] ?? '—'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Fused applied: ${status?['fusedApplied'] ?? '—'}',
            style: theme.textTheme.bodySmall,
          ),
          if (status?['gpsError'] != null)
            Text(
              'GPS error: ${status?['gpsError']}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          if (status?['addProviderError'] != null || status?['addProviderResult'] != null)
            Text(
              'addTestProvider: ${status?['addProviderResult'] ?? '—'} ${status?['addProviderError'] ?? ''}'.trim(),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          if (status?['enableProviderError'] != null || status?['enableProviderResult'] != null)
            Text(
              'setTestProviderEnabled: ${status?['enableProviderResult'] ?? '—'} ${status?['enableProviderError'] ?? ''}'.trim(),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          if (status?['statusProviderError'] != null || status?['statusProviderResult'] != null)
            Text(
              'setTestProviderStatus: ${status?['statusProviderResult'] ?? '—'} ${status?['statusProviderError'] ?? ''}'
                  .trim(),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          if (status?['removeProviderError'] != null || status?['removeProviderResult'] != null)
            Text(
              'removeTestProvider: ${status?['removeProviderResult'] ?? '—'} ${status?['removeProviderError'] ?? ''}'
                  .trim(),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          if (status?['fusedError'] != null)
            Text(
              'Fused error: ${status?['fusedError']}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _refreshMockAppStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh mock status'),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pendingFitRoute) {
      _fitRouteToMap();
    }
  }

  Future<void> _loadRouteFromInput() async {
    final input = _routeController.text.trim();
    if (input.isEmpty) {
      _showSnack('Paste an encoded polyline or Routes API JSON.');
      return;
    }

    _stopPlayback();

    final polyline = _extractPolylineFromInput(input);
    if (polyline == null || polyline.isEmpty) {
      _showSnack('No encoded polyline found in input.');
      return;
    }

    try {
      final points = _decodePolyline(polyline);
      if (points.length < 2) {
        _showSnack('Failed to decode polyline.');
        return;
      }
      _setRoute(points);
      _fitRouteToMap();
    } catch (error) {
      _showSnack('Failed to load route: $error');
    }
  }

  String? _extractPolylineFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final unquoted = _stripSurroundingQuotes(trimmed);
    if (unquoted.startsWith('{') || unquoted.startsWith('[')) {
      try {
        final data = jsonDecode(unquoted);
        final extracted = _extractPolylineFromJson(data);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      } catch (_) {
        // Fall back to regex or raw input.
      }
      final match = RegExp(r'encodedPolyline\"?\s*:\s*\"([^\"]+)\"').firstMatch(unquoted);
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
    final direct = map['encodedPolyline'] ?? map['routePolyline'] ?? map['polyline'];
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
      _lastInjectedPosition = position;
      _markers = _showMockMarker
          ? {
              Marker(
                markerId: const MarkerId('current'),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: const InfoWindow(title: 'Mocked GPS'),
                zIndex: 1,
              ),
            }
          : const {};
    });

    unawaited(_sendMockLocation(position));
    _followCamera(position);
  }

  void _followCamera(LatLng position) {
    if (_mapController == null || !_autoFollow) {
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
    try {
      final result = await _mockChannel.invokeMethod<Map<Object?, Object?>>('setMockLocation', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': 3.0,
        'speedMps': speedMps,
      });
      if (mounted) {
        setState(() {
          _lastMockStatus = result?.map((key, value) => MapEntry(key.toString(), value));
        });
      }
      final gpsApplied = result?['gpsApplied'] == true;
      final mockAppSelected = result?['mockAppSelected'] == true;
      final gpsError = result?['gpsError']?.toString();
      final fusedError = result?['fusedError']?.toString();

      if (!gpsApplied) {
        final details = gpsError ?? fusedError ?? 'GPS mock not applied';
        final hint = mockAppSelected ? 'Mock app set, but GPS mock failed.' : 'Select this app as mock location.';
        final message = 'Mock GPS not applied: $details. $hint';
        if (mounted) {
          setState(() {
            _mockError = message;
          });
        }
      } else if (_mockError != null && mounted) {
        setState(() {
          _mockError = null;
        });
      }
    } on PlatformException catch (error) {
      final now = DateTime.now();
      if (_lastMockErrorAt == null || now.difference(_lastMockErrorAt!) > const Duration(seconds: 5)) {
        _lastMockErrorAt = now;
        if (mounted) {
          setState(() {
            _mockError = 'Mock location failed: ${error.message ?? error.code}';
          });
        }
      }
    }
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

  String _statusLabel(bool? value) {
    if (value == null) {
      return '…';
    }
    return value ? 'OK' : 'NO';
  }

  Future<void> _runStartupChecks({required bool showDialogs}) async {
    if (_startupChecksRunning) {
      return;
    }
    _startupChecksRunning = true;
    try {
      final locationGranted = await _requestLocationPermission(showDialogs: showDialogs);
      if (!locationGranted) {
        return;
      }

      final devEnabled = await _isDeveloperModeEnabledNative();
      setState(() {
        _isDeveloperModeEnabled = devEnabled;
      });
      if (!devEnabled) {
        if (showDialogs) {
          final open = await _confirmDialog(
            'Enable Developer Options',
            'Developer options must be enabled to select a mock location app.',
            'Open Developer Options',
          );
          if (open) {
            await _openDeveloperSettings();
          }
        }
        return;
      }

      final isMockApp = await _isMockLocationAppNative();
      setState(() {
        _isMockLocationApp = isMockApp;
      });
      if (!isMockApp && showDialogs) {
        final open = await _confirmDialog(
          'Select Mock Location App',
          'Choose this app as the mock location provider.',
          'Open Developer Options',
        );
        if (open) {
          await _openDeveloperSettings();
        }
      }
    } finally {
      _startupChecksRunning = false;
    }
  }

  Future<bool> _requestLocationPermission({required bool showDialogs}) async {
    final status = await Permission.locationWhenInUse.request();
    final granted = status.isGranted;
    setState(() {
      _hasLocationPermission = granted;
    });
    if (granted) {
      return true;
    }

    if (!showDialogs) {
      return false;
    }

    final open = await _confirmDialog(
      'Location Permission Required',
      'Grant location permission so the mock GPS updates can be applied.',
      'Open App Settings',
    );
    if (open) {
      await openAppSettings();
    }
    return false;
  }

  Future<bool> _isDeveloperModeEnabledNative() async {
    try {
      final enabled = await _mockChannel.invokeMethod<bool>('isDeveloperModeEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isMockLocationAppNative() async {
    try {
      final enabled = await _mockChannel.invokeMethod<bool>('isMockLocationApp');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshMockAppStatus() async {
    try {
      final selected = await _mockChannel.invokeMethod<String>('getMockLocationApp');
      final isSelected = await _isMockLocationAppNative();
      if (mounted) {
        setState(() {
          _selectedMockApp = selected;
          _isMockLocationApp = isSelected;
        });
      }
    } catch (_) {
      // Ignore refresh failures.
    }
  }

  Future<void> _openSettingsSheet() async {
    if (!mounted) {
      return;
    }
    var showSetupBar = _showSetupBar;
    var showDebugPanel = _showDebugPanel;
    var showMockMarker = _showMockMarker;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Show setup bar'),
                    value: showSetupBar,
                    onChanged: (value) {
                      setModalState(() {
                        showSetupBar = value;
                      });
                      setState(() {
                        _showSetupBar = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Show debug panel'),
                    value: showDebugPanel,
                    onChanged: (value) {
                      setModalState(() {
                        showDebugPanel = value;
                      });
                      setState(() {
                        _showDebugPanel = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Show mocked marker'),
                    value: showMockMarker,
                    onChanged: (value) {
                      setModalState(() {
                        showMockMarker = value;
                      });
                      setState(() {
                        _showMockMarker = value;
                        if (!_showMockMarker) {
                          _markers = const {};
                        } else if (_currentPosition != null) {
                          _markers = {
                            Marker(
                              markerId: const MarkerId('current'),
                              position: _currentPosition!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                              infoWindow: const InfoWindow(title: 'Mocked GPS'),
                              zIndex: 1,
                            ),
                          };
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _runStartupChecks(showDialogs: true);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Run setup checks'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _refreshMockAppStatus();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh mock status'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDeveloperSettings() async {
    try {
      await _mockChannel.invokeMethod('openDeveloperSettings');
    } on PlatformException catch (error) {
      _showSnack('Failed to open developer settings: ${error.message ?? error.code}');
    }
  }

  Future<bool> _confirmDialog(String title, String message, String actionLabel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
