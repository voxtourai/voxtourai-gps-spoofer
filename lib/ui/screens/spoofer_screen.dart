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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../controllers/mock_location_controller.dart';
import '../../controllers/map_state_controller.dart';
import '../../controllers/playback_controller.dart';
import '../../controllers/preferences_controller.dart';
import '../../controllers/route_controller.dart';
import '../../controllers/route_workflow_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/waypoint_controller.dart';
import '../../models/help_section.dart';
import '../map/map_style.dart';
import '../widgets/controls_panel.dart';
import '../widgets/map_action_buttons.dart';
import '../widgets/waypoint_action_row.dart';
import 'help_screen.dart';
import 'search_screen.dart';

const String _samplePolyline =
    'kenpGym~}@IsJo@Cm@Qm@_@e@i@Wa@EMYV?BWyC?EzFmA@?^u@nAcEpA_FD?CAAKDSF?^gBD@DU@?@I@?D[NHB@`@cB@?y@m@m@e@AQCC@??Pj@b@DDd@uBDAHFFEDF?DTRJFz@gD@?QIJoB@?yBe@vBd@@?HcB@?zBXFAB@@c@?e@RuCD??[@?VD@@YGDq@?IB?HK@?AOPqA@?b@gC@?Xo@@?X}@@?z@uC@?nFfBlARBBVgC^iCB?o@hEa@pE?DgAdK_A|G?BgA_@MxA?BA?';

class SpooferScreen extends StatefulWidget {
  const SpooferScreen({super.key, required this.mockController});

  final MockLocationController mockController;

  @override
  State<SpooferScreen> createState() => _SpooferScreenState();
}

class _SpooferScreenState extends State<SpooferScreen> with WidgetsBindingObserver {
  final TextEditingController _routeController = TextEditingController();

  GoogleMapController? _mapController;
  final MapStateController _mapState = MapStateController();
  late final RouteWorkflowController _routeState =
      RouteWorkflowController(
        mapState: _mapState,
        onRouteEdited: _stopPlayback,
        onMarkersChanged: _refreshMarkers,
      );

  RouteController get _route => _routeState.route;
  WaypointController get _waypoints => _routeState.waypoints;

  final PlaybackController _playback = PlaybackController();
  final SettingsController _settings = SettingsController();
  final PreferencesController _prefs = PreferencesController();
  String? _mockError;
  DateTime? _lastMockErrorAt;
  bool? _hasLocationPermission;
  bool? _isDeveloperModeEnabled;
  bool? _isMockLocationApp;
  bool _startupChecksRunning = false;
  Map<String, Object?>? _lastMockStatus;
  String? _selectedMockApp;
  bool _backgroundNotificationShown = false;
  final List<String> _debugLog = [];
  String? _lastDebugMessage;
  DateTime? _lastDebugAt;
  OverlayEntry? _overlayMessage;
  final flutter_local_notifications.FlutterLocalNotificationsPlugin _notifications =
      flutter_local_notifications.FlutterLocalNotificationsPlugin();
  static const int _backgroundNotificationId = 1001;
  bool _tosAccepted = false;
  PackageInfo? _packageInfo;
  bool _packageInfoLoading = false;
  int _titleTapCount = 0;
  DateTime? _lastTitleTapAt;
  final List<HelpSection> _helpSections = const [
    HelpSection(
      'Getting started',
      [
        'Enable Developer Options and set this app as the mock location app.',
        'Grant location and notification permissions when prompted.',
        'Load a route or add custom waypoints, then press Play.',
      ],
    ),
    HelpSection(
      'Loading routes',
      [
        'Tap Load to paste an encoded polyline or Google Routes API JSON.',
        'Clear removes the active route and stops playback.',
        'When a route is loaded, Progress scrubs the route manually.',
      ],
    ),
    HelpSection(
      'Custom routes and waypoints',
      [
        'Long-press the map to add waypoints when no route is loaded.',
        'Drag a waypoint marker to move it, tap to select it.',
        'Use Delete/Rename or the Waypoints list to manage points.',
        'Save or load custom routes from the Waypoints list.',
      ],
    ),
    HelpSection(
      'Playback and speed',
      [
        'Play starts auto movement along the route.',
        'Speed is in m/s; negative values move in reverse.',
        'Speed 0 pauses movement without clearing the route.',
      ],
    ),
    HelpSection(
      'Map and camera',
      [
        'Recenter follows the current mock location on the map.',
        'Drag the map to stop auto-follow.',
        'Tap the map to set a single mock location when no route is active.',
      ],
    ),
    HelpSection(
      'Background mode',
      [
        'Enable Background mode in Settings to keep spoofing when minimized.',
        'Allow notification permission and battery optimization exemptions.',
        'A persistent notification indicates background mode is active.',
      ],
    ),
    HelpSection(
      'Dark mode',
      [
        'Use Settings to choose Off, On, UI only, or Map only.',
        'Map style updates when the app theme changes.',
      ],
    ),
    HelpSection(
      'Troubleshooting',
      [
        'If mock GPS is not applied, re-check mock app selection.',
        'Ensure location permission is granted and mock status is green.',
        'If other apps do not update, reopen them or check OS location settings.',
      ],
    ),
  ];

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
    _overlayMessage?.remove();
    _overlayMessage = null;
    _playback.dispose();
    _mapState.dispose();
    _routeState.dispose();
    _settings.dispose();
    unawaited(_cancelBackgroundNotification());
    _routeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_settings.backgroundEnabled) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        unawaited(_showBackgroundNotification());
      } else if (state == AppLifecycleState.resumed) {
        unawaited(_cancelBackgroundNotification());
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (_playback.resumeAfterPause) {
        _playback.setResumeAfterPause(false);
        _startPlayback();
      }
    } else {
      if (_playback.isPlaying) {
        _playback.setResumeAfterPause(true);
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
    return AnimatedBuilder(
      animation: Listenable.merge([_routeState, _playback, _settings, _mapState]),
      builder: (context, _) {
        final hasRoute = _route.hasRoute;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final controlsVisible = _route.hasRoute;
        final double overlayBottom = 12 + (controlsVisible ? 0.0 : bottomInset);

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTitleTap,
              child: const Text('GPS Spoofer'),
            ),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search),
                onPressed: _openSearchScreen,
              ),
              IconButton(
                tooltip: 'Help',
                icon: const Icon(Icons.help_outline),
                onPressed: _openHelpScreen,
              ),
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
                        if (_mapState.autoFollow) {
                          _mapState.setAutoFollow(false);
                        }
                      },
                      child: GoogleMap(
                        key: ValueKey('map-${_hasLocationPermission == true ? 'loc-on' : 'loc-off'}'),
                        initialCameraPosition: CameraPosition(
                          target: _mapState.currentPosition ?? const LatLng(0, 0),
                          zoom: _mapState.currentPosition == null ? 2 : 16,
                        ),
                        onMapCreated: _onMapCreated,
                        onCameraMoveStarted: () {
                          if (_mapState.isProgrammaticMove) {
                            return;
                          }
                          if (_mapState.autoFollow) {
                            _mapState.setAutoFollow(false);
                          }
                        },
                        onCameraIdle: () {
                          if (_mapState.isProgrammaticMove) {
                            _mapState.setProgrammaticMove(false);
                          }
                        },
                        onTap: (position) {
                          if (_waypoints.selectedIndex != null) {
                            _routeState.selectWaypoint(null);
                            return;
                          }
                          if (_route.hasPoints || _waypoints.hasPoints) {
                            return;
                          }
                          _setManualLocation(position);
                        },
                        onLongPress: (position) {
                          if (_route.hasPoints && !_waypoints.usingCustomRoute) {
                            _showSnack('Clear the loaded route to add points.');
                            return;
                          }
                          _addCustomPoint(position);
                        },
                        markers: _mapState.markers,
                        polylines: _mapState.polylines,
                        mapToolbarEnabled: false,
                        padding: EdgeInsets.only(
                          bottom: bottomInset + 56,
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
                      child: MapActionButtons(
                        hasRoute: hasRoute,
                        hasPoints: _route.hasPoints,
                        isPlaying: _playback.isPlaying,
                        showWaypoints: !(_route.hasRoute && !_waypoints.usingCustomRoute),
                        onLoadOrClear: _route.hasPoints ? _clearRoute : _openRouteInputSheet,
                        onTogglePlayback: hasRoute ? _togglePlayback : null,
                        onOpenWaypoints: _openWaypointList,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: overlayBottom,
                      child: FloatingActionButton.small(
                        heroTag: 'recenter',
                        onPressed: _mapState.currentPosition == null
                            ? null
                            : () {
                                _mapState.setAutoFollow(true);
                                _followCamera(_mapState.currentPosition!);
                              },
                        tooltip: 'Recenter',
                        child: Icon(
                          _mapState.autoFollow ? Icons.my_location : Icons.center_focus_strong,
                        ),
                      ),
                    ),
                    if (_waypoints.selectedIndex != null)
                      Positioned(
                        left: 12,
                        right: 72,
                        bottom: overlayBottom,
                        child: WaypointActionRow(
                          onRename: () {
                            final idx = _waypoints.selectedIndex;
                            if (idx != null) {
                              _renameCustomPoint(idx);
                            }
                          },
                          onDelete: () {
                            final idx = _waypoints.selectedIndex;
                            if (idx != null) {
                              _removeCustomPoint(idx);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _route.hasRoute
                    ? SafeArea(
                        key: const ValueKey('controls'),
                        top: false,
                        child: _buildControls(context),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-controls')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    final bool hasRoute = _route.hasRoute;
    final progressLabel = '${(_route.progress * 100).toStringAsFixed(0)}%';
    final distanceLabel = _route.totalDistanceMeters > 0
        ? '${_formatDistance(_route.progressDistance)} / ${_formatDistance(_route.totalDistanceMeters)}'
        : '0 m';

    return ControlsPanel(
      showSetupBar: _settings.showSetupBar,
      setupLabel: 'Setup: '
          'location ${_statusLabel(_hasLocationPermission)} · '
          'dev ${_statusLabel(_isDeveloperModeEnabled)} · '
          'mock ${_statusLabel(_isMockLocationApp)}',
      onRunSetupChecks: () => _runStartupChecks(showDialogs: true),
      progressLabel: progressLabel,
      distanceLabel: distanceLabel,
      progress: _clamp01(_route.progress),
      onProgressChanged: hasRoute
          ? (value) {
              _playback.markTick();
              _setProgress(value);
            }
          : null,
      speedMps: _playback.speedMps,
      onSpeedChanged: (value) => _playback.speedMps = value,
      mockError: _mockError,
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
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_outline),
              onPressed: controller.clear,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                controller.text = _samplePolyline;
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                _showOverlayMessage('Filled demo route.');
              },
              child: const Text('Demo'),
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
      final result = await widget.mockController.clearMockLocation();
      if (mounted) {
        setState(() {
          _lastMockStatus = result;
          _mockError = null;
        });
      }
      _appendDebugLog('Cleared mock location.');
    } on PlatformException catch (error) {
      _showSnack('Failed to clear mock location: ${error.message ?? error.code}');
      _appendDebugLog('Clear mock failed: ${error.message ?? error.code}');
    }
  }

  Future<LatLng?> _getRealLocation() async {
    final current = await widget.mockController.getCurrentLocation();
    if (current != null) {
      return current;
    }
    return widget.mockController.getLastKnownLocation();
  }

  void _clearRoute() {
    _stopPlayback();
    _routeState.clearAll();
  }

  void _appendDebugLog(String message) {
    final now = DateTime.now();
    if (_lastDebugMessage == message &&
        _lastDebugAt != null &&
        now.difference(_lastDebugAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastDebugMessage = message;
    _lastDebugAt = now;
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final entry = '[$stamp] $message';
    if (!mounted) {
      _debugLog.add(entry);
      if (_debugLog.length > 50) {
        _debugLog.removeRange(0, _debugLog.length - 50);
      }
      return;
    }
    setState(() {
      _debugLog.add(entry);
      if (_debugLog.length > 50) {
        _debugLog.removeRange(0, _debugLog.length - 50);
      }
    });
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    if (_lastTitleTapAt == null || now.difference(_lastTitleTapAt!) > const Duration(seconds: 2)) {
      _titleTapCount = 0;
    }
    _lastTitleTapAt = now;
    _titleTapCount += 1;
    if (_titleTapCount >= 5) {
      _titleTapCount = 0;
      unawaited(_showAppInfoDialog());
    }
  }

  Future<PackageInfo?> _loadPackageInfo() async {
    if (_packageInfo != null) {
      return _packageInfo;
    }
    if (_packageInfoLoading) {
      return null;
    }
    _packageInfoLoading = true;
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = info;
        });
      } else {
        _packageInfo = info;
      }
      return info;
    } catch (_) {
      return null;
    } finally {
      _packageInfoLoading = false;
    }
  }

  Future<void> _showAppInfoDialog() async {
    final info = await _loadPackageInfo();
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('App info'),
          content: info == null
              ? const Text('Version info unavailable.')
              : DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodySmall,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Version: ${info.version}'),
                      Text('Build: ${info.buildNumber}'),
                      Text('App ID: ${info.packageName}'),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSearchScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          mockController: widget.mockController,
          onSelect: (location, zoom) {
            _setManualLocation(location, force: true, zoom: zoom);
          },
          onLog: _appendDebugLog,
        ),
      ),
    );
  }

  Widget _buildDebugPanel(BuildContext context) {
    final status = _lastMockStatus;
    final theme = Theme.of(context);
    if (!_settings.showDebugPanel) {
      return const SizedBox.shrink();
    }
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
            'Injected: ${_mapState.lastInjectedPosition == null ? '—' : '${_mapState.lastInjectedPosition!.latitude.toStringAsFixed(6)}, ${_mapState.lastInjectedPosition!.longitude.toStringAsFixed(6)}'}',
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
          const SizedBox(height: 6),
          Text('Log', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: _debugLog.isEmpty
                ? Text('No debug events yet.', style: theme.textTheme.bodySmall)
                : SingleChildScrollView(
                    child: Text(_debugLog.join('\n'), style: theme.textTheme.bodySmall),
                  ),
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

    _settings.setBackgroundBusy(true);

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
        _settings.setBackgroundEnabled(true);
        _showSnack('Background mode enabled. Keep playback running to spoof.');
        return true;
      } else {
        await FlutterBackground.disableBackgroundExecution();
        _settings.setBackgroundEnabled(false);
        unawaited(_cancelBackgroundNotification());
        return true;
      }
    } catch (error) {
      _showSnack('Background mode error: $error');
      return false;
    } finally {
      _settings.setBackgroundBusy(false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapState.setLastMapStyleDark(null);
    unawaited(_applyMapStyle());
    if (_mapState.pendingFitRoute) {
      _fitRouteToMap();
    }
  }

  Future<void> _applyMapStyle() async {
    if (_mapController == null) {
      return;
    }
    final useDarkStyle = _shouldUseDarkMapStyle();
    if (_mapState.lastMapStyleDark == useDarkStyle) {
      return;
    }
    _mapState.setLastMapStyleDark(useDarkStyle);
    await _mapController!.setMapStyle(useDarkStyle ? darkMapStyle : null);
  }

  bool _shouldUseDarkMapStyle() {
    switch (_settings.darkModeSetting) {
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
    _settings.setDarkModeSetting(setting);
    switch (setting) {
      case DarkModeSetting.on:
        themeController.mode.value = ThemeMode.system;
        break;
      case DarkModeSetting.uiOnly:
        themeController.mode.value = ThemeMode.dark;
        break;
      case DarkModeSetting.mapOnly:
      case DarkModeSetting.off:
        themeController.mode.value = ThemeMode.light;
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
      final points = _route.decodePolyline(polyline);
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
    _routeState.setRouteFromPoints(points);
    _setProgress(0);
  }

  void _togglePlayback() {
    if (_playback.isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }


  void _startPlayback() {
    if (!_route.hasRoute || _route.totalDistanceMeters == 0) {
      return;
    }
    _playback.start(_onTick);
  }

  void _stopPlayback() {
    if (!_playback.isPlaying) {
      return;
    }
    _playback.stop();
  }

  void _onTick() {
    if (!_playback.isPlaying || !_route.hasRoute) {
      return;
    }

    final deltaSeconds = _playback.consumeDeltaSeconds();
    if (deltaSeconds == null) {
      return;
    }

    final speedMps = _playback.speedMps;
    final currentDistance = _route.progressDistance;
    final nextDistance = currentDistance + speedMps * deltaSeconds;

    if (nextDistance >= _route.totalDistanceMeters) {
      _setProgress(1);
      _stopPlayback();
      return;
    }
    if (nextDistance <= 0) {
      _setProgress(0);
      _stopPlayback();
      return;
    }

    _setProgress(nextDistance / _route.totalDistanceMeters);
  }

  void _setProgress(double value) {
    if (!_route.hasPoints) {
      return;
    }

    final clamped = _clamp01(value);
    _route.setProgress(clamped);
    final position = _route.positionForCurrentProgress() ?? _route.points.first;

    _mapState.setCurrentPosition(position, updateLastInjected: true);
    _refreshMarkers();

    unawaited(_sendMockLocation(position));
    _followCamera(position);
  }

  void _setManualLocation(LatLng position, {bool force = false, double? zoom}) {
    if (_route.hasPoints || _waypoints.hasPoints) {
      if (!force) {
        return;
      }
      _clearRoute();
    }
    _stopPlayback();
    _mapState.setCurrentPosition(position, updateLastInjected: true);
    _mapState.setAutoFollow(true);
    _refreshMarkers();
    unawaited(_sendMockLocation(position));
    if (_mapController != null) {
      _mapState.setProgrammaticMove(true);
      final update = zoom == null ? CameraUpdate.newLatLng(position) : CameraUpdate.newLatLngZoom(position, zoom);
      _mapController!.animateCamera(update);
      return;
    }
    _followCamera(position);
  }

  void _refreshMarkers() {
    final markers = <Marker>{};
    final currentPosition = _mapState.currentPosition;
    if (_settings.showMockMarker && currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Mocked GPS'),
          zIndex: 1,
        ),
      );
    }
    markers.addAll(_mapState.customMarkers);
    _mapState.setMarkers(markers);
  }

  void _addCustomPoint(LatLng position) {
    if (_route.hasPoints && !_waypoints.usingCustomRoute) {
      _showSnack('Clear the loaded route to edit a custom route.');
      return;
    }
    _routeState.addWaypoint(position);
    if (_route.hasPoints) {
      _setProgress(0);
    }
    _followCamera(position);
  }

  void _removeCustomPoint(int index) {
    _routeState.removeWaypoint(index);
    if (_route.hasPoints) {
      _setProgress(0);
    }
  }

  void _selectCustomPoint(int index) {
    _routeState.selectWaypoint(index);
  }

  Future<void> _saveCustomRoute() async {
    if (_waypoints.points.isEmpty) {
      _showSnack('No custom route to save.');
      return;
    }
    final suggested = 'Custom route ${DateTime.now().toLocal().toString().substring(0, 16)}';
    final controller = TextEditingController(text: suggested);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save route'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Route name',
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
    if (!mounted || name == null) {
      return;
    }
    final trimmed = name.isEmpty ? suggested : name;
    await _upsertSavedRoute(trimmed);
    _showSnack('Saved "$trimmed".');
  }

  Future<void> _upsertSavedRoute(String name) async {
    await _prefs.upsertSavedRoute(
      name: name,
      points: _waypoints.points,
      names: _waypoints.names,
    );
  }

  Future<bool> _openSavedRoutes() async {
    final routes = await _prefs.loadSavedRoutes();
    if (routes.isEmpty) {
      _showSnack('No saved routes yet.');
      return false;
    }
    var loaded = false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView.separated(
              itemCount: routes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = routes[index];
                final name = item['name']?.toString() ?? 'Route';
                final points = (item['points'] as List?) ?? [];
                return ListTile(
                  title: Text(name),
                  subtitle: Text('${points.length} points'),
                  onTap: () {
                    _applySavedRoute(item);
                    loaded = true;
                    Navigator.of(context).pop();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      routes.removeAt(index);
                      await _prefs.saveRoutes(routes);
                      setSheetState(() {});
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
    return loaded;
  }

  void _applySavedRoute(Map route) {
    final points = <LatLng>[];
    final names = <String>[];
    final rawPoints = route['points'];
    if (rawPoints is List) {
      for (final item in rawPoints) {
        if (item is Map) {
          final lat = item['lat'];
          final lng = item['lng'];
          if (lat is num && lng is num) {
            points.add(LatLng(lat.toDouble(), lng.toDouble()));
          }
        }
      }
    }
    final rawNames = route['names'];
    if (rawNames is List) {
      for (final item in rawNames) {
        names.add(item.toString());
      }
    }
    if (points.isEmpty) {
      _showSnack('Saved route is empty.');
      return;
    }
    _routeState.setWaypointsFromSaved(points, names);
    if (_route.hasPoints) {
      _setProgress(0);
    }
    _fitRouteToMap();
  }

  void _reorderCustomPoints(int oldIndex, int newIndex) {
    _routeState.reorderWaypoints(oldIndex, newIndex);
    if (_route.hasPoints) {
      _setProgress(0);
    }
  }

  String _defaultWaypointName(int index) => _waypoints.defaultName(index);

  Future<void> _renameCustomPoint(int index) async {
    if (index < 0 || index >= _waypoints.points.length) {
      return;
    }
    final currentName = _waypoints.names[index];
    final controller = TextEditingController();
    final focusNode = FocusNode();
    var canSave = false;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Rename waypoint'),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: currentName,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                final nextCanSave = value.trim().isNotEmpty;
                if (nextCanSave != canSave) {
                  setDialogState(() {
                    canSave = nextCanSave;
                  });
                }
              },
              onSubmitted: (value) {
                if (value.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(value.trim());
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: canSave ? () => Navigator.of(context).pop(controller.text.trim()) : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    focusNode.dispose();
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    _routeState.renameWaypoint(index, result);
    _refreshMarkers();
  }

  Future<void> _openWaypointList() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.6;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasPoints = _waypoints.points.isNotEmpty;
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
                            tooltip: 'Save route',
                            icon: const Icon(Icons.save),
                            onPressed: hasPoints ? _saveCustomRoute : null,
                          ),
                          IconButton(
                            tooltip: 'Load route',
                            icon: const Icon(Icons.folder_open),
                            onPressed: () async {
                              final loaded = await _openSavedRoutes();
                              if (loaded && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                        ),
                    ),
                    Expanded(
                      child: hasPoints
                          ? ReorderableListView.builder(
                              itemCount: _waypoints.points.length,
                              buildDefaultDragHandles: false,
                              onReorder: (oldIndex, newIndex) {
                                _reorderCustomPoints(oldIndex, newIndex);
                                setSheetState(() {});
                              },
                              itemBuilder: (context, index) {
                                final name = _waypoints.names.length > index
                                    ? _waypoints.names[index]
                                    : _defaultWaypointName(index);
                                final position = _waypoints.points[index];
                                return ListTile(
                                  key: ValueKey('wp_item_$index'),
                                  dense: true,
                                  title: Text(name),
                                  subtitle: Text(
                                    '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
                                  ),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    child: Text(
                                      '${index + 1}',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
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
                                        onPressed: () async {
                                          await _renameCustomPoint(index);
                                          if (context.mounted) {
                                            setSheetState(() {});
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Delete',
                                        onPressed: () {
                                          _removeCustomPoint(index);
                                          setSheetState(() {});
                                        },
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: const Icon(Icons.drag_handle),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                'No waypoints yet. Tap and hold on the map to add points.',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _followCamera(LatLng position) {
    if (_mapController == null || !_mapState.autoFollow) {
      return;
    }
    _mapState.setProgrammaticMove(true);
    _mapController!.moveCamera(CameraUpdate.newLatLng(position));
  }

  void _fitRouteToMap() {
    if (_mapController == null) {
      _mapState.setPendingFitRoute(true);
      return;
    }
    if (!_route.hasPoints) {
      return;
    }
    _mapState.setPendingFitRoute(false);

    if (_route.points.length == 1) {
      _mapController!.moveCamera(CameraUpdate.newLatLngZoom(_route.points.first, 16));
      return;
    }

    final bounds = _boundsFromLatLngs(_route.points);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  Future<void> _sendMockLocation(LatLng position) async {
    final speedMps = _playback.speedMps.abs();
    final hadError = _mockError != null;
    try {
      final result = await widget.mockController.setMockLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: 3.0,
        speedMps: speedMps,
      );
      if (mounted) {
        setState(() {
          _lastMockStatus = result;
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
        _appendDebugLog('Mock apply failed: $details');
      } else if (_mockError != null && mounted) {
        setState(() {
          _mockError = null;
        });
        if (hadError) {
          _appendDebugLog('Mock apply ok.');
        }
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
        _appendDebugLog('Mock exception: ${error.message ?? error.code}');
      }
    }
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

  void _showOverlayMessage(String message) {
    if (!mounted) {
      return;
    }
    _overlayMessage?.remove();
    _overlayMessage = null;
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      _showSnack(message);
      return;
    }
    final entry = OverlayEntry(
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.inverseSurface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: TextStyle(color: colors.onInverseSurface),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    _overlayMessage = entry;
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) {
        entry.remove();
      }
      if (identical(_overlayMessage, entry)) {
        _overlayMessage = null;
      }
    });
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

    final accepted = await _prefs.isTosAccepted();
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
                await _prefs.setTosAccepted(true);
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

    _tosAccepted = await _prefs.isTosAccepted();
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
      return await widget.mockController.isDeveloperModeEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isMockLocationAppNative() async {
    try {
      return await widget.mockController.isMockLocationApp();
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshMockAppStatus() async {
    try {
      final selected = await widget.mockController.getMockLocationApp();
      final isSelected = await _isMockLocationAppNative();
      if (mounted) {
        setState(() {
          _selectedMockApp = selected;
          _isMockLocationApp = isSelected;
        });
      }
      _appendDebugLog('Mock app: ${selected ?? '—'} selected=${isSelected ? 'YES' : 'NO'}');
    } catch (_) {
      // Ignore refresh failures.
    }
  }

  Future<void> _openSettingsSheet() async {
    if (!mounted) {
      return;
    }
    var showSetupBar = _settings.showSetupBar;
    var showDebugPanel = _settings.showDebugPanel;
    var showMockMarker = _settings.showMockMarker;
    var backgroundEnabled = _settings.backgroundEnabled;
    var backgroundBusy = _settings.backgroundBusy;
    var darkModeSetting = _settings.darkModeSetting;
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
                            _settings.setShowSetupBar(value);
                          },
                        ),
                        buildToggle(
                          title: 'Show debug panel',
                          value: showDebugPanel,
                          onChanged: (value) {
                            setModalState(() {
                              showDebugPanel = value;
                            });
                            _settings.setShowDebugPanel(value);
                          },
                        ),
                        buildToggle(
                          title: 'Show mocked marker',
                          value: showMockMarker,
                          onChanged: (value) {
                            setModalState(() {
                              showMockMarker = value;
                            });
                            _settings.setShowMockMarker(value);
                            _refreshMarkers();
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
                                _settings.setBackgroundBusy(true);
                                final ok = await _setBackgroundMode(value);
                                setModalState(() {
                                  backgroundBusy = false;
                                  backgroundEnabled = _settings.backgroundEnabled;
                                });
                                _settings.setBackgroundBusy(false);
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
                            _settings.setBackgroundBusy(true);
                            final ok = await _setBackgroundMode(next);
                            setModalState(() {
                              backgroundBusy = false;
                              backgroundEnabled = _settings.backgroundEnabled;
                            });
                            _settings.setBackgroundBusy(false);
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
                                _applyDarkModeSetting(value);
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
                            _mapState.setCurrentPosition(location);
                            _mapState.setLastInjectedPosition(null);
                            _mapState.setAutoFollow(true);
                            _refreshMarkers();
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
                        if (showDebugPanel) ...[
                          const Divider(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildDebugPanel(context),
                          ),
                        ],
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

  Future<void> _openHelpScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => HelpScreen(helpSections: _helpSections),
      ),
    );
  }

  Future<void> _openDeveloperSettings() async {
    try {
      await widget.mockController.openDeveloperSettings();
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
