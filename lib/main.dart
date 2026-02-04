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

const String _samplePolyline =
    'kenpGym~}@IsJo@Cm@Qm@_@e@i@Wa@EMYV?BWyC?EzFmA@?^u@nAcEpA_FD?CAAKDSF?^gBD@DU@?@I@?D[NHB@`@cB@?y@m@m@e@AQCC@??Pj@b@DDd@uBDAHFFEDF?DTRJFz@gD@?QIJoB@?yBe@vBd@@?HcB@?zBXFAB@@c@?e@RuCD??[@?VD@@YGDq@?IB?HK@?AOPqA@?b@gC@?Xo@@?X}@@?z@uC@?nFfBlARBBVgC^iCB?o@hEa@pE?DgAdK_A|G?BgA_@MxA?BA?';
const String _darkMapStyle = r'''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},
  {"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
  {"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);

enum DarkModeSetting {
  on,
  uiOnly,
  mapOnly,
  off,
}

void main() {
  runApp(const SpooferApp());
}

class SpooferApp extends StatelessWidget {
  const SpooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
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
          home: const SpooferScreen(),
        );
      },
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
  bool _isProgrammaticMove = false;
  bool? _lastMapStyleDark;

  List<LatLng> _routePoints = [];
  List<double> _cumulativeMeters = [];
  double _totalDistanceMeters = 0;
  double _progress = 0;
  double _speedMps = 2;

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
  DarkModeSetting _darkModeSetting = DarkModeSetting.on;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_applyMapStyle());
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = _routePoints.length >= 2;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
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
            flex: 15,
            child: Stack(
              children: [
                Listener(
                  onPointerDown: (_) {
                    if (_autoFollow) {
                      setState(() {
                        _autoFollow = false;
                      });
                    }
                  },
                  child: GoogleMap(
                    key: ValueKey('map-${_hasLocationPermission == true ? 'loc-on' : 'loc-off'}'),
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition ?? const LatLng(0, 0),
                      zoom: _currentPosition == null ? 2 : 16,
                    ),
                    onMapCreated: _onMapCreated,
                    onCameraMoveStarted: () {
                      if (_isProgrammaticMove) {
                        return;
                      }
                      if (_autoFollow) {
                        setState(() {
                          _autoFollow = false;
                        });
                      }
                    },
                    onCameraIdle: () {
                      if (_isProgrammaticMove) {
                        _isProgrammaticMove = false;
                      }
                    },
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: _hasLocationPermission == true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'load',
                        onPressed: _routePoints.isEmpty ? _openRouteInputSheet : _clearRoute,
                        tooltip: _routePoints.isEmpty ? 'Load route' : 'Clear route',
                        child: Icon(_routePoints.isEmpty ? Icons.upload : Icons.close),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'play',
                        onPressed: hasRoute ? _togglePlayback : null,
                        backgroundColor: hasRoute ? null : Theme.of(context).colorScheme.surfaceVariant,
                        foregroundColor: hasRoute ? null : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        tooltip: _isPlaying ? 'Pause' : 'Play',
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                    ],
                  ),
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
            flex: 5,
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
    final theme = Theme.of(context);
    final bool hasRoute = _routePoints.length >= 2;
    final progressLabel = '${(_progress * 100).toStringAsFixed(0)}%';
    final distanceLabel = _totalDistanceMeters > 0
        ? '${_formatDistance(_progress * _totalDistanceMeters)} / ${_formatDistance(_totalDistanceMeters)}'
        : '0 m';
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    );
    final speedSliderTheme = sliderTheme.copyWith(
      activeTrackColor: theme.colorScheme.outlineVariant,
      inactiveTrackColor: theme.colorScheme.outlineVariant,
      trackShape: const _UniformTrackShape(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
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
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      '$progressLabel · $distanceLabel',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                SliderTheme(
                  data: sliderTheme,
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
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Speed', style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      '${_speedMps.toStringAsFixed(0)} m/s',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                SliderTheme(
                  data: speedSliderTheme,
                  child: Slider(
                    value: _speedMps,
                    min: -200,
                    max: 200,
                    divisions: 200,
                    onChanged: (value) {
                      setState(() {
                        _speedMps = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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

  Future<void> _openRouteInputSheet() async {
    final controller = TextEditingController(text: _routeController.text);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            'Load route',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste encoded polyline or Routes API JSON',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _routeController.text = controller.text;
                Navigator.of(context).pop();
                _loadRouteFromInput();
              },
              child: const Text('Load'),
            ),
          ],
        );
      },
    );
  }

  void _clearRoute() {
    _stopPlayback();
    setState(() {
      _routePoints = [];
      _cumulativeMeters = [];
      _totalDistanceMeters = 0;
      _progress = 0;
      _polylines = const {};
      _markers = const {};
      _currentPosition = null;
    });
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
    unawaited(_applyMapStyle());
    if (_pendingFitRoute) {
      _fitRouteToMap();
    }
  }

  Future<void> _applyMapStyle() async {
    if (_mapController == null) {
      return;
    }
    final useDarkStyle = _shouldUseDarkMapStyle();
    if (_lastMapStyleDark == useDarkStyle) {
      return;
    }
    _lastMapStyleDark = useDarkStyle;
    await _mapController!.setMapStyle(useDarkStyle ? _darkMapStyle : null);
  }

  bool _shouldUseDarkMapStyle() {
    switch (_darkModeSetting) {
      case DarkModeSetting.on:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      case DarkModeSetting.uiOnly:
        return false;
      case DarkModeSetting.mapOnly:
        return true;
      case DarkModeSetting.off:
        return false;
    }
  }

  void _applyDarkModeSetting(DarkModeSetting setting) {
    _darkModeSetting = setting;
    switch (setting) {
      case DarkModeSetting.on:
        _themeMode.value = ThemeMode.system;
        break;
      case DarkModeSetting.uiOnly:
        _themeMode.value = ThemeMode.dark;
        break;
      case DarkModeSetting.mapOnly:
      case DarkModeSetting.off:
        _themeMode.value = ThemeMode.light;
        break;
    }
    unawaited(_applyMapStyle());
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

    final speedMps = _speedMps;
    final currentDistance = _progress * _totalDistanceMeters;
    final nextDistance = currentDistance + speedMps * deltaSeconds;

    if (nextDistance >= _totalDistanceMeters) {
      _setProgress(1);
      _stopPlayback();
      return;
    }
    if (nextDistance <= 0) {
      _setProgress(0);
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
    _isProgrammaticMove = true;
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
    final speedMps = _speedMps.abs();
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
    var darkModeSetting = _darkModeSetting;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: SafeArea(
            child: Material(
              elevation: 6,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 280,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    final denseStyle = Theme.of(context).textTheme.bodySmall;
                    const compactDensity = VisualDensity(horizontal: -2, vertical: -4);
                    Widget buildToggle({
                      required String title,
                      required bool value,
                      required ValueChanged<bool> onChanged,
                    }) {
                      return ListTile(
                        dense: true,
                        visualDensity: compactDensity,
                        contentPadding: EdgeInsets.zero,
                        title: Text(title, style: denseStyle),
                        trailing: Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: value,
                            onChanged: onChanged,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        onTap: () => onChanged(!value),
                      );
                    }

                    String darkModeLabel(DarkModeSetting setting) {
                      switch (setting) {
                        case DarkModeSetting.on:
                          return 'On';
                        case DarkModeSetting.uiOnly:
                          return 'UI only';
                        case DarkModeSetting.mapOnly:
                          return 'Map only';
                        case DarkModeSetting.off:
                          return 'Off';
                      }
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                      children: [
                        Row(
                          children: [
                            Text('Settings', style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                              splashRadius: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        buildToggle(
                          title: 'Show setup bar',
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
                        buildToggle(
                          title: 'Show debug panel',
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
                        buildToggle(
                          title: 'Show mocked marker',
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
                        ListTile(
                          dense: true,
                          visualDensity: compactDensity,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Dark mode', style: denseStyle),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<DarkModeSetting>(
                              isDense: true,
                              value: darkModeSetting,
                              items: DarkModeSetting.values
                                  .map(
                                    (setting) => DropdownMenuItem(
                                      value: setting,
                                      child: Text(darkModeLabel(setting)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setModalState(() {
                                  darkModeSetting = value;
                                });
                                setState(() {
                                  _applyDarkModeSetting(value);
                                });
                              },
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            visualDensity: compactDensity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _runStartupChecks(showDialogs: true);
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Run setup checks'),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: compactDensity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          onPressed: () {
                            _refreshMockAppStatus();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh mock status'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        );
        return SlideTransition(position: offset, child: child);
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

class _UniformTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _UniformTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final paint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? sliderTheme.activeTrackColor ?? Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = trackHeight;

    final y = trackRect.center.dy;
    context.canvas.drawLine(
      Offset(trackRect.left, y),
      Offset(trackRect.right, y),
      paint,
    );
  }
}
