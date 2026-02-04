import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as scheduler;
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as flutter_local_notifications;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _tosAcceptedKey = 'tos_accepted_v1';
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

class _SpooferScreenState extends State<SpooferScreen> with WidgetsBindingObserver {
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
  Timer? _playbackTimer;
  DateTime? _lastTickAt;
  bool _resumeAfterPause = false;
  String? _mockError;
  DateTime? _lastMockErrorAt;
  bool? _hasLocationPermission;
  bool? _isDeveloperModeEnabled;
  bool? _isMockLocationApp;
  bool _startupChecksRunning = false;
  Map<String, Object?>? _lastMockStatus;
  String? _selectedMockApp;
  LatLng? _lastInjectedPosition;
  List<LatLng> _customPoints = [];
  List<String> _customNames = [];
  Set<Marker> _customMarkers = const {};
  bool _usingCustomRoute = false;
  bool _showMockMarker = false;
  bool _showSetupBar = false;
  bool _showDebugPanel = false;
  bool _backgroundEnabled = false;
  bool _backgroundBusy = false;
  bool _backgroundNotificationShown = false;
  final flutter_local_notifications.FlutterLocalNotificationsPlugin _notifications =
      flutter_local_notifications.FlutterLocalNotificationsPlugin();
  static const int _backgroundNotificationId = 1001;
  bool _tosAccepted = false;
  int? _selectedCustomIndex;
  DarkModeSetting _darkModeSetting = DarkModeSetting.on;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accepted = await _ensureTosAccepted();
      if (accepted) {
        unawaited(_runStartupChecks(showDialogs: true));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackTimer?.cancel();
    unawaited(_cancelBackgroundNotification());
    _routeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_backgroundEnabled) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        unawaited(_showBackgroundNotification());
      } else if (state == AppLifecycleState.resumed) {
        unawaited(_cancelBackgroundNotification());
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (_resumeAfterPause) {
        _resumeAfterPause = false;
        _startPlayback();
      }
    } else {
      if (_isPlaying) {
        _resumeAfterPause = true;
        _stopPlayback();
      }
    }
  }

  Future<void> _initNotifications() async {
    final androidSettings =
        flutter_local_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = flutter_local_notifications.InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  Future<void> _showBackgroundNotification() async {
    if (_backgroundNotificationShown) {
      return;
    }
    final androidDetails = flutter_local_notifications.AndroidNotificationDetails(
      'background_mode',
      'Background mode',
      channelDescription: 'Indicates mock GPS can run in the background.',
      importance: flutter_local_notifications.Importance.low,
      priority: flutter_local_notifications.Priority.low,
      ongoing: true,
      showWhen: false,
    );
    final details = flutter_local_notifications.NotificationDetails(android: androidDetails);
    await _notifications.show(
      _backgroundNotificationId,
      'Background mode active',
      'Mock GPS can keep running in the background.',
      details,
    );
    _backgroundNotificationShown = true;
  }

  Future<void> _cancelBackgroundNotification() async {
    if (!_backgroundNotificationShown) {
      return;
    }
    await _notifications.cancel(_backgroundNotificationId);
    _backgroundNotificationShown = false;
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
                    onTap: (position) {
                      if (_selectedCustomIndex != null) {
                        setState(() {
                          _selectedCustomIndex = null;
                        });
                        return;
                      }
                      if (_routePoints.isNotEmpty || _customPoints.isNotEmpty) {
                        return;
                      }
                      _setManualLocation(position);
                    },
                    onLongPress: (position) {
                      if (_routePoints.isNotEmpty && !_usingCustomRoute) {
                        _showSnack('Clear the loaded route to add points.');
                        return;
                      }
                      _addCustomPoint(position);
                    },
                    markers: _markers,
                    polylines: _polylines,
                    mapToolbarEnabled: false,
                    padding: EdgeInsets.only(
                      bottom: _selectedCustomIndex != null ? 96 : 56,
                      right: 56,
                      left: 12,
                    ),
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
                      if (_usingCustomRoute && _customPoints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'waypoints',
                          onPressed: _openWaypointList,
                          tooltip: 'Waypoints',
                          child: const Icon(Icons.list_alt),
                        ),
                      ],
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
                if (_selectedCustomIndex != null)
                  Positioned(
                    left: 12,
                    right: 72,
                    bottom: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              final idx = _selectedCustomIndex;
                              if (idx != null) {
                                _renameCustomPoint(idx);
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Rename'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              final idx = _selectedCustomIndex;
                              if (idx != null) {
                                _removeCustomPoint(idx);
                              }
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
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
                            _lastTickAt = DateTime.now();
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

  Future<void> _clearMockLocation() async {
    try {
      final result = await _mockChannel.invokeMethod<Map<Object?, Object?>>("clearMockLocation");
      if (mounted) {
        setState(() {
          _lastMockStatus = result?.map((key, value) => MapEntry(key.toString(), value));
          _mockError = null;
        });
      }
    } on PlatformException catch (error) {
      _showSnack('Failed to clear mock location: ${error.message ?? error.code}');
    }
  }

  Future<LatLng?> _getLocationFromChannel(String method) async {
    try {
      final result = await _mockChannel.invokeMethod<Map<Object?, Object?>>(method);
      if (result == null) {
        return null;
      }
      final lat = result['latitude'];
      final lng = result['longitude'];
      if (lat is num && lng is num) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    } on PlatformException {
      // Ignore failures; caller can decide what to show.
    }
    return null;
  }

  Future<LatLng?> _getRealLocation() async {
    final current = await _getLocationFromChannel('getCurrentLocation');
    if (current != null) {
      return current;
    }
    return _getLocationFromChannel('getLastKnownLocation');
  }

  void _clearRoute() {
    _stopPlayback();
    setState(() {
      _routePoints = [];
      _cumulativeMeters = [];
      _totalDistanceMeters = 0;
      _progress = 0;
      _polylines = const {};
      _customPoints = [];
      _customMarkers = const {};
      _customNames = [];
      _usingCustomRoute = false;
      _markers = const {};
      _selectedCustomIndex = null;
      _currentPosition = null;
      _lastInjectedPosition = null;
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

  static const FlutterBackgroundAndroidConfig _backgroundConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: 'GPS Spoofer',
    notificationText: 'Mock location running in background',
    notificationImportance: AndroidNotificationImportance.normal,
    notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
  );

  Future<bool> _setBackgroundMode(bool enabled) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      _showSnack('Background mode is only supported on Android.');
      return false;
    }

    setState(() {
      _backgroundBusy = true;
    });

    try {
      if (enabled) {
        final notificationStatus = await Permission.notification.request();
        if (!notificationStatus.isGranted) {
          _showSnack('Notification permission is required for background mode.');
          return false;
        }

        final initialized = await FlutterBackground.initialize(androidConfig: _backgroundConfig);
        if (!initialized) {
          _showSnack('Please disable battery optimizations to enable background mode.');
          return false;
        }
        final hasPermissions = await FlutterBackground.hasPermissions;
        if (!hasPermissions) {
          _showSnack('Background permissions not granted. Disable battery optimizations and retry.');
          return false;
        }
        final success = await FlutterBackground.enableBackgroundExecution();
        if (!success) {
          _showSnack('Failed to enable background mode.');
          return false;
        }
        setState(() {
          _backgroundEnabled = true;
        });
        _showSnack('Background mode enabled. Keep playback running to spoof.');
        return true;
      } else {
        await FlutterBackground.disableBackgroundExecution();
        setState(() {
          _backgroundEnabled = false;
        });
        unawaited(_cancelBackgroundNotification());
        return true;
      }
    } catch (error) {
      _showSnack('Background mode error: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _backgroundBusy = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _lastMapStyleDark = null;
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
        return scheduler.SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
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
      _customPoints = [];
      _customMarkers = const {};
      _customNames = [];
      _usingCustomRoute = false;
      _selectedCustomIndex = null;
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
    _lastTickAt = DateTime.now();
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (_) => _onTick());
  }

  void _stopPlayback() {
    if (!_isPlaying) {
      return;
    }
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _lastTickAt = null;
    setState(() {
      _isPlaying = false;
    });
  }

  void _onTick() {
    if (!_isPlaying || _routePoints.length < 2) {
      return;
    }

    final now = DateTime.now();
    if (_lastTickAt == null) {
      _lastTickAt = now;
      return;
    }

    final deltaSeconds = now.difference(_lastTickAt!).inMicroseconds / 1000000.0;
    _lastTickAt = now;

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
      _refreshMarkers();
    });

    unawaited(_sendMockLocation(position));
    _followCamera(position);
  }

  void _setManualLocation(LatLng position) {
    if (_routePoints.isNotEmpty) {
      return;
    }
    _stopPlayback();
    setState(() {
      _currentPosition = position;
      _lastInjectedPosition = position;
      _autoFollow = true;
      _refreshMarkers();
    });
    unawaited(_sendMockLocation(position));
    _followCamera(position);
  }

  void _refreshMarkers() {
    final markers = <Marker>{};
    if (_showMockMarker && _currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Mocked GPS'),
          zIndex: 1,
        ),
      );
    }
    markers.addAll(_customMarkers);
    _markers = markers;
  }

  void _rebuildCustomMarkers() {
    if (_customPoints.isEmpty) {
      _customMarkers = const {};
      return;
    }
    _customMarkers = {
      for (var i = 0; i < _customPoints.length; i++)
        Marker(
          markerId: MarkerId('wp_$i'),
          position: _customPoints[i],
          draggable: true,
          onDragEnd: (pos) {
            _customPoints[i] = pos;
            _stopPlayback();
            _rebuildCustomRoute();
            _selectCustomPoint(i);
          },
          onTap: () {
            _selectCustomPoint(i);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == _selectedCustomIndex ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: _customNames.length > i ? _customNames[i] : _defaultWaypointName(i),
            snippet: 'Hold and drag to move',
          ),
          zIndex: 2,
        ),
    };
  }

  void _rebuildCustomRoute() {
    _rebuildCustomMarkers();
    if (_customPoints.isEmpty) {
      if (mounted) {
        setState(() {
          _routePoints = [];
          _cumulativeMeters = [];
          _totalDistanceMeters = 0;
          _progress = 0;
          _polylines = const {};
          _currentPosition = null;
          _lastInjectedPosition = null;
          _refreshMarkers();
        });
      } else {
        _routePoints = [];
        _cumulativeMeters = [];
        _totalDistanceMeters = 0;
        _progress = 0;
        _polylines = const {};
        _currentPosition = null;
        _lastInjectedPosition = null;
        _refreshMarkers();
      }
      return;
    }

    _routePoints = List<LatLng>.from(_customPoints);
    _cumulativeMeters = _buildCumulativeMeters(_routePoints);
    _totalDistanceMeters = _cumulativeMeters.isEmpty ? 0 : _cumulativeMeters.last;
    _polylines = _routePoints.length >= 2
        ? {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blueAccent,
              width: 4,
              points: _routePoints,
            ),
          }
        : const {};
    _progress = 0;
    _setProgress(0);
  }

  void _addCustomPoint(LatLng position) {
    if (_routePoints.isNotEmpty && !_usingCustomRoute) {
      _showSnack('Clear the loaded route to edit a custom route.');
      return;
    }
    _usingCustomRoute = true;
    _stopPlayback();
    _customNames.add(_defaultWaypointName(_customPoints.length));
    _customPoints.add(position);
    _rebuildCustomRoute();
    _followCamera(position);
  }

  void _removeCustomPoint(int index) {
    if (index < 0 || index >= _customPoints.length) {
      return;
    }
    _stopPlayback();
    _customNames.removeAt(index);
    _customPoints.removeAt(index);
    if (_customPoints.isEmpty) {
      _usingCustomRoute = false;
      _customNames = [];
    }
    if (_selectedCustomIndex == index) {
      _selectedCustomIndex = null;
    }
    _normalizeWaypointNames();
    _rebuildCustomRoute();
  }

  void _selectCustomPoint(int index) {
    setState(() {
      _selectedCustomIndex = index;
      _rebuildCustomMarkers();
      _refreshMarkers();
    });
  }

  void _reorderCustomPoints(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _customPoints.length) {
      return;
    }
    if (newIndex < 0 || newIndex > _customPoints.length) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex == oldIndex) {
      return;
    }
    _stopPlayback();
    final point = _customPoints.removeAt(oldIndex);
    final name = _customNames.removeAt(oldIndex);
    _customPoints.insert(newIndex, point);
    _customNames.insert(newIndex, name);

    if (_selectedCustomIndex != null) {
      final selected = _selectedCustomIndex!;
      if (selected == oldIndex) {
        _selectedCustomIndex = newIndex;
      } else if (oldIndex < selected && newIndex >= selected) {
        _selectedCustomIndex = selected - 1;
      } else if (oldIndex > selected && newIndex <= selected) {
        _selectedCustomIndex = selected + 1;
      }
    }
    _normalizeWaypointNames();
    _rebuildCustomRoute();
  }

  String _defaultWaypointName(int index) => 'Waypoint ${index + 1}';

  void _normalizeWaypointNames() {
    for (var i = 0; i < _customNames.length; i++) {
      if (RegExp(r'^Waypoint\\s+\\d+$').hasMatch(_customNames[i])) {
        _customNames[i] = _defaultWaypointName(i);
      }
    }
  }

  Future<void> _renameCustomPoint(int index) async {
    if (index < 0 || index >= _customPoints.length) {
      return;
    }
    final controller = TextEditingController(text: _customNames[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename waypoint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Waypoint name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    final name = result.isEmpty ? _defaultWaypointName(index) : result;
    setState(() {
      _customNames[index] = name;
      _rebuildCustomMarkers();
      _refreshMarkers();
    });
  }

  Future<void> _openWaypointList() async {
    if (_customPoints.isEmpty) {
      _showSnack('No waypoints to edit.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.6;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Text('Waypoints', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: _customPoints.length,
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      _reorderCustomPoints(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final name = _customNames.length > index
                          ? _customNames[index]
                          : _defaultWaypointName(index);
                      final position = _customPoints[index];
                      return ListTile(
                        key: ValueKey('wp_item_$index'),
                        dense: true,
                        title: Text(name),
                        subtitle: Text(
                          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                        ),
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text('${index + 1}', style: Theme.of(context).textTheme.labelSmall),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _selectCustomPoint(index);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Rename',
                              onPressed: () => _renameCustomPoint(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () => _removeCustomPoint(index),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<bool> _ensureTosAccepted() async {
    if (_tosAccepted) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_tosAcceptedKey) ?? false;
    if (accepted) {
      _tosAccepted = true;
      return true;
    }

    if (!mounted) {
      return false;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Terms of Use'),
          content: const SingleChildScrollView(
            child: Text(
              'This tool is for testing and development only. You are responsible for using it legally and with permission. Location accuracy is not guaranteed, and you assume all risks from use.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                await prefs.setBool(_tosAcceptedKey, true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('I agree'),
            ),
          ],
        ),
      ),
    );

    _tosAccepted = prefs.getBool(_tosAcceptedKey) ?? false;
    return _tosAccepted;
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
    var backgroundEnabled = _backgroundEnabled;
    var backgroundBusy = _backgroundBusy;
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
                              _refreshMarkers();
                            });
                          },
                        ),
                        ListTile(
                          dense: true,
                          visualDensity: compactDensity,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Background mode', style: denseStyle),
                          trailing: Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: backgroundEnabled,
                              onChanged: backgroundBusy
                              ? null
                              : (value) async {
                                setModalState(() {
                                  backgroundEnabled = value;
                                  backgroundBusy = true;
                                });
                                final ok = await _setBackgroundMode(value);
                                setModalState(() {
                                  backgroundBusy = false;
                                  backgroundEnabled = _backgroundEnabled;
                                });
                                if (!ok) {
                                  // snack handled in _setBackgroundMode
                                }
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          onTap: backgroundBusy
                          ? null
                          : () async {
                            final next = !backgroundEnabled;
                            setModalState(() {
                              backgroundEnabled = next;
                              backgroundBusy = true;
                            });
                            final ok = await _setBackgroundMode(next);
                            setModalState(() {
                              backgroundBusy = false;
                              backgroundEnabled = _backgroundEnabled;
                            });
                            if (!ok) {
                              // snack handled in _setBackgroundMode
                            }
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
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: compactDensity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                          onPressed: () async {
                            await _clearMockLocation();
                            await Future.delayed(const Duration(milliseconds: 400));
                            var location = await _getRealLocation();
                            if (location == null) {
                              await Future.delayed(const Duration(milliseconds: 600));
                              location = await _getRealLocation();
                            }
                            if (location == null) {
                              _showSnack('Real location not available yet.');
                              return;
                            }
                            setState(() {
                              _currentPosition = location;
                              _lastInjectedPosition = null;
                              _refreshMarkers();
                              _autoFollow = true;
                            });
                            _followCamera(location);
                          },
                          icon: const Icon(Icons.location_off),
                          label: const Text('Disable mock location'),
                        ),
                        const SizedBox(height: 6),
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
