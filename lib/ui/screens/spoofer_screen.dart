import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart' as scheduler;
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as flutter_local_notifications;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../controllers/mock_location_controller.dart';
import '../../controllers/preferences_controller.dart';
import '../../spoofer/bloc/map/spoofer_map_bloc.dart';
import '../../spoofer/bloc/map/spoofer_map_event.dart';
import '../../spoofer/bloc/map/spoofer_map_state.dart';
import '../../spoofer/bloc/message/spoofer_message_cubit.dart';
import '../../spoofer/bloc/message/spoofer_message_state.dart';
import '../../spoofer/bloc/mock/spoofer_mock_bloc.dart';
import '../../spoofer/bloc/mock/spoofer_mock_event.dart';
import '../../spoofer/bloc/mock/spoofer_mock_state.dart';
import '../../spoofer/bloc/playback/spoofer_playback_bloc.dart';
import '../../spoofer/bloc/playback/spoofer_playback_event.dart';
import '../../spoofer/bloc/playback/spoofer_playback_state.dart';
import '../../spoofer/bloc/route/spoofer_route_bloc.dart';
import '../../spoofer/bloc/route/spoofer_route_event.dart';
import '../../spoofer/bloc/route/spoofer_route_state.dart';
import '../../spoofer/bloc/settings/spoofer_settings_cubit.dart';
import '../../spoofer/bloc/settings/spoofer_settings_state.dart';
import '../../spoofer/coordinator/spoofer_runtime_coordinator.dart';
import '../map/map_style.dart';
import '../help/help_content.dart';
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

  final PreferencesController _prefs = PreferencesController();
  final SpooferRuntimeCoordinator _coordinator = const SpooferRuntimeCoordinator();
  OverlayEntry? _overlayMessage;
  int _lastMessageId = -1;
  int _lastRouteMessageId = -1;
  int _lastMockMessageId = -1;
  int _lastMockPromptId = -1;
  int _activePointers = 0;
  bool _userInteracting = false;
  final flutter_local_notifications.FlutterLocalNotificationsPlugin _notifications =
      flutter_local_notifications.FlutterLocalNotificationsPlugin();
  static const int _backgroundNotificationId = 1001;
  static const int _initialMapStyleRetryCount = 3;
  static const Duration _initialMapStyleRetryDelay = Duration(milliseconds: 250);
  bool _tosAccepted = false;
  PackageInfo? _packageInfo;
  bool _packageInfoLoading = false;
  int _titleTapCount = 0;
  DateTime? _lastTitleTapAt;

  SpooferSettingsCubit get _settingsCubit => context.read<SpooferSettingsCubit>();
  SpooferSettingsState get _settingsState => _settingsCubit.state;
  SpooferMessageCubit get _messages => context.read<SpooferMessageCubit>();
  SpooferMapBloc get _mapBloc => context.read<SpooferMapBloc>();
  SpooferMapState get _mapState => _mapBloc.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initNotifications());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accepted = await _ensureTosAccepted();
      if (accepted) {
        _requestStartupChecks(showDialogs: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayMessage?.remove();
    _overlayMessage = null;
    unawaited(_notifications.cancel(_backgroundNotificationId));
    _routeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_settingsState.backgroundEnabled) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        unawaited(_showBackgroundNotification());
      } else if (state == AppLifecycleState.resumed) {
        unawaited(_cancelBackgroundNotification());
      }
      return;
    }
    final playbackBloc = context.read<SpooferPlaybackBloc>();
    if (state == AppLifecycleState.resumed) {
      playbackBloc.add(const SpooferPlaybackAppResumed());
    } else {
      playbackBloc.add(const SpooferPlaybackAppPaused());
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (!mounted || _settingsState.darkModeSetting != DarkModeSetting.on) {
      return;
    }
    unawaited(_applyMapStyle(force: true));
  }

  Future<void> _initNotifications() async {
    final androidSettings =
        flutter_local_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = flutter_local_notifications.InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  Future<void> _showBackgroundNotification() async {
    if (_settingsState.backgroundNotificationShown) {
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
    _settingsCubit.setBackgroundNotificationShown(true);
  }

  Future<void> _cancelBackgroundNotification() async {
    if (!_settingsState.backgroundNotificationShown) {
      return;
    }
    await _notifications.cancel(_backgroundNotificationId);
    _settingsCubit.setBackgroundNotificationShown(false);
  }

  void _setMapCurrentPosition(LatLng? position, {bool updateLastInjected = false}) {
    _mapBloc.add(
      SpooferMapCurrentPositionSetRequested(
        position: position,
        updateLastInjected: updateLastInjected,
      ),
    );
  }

  void _setMapLastInjectedPosition(LatLng? position) {
    _mapBloc.add(SpooferMapLastInjectedPositionSetRequested(position: position));
  }

  void _setMapPolylines(Set<Polyline> polylines) {
    _mapBloc.add(SpooferMapPolylinesSetRequested(polylines: polylines));
  }

  void _setMapMarkers(Set<Marker> markers) {
    _mapBloc.add(SpooferMapMarkersSetRequested(markers: markers));
  }

  void _setMapAutoFollow(bool value) {
    _mapBloc.add(SpooferMapAutoFollowSetRequested(value: value));
  }

  void _setMapPendingFitRoute(bool value) {
    _mapBloc.add(SpooferMapPendingFitRouteSetRequested(value: value));
  }

  void _setMapProgrammaticMove(bool value) {
    _mapBloc.add(SpooferMapProgrammaticMoveSetRequested(value: value));
  }

  void _setMapLastMapStyleDark(bool? value) {
    _mapBloc.add(SpooferMapLastMapStyleDarkSetRequested(value: value));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_applyMapStyle());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SpooferRouteBloc, SpooferRouteState>(
          listener: (context, routeState) => _handleRouteBlocState(routeState),
        ),
        BlocListener<SpooferPlaybackBloc, SpooferPlaybackState>(
          listenWhen: (previous, current) => previous.tickSequence != current.tickSequence,
          listener: (context, playbackState) => _handlePlaybackTick(playbackState),
        ),
        BlocListener<SpooferMockBloc, SpooferMockState>(
          listener: (context, mockState) => _handleMockBlocState(mockState),
        ),
        BlocListener<SpooferMessageCubit, SpooferMessageState>(
          listener: (context, messageState) => _handleUiMessageState(messageState),
        ),
      ],
      child: BlocBuilder<SpooferRouteBloc, SpooferRouteState>(
        builder: (context, routeState) {
          return BlocBuilder<SpooferPlaybackBloc, SpooferPlaybackState>(
            builder: (context, playbackState) {
              return BlocBuilder<SpooferMockBloc, SpooferMockState>(
                builder: (context, mockState) {
                  return BlocBuilder<SpooferSettingsCubit, SpooferSettingsState>(
                    builder: (context, settingsState) {
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
                              BlocBuilder<SpooferMapBloc, SpooferMapState>(
                                builder: (context, mapState) {
                                  return Listener(
                                    onPointerDown: (_) {
                                      _activePointers += 1;
                                      _userInteracting = true;
                                    },
                                    onPointerUp: (_) {
                                      _activePointers = math.max(0, _activePointers - 1);
                                      if (_activePointers == 0) {
                                        _userInteracting = false;
                                      }
                                    },
                                    onPointerCancel: (_) {
                                      _activePointers = 0;
                                      _userInteracting = false;
                                    },
                                    child: GoogleMap(
                                      key: ValueKey(
                                        'map-${mockState.hasLocationPermission == true ? 'loc-on' : 'loc-off'}',
                                      ),
                                      initialCameraPosition: CameraPosition(
                                        target: mapState.currentPosition ?? const LatLng(0, 0),
                                        zoom: mapState.currentPosition == null ? 2 : 16,
                                      ),
                                      onMapCreated: _onMapCreated,
                                      onCameraMoveStarted: () {
                                        if (_userInteracting) {
                                          if (mapState.autoFollowEnabled) {
                                            _setMapAutoFollow(false);
                                          }
                                          if (mapState.isProgrammaticMove) {
                                            _setMapProgrammaticMove(false);
                                          }
                                          return;
                                        }
                                        if (mapState.isProgrammaticMove) {
                                          return;
                                        }
                                      },
                                      onCameraMove: (_) {
                                        if (_userInteracting && mapState.autoFollowEnabled) {
                                          _setMapAutoFollow(false);
                                        }
                                      },
                                      onCameraIdle: () {
                                        if (mapState.isProgrammaticMove) {
                                          _setMapProgrammaticMove(false);
                                        }
                                      },
                                      onTap: (position) {
                                        if (routeState.selectedWaypointIndex != null) {
                                          context.read<SpooferRouteBloc>().add(
                                                const SpooferRouteWaypointSelectedRequested(index: null),
                                              );
                                          return;
                                        }
                                        if (routeState.hasPoints || routeState.hasWaypointPoints) {
                                          return;
                                        }
                                        _setManualLocation(position);
                                      },
                                      onLongPress: (position) {
                                        if (routeState.hasPoints && !routeState.usingCustomRoute) {
                                          _messages.showSnack('Clear the loaded route to add points.');
                                          return;
                                        }
                                        _addCustomPoint(position);
                                      },
                                      markers: mapState.markers,
                                      polylines: mapState.polylines,
                                      mapToolbarEnabled: false,
                                      padding: _mapPaddingForCamera(context),
                                      myLocationEnabled: mockState.hasLocationPermission == true,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                    ),
                                  );
                                },
                              ),
                              BlocBuilder<SpooferMapBloc, SpooferMapState>(
                                builder: (context, mapState) {
                                  final hasRoute = routeState.hasRoute;
                                  final bottomInset = MediaQuery.of(context).padding.bottom;
                                  final controlsVisible = routeState.hasRoute;
                                  final double overlayBottom = 12 + (controlsVisible ? 0.0 : bottomInset);

                                  return Stack(
                                    children: [
                                      Positioned(
                                        right: 12,
                                        top: 12,
                                        child: MapActionButtons(
                                          hasRoute: hasRoute,
                                          hasPoints: routeState.hasPoints,
                                          isPlaying: playbackState.isPlaying,
                                          showWaypoints: !(routeState.hasRoute && !routeState.usingCustomRoute),
                                          onLoadOrClear: routeState.hasPoints ? _clearRoute : _openRouteInputSheet,
                                          onTogglePlayback: hasRoute ? _togglePlayback : null,
                                          onOpenWaypoints: _openWaypointList,
                                        ),
                                      ),
                                      Positioned(
                                        right: 12,
                                        bottom: overlayBottom,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (hasRoute) ...[
                                              FloatingActionButton.small(
                                                heroTag: 'fitRoute',
                                                onPressed: () {
                                                  _fitRouteToMap();
                                                  _messages.showOverlay('Map fit to route');
                                                },
                                                tooltip: 'Fit route',
                                                child: const Icon(Icons.fit_screen),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            FloatingActionButton.small(
                                              heroTag: 'recenter',
                                              onPressed: mapState.currentPosition == null
                                                  ? null
                                                  : () {
                                                      final wasAutoFollow = mapState.autoFollowEnabled;
                                                      _setMapAutoFollow(true);
                                                      _followCamera(mapState.currentPosition!);
                                                      if (!wasAutoFollow) {
                                                        _messages.showOverlay('Auto-follow enabled');
                                                      }
                                                    },
                                              tooltip: 'Recenter',
                                              child: Icon(
                                                mapState.autoFollowEnabled
                                                    ? Icons.my_location
                                                    : Icons.center_focus_strong,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (routeState.selectedWaypointIndex != null)
                                        Positioned(
                                          left: 12,
                                          right: 72,
                                          bottom: overlayBottom,
                                          child: WaypointActionRow(
                                            onRename: () {
                                              final idx = routeState.selectedWaypointIndex;
                                              if (idx != null) {
                                                _renameCustomPoint(idx);
                                              }
                                            },
                                            onDelete: () {
                                              final idx = routeState.selectedWaypointIndex;
                                              if (idx != null) {
                                                _removeCustomPoint(idx);
                                              }
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                },
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
                          child: routeState.hasRoute
                              ? SafeArea(
                                  key: const ValueKey('controls'),
                                  top: false,
                                  child: _buildControls(
                                    context,
                                    routeState,
                                    playbackState,
                                    mockState,
                                    settingsState,
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('no-controls')),
                        ),
                      ],
                    ),
                  );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    SpooferRouteState routeState,
    SpooferPlaybackState playbackState,
    SpooferMockState mockState,
    SpooferSettingsState settingsState,
  ) {
    final bool hasRoute = routeState.hasRoute;
    final progressLabel = '${(routeState.progress * 100).toStringAsFixed(0)}%';
    final distanceLabel = routeState.totalDistanceMeters > 0
        ? '${_formatDistance(routeState.progressDistance)} / ${_formatDistance(routeState.totalDistanceMeters)}'
        : '0 m';

    return ControlsPanel(
      showSetupBar: settingsState.showSetupBar,
      setupLabel: 'Setup: '
          'location ${_statusLabel(mockState.hasLocationPermission)} · '
          'dev ${_statusLabel(mockState.isDeveloperModeEnabled)} · '
          'mock ${_statusLabel(mockState.isMockLocationApp)}',
      onRunSetupChecks: () => _requestStartupChecks(showDialogs: true),
      progressLabel: progressLabel,
      distanceLabel: distanceLabel,
      progress: _clamp01(routeState.progress),
      onProgressChanged: hasRoute
          ? (value) {
              context.read<SpooferPlaybackBloc>().add(const SpooferPlaybackTickClockResetRequested());
              _setProgress(value);
            }
          : null,
      speedMps: playbackState.speedMps,
      onSpeedChanged: (value) {
        context.read<SpooferPlaybackBloc>().add(
              SpooferPlaybackSpeedSetRequested(speedMps: value),
            );
      },
      mockError: mockState.mockError,
    );
  }

  Future<void> _openRouteInputSheet() async {
    final controller = TextEditingController(text: _routeController.text);
    String? detectedPolyline;
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final trimmed = value.text.trim();
            final isEmpty = trimmed.isEmpty;
            detectedPolyline = isEmpty ? null : _extractPolylineFromInput(trimmed);
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Text(
                'Load route',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
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
                  if (isEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Input required to load a route.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ] else if (detectedPolyline != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Polyline detected.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ],
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
                    _messages.showOverlay('Filled demo route.');
                  },
                  child: const Text('Demo'),
                ),
                FilledButton(
                  onPressed: isEmpty
                      ? null
                      : () {
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
      },
    );
  }

  void _clearMockLocation() {
    context.read<SpooferMockBloc>().add(const SpooferMockClearLocationRequested());
  }

  Future<LatLng?> _getRealLocation() async {
    final current = await widget.mockController.getCurrentLocation();
    if (current != null) {
      return current;
    }
    return widget.mockController.getLastKnownLocation();
  }

  Future<void> _clearRoute() async {
    final routeState = context.read<SpooferRouteBloc>().state;
    final playbackState = context.read<SpooferPlaybackBloc>().state;
    if (playbackState.isPlaying && routeState.hasRoute) {
      final confirm = await _confirmDialog(
        'Clear route?',
        'Playback is running. Clear the route and stop playback?',
        'Clear route',
      );
      if (!confirm) {
        return;
      }
    }
    _stopPlayback();
    context.read<SpooferRouteBloc>().add(const SpooferRouteClearRequested());
    _setMapCurrentPosition(null, updateLastInjected: true);
    _setMapPolylines(const <Polyline>{});
    _refreshMarkers();
  }

  void _appendDebugLog(String message) {
    context.read<SpooferMockBloc>().add(SpooferMockDebugLogAppended(message: message));
  }

  void _handleRouteBlocState(SpooferRouteState routeState) {
    final message = routeState.message;
    if (message != null && message.id != _lastRouteMessageId) {
      _lastRouteMessageId = message.id;
      _messages.showSnack(message.text);
    }
    if (!routeState.hasRoute && context.read<SpooferPlaybackBloc>().state.isPlaying) {
      _stopPlayback();
    }
    _setMapPolylines(_buildRoutePolylines(routeState.routePoints));
    _refreshMarkers(routeState);
  }

  void _handleMockBlocState(SpooferMockState mockState) {
    final message = mockState.message;
    if (message != null && message.id != _lastMockMessageId) {
      _lastMockMessageId = message.id;
      _messages.showSnack(message.text);
    }
    final prompt = mockState.prompt;
    if (prompt != null && prompt.id != _lastMockPromptId) {
      _lastMockPromptId = prompt.id;
      unawaited(_handleMockPrompt(prompt));
    }
  }

  Future<void> _handleMockPrompt(SpooferMockStatePrompt prompt) async {
    if (!mounted) {
      return;
    }
    final accepted = await _confirmDialog(
      prompt.title,
      prompt.message,
      prompt.actionLabel,
    );
    if (!mounted) {
      return;
    }
    context.read<SpooferMockBloc>().add(
          SpooferMockPromptResolved(
            promptId: prompt.id,
            accepted: accepted,
          ),
        );
  }

  void _handlePlaybackTick(SpooferPlaybackState playbackState) {
    if (!playbackState.isPlaying) {
      return;
    }
    final routeState = context.read<SpooferRouteBloc>().state;
    final resolution = _coordinator.resolvePlaybackTick(
      routeState: routeState,
      playbackState: playbackState,
    );
    if (resolution == null) {
      if (!routeState.hasRoute) {
        _stopPlayback();
      }
      return;
    }
    if (resolution.boundary == PlaybackBoundary.end) {
      _setProgress(1);
      _stopPlayback();
      return;
    }
    if (resolution.boundary == PlaybackBoundary.start) {
      _setProgress(0);
      _stopPlayback();
      return;
    }
    _setProgress(resolution.progress);
  }

  Set<Polyline> _buildRoutePolylines(List<LatLng> points) {
    if (points.length < 2) {
      return const <Polyline>{};
    }
    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blueAccent,
        width: 4,
        points: points,
      ),
    };
  }

  EdgeInsets _mapPaddingForCamera(BuildContext context) {
    return EdgeInsets.zero;
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

  Widget _buildDebugPanel(BuildContext context, SpooferMockState mockState) {
    final status = mockState.lastMockStatus;
    final theme = Theme.of(context);
    if (!_settingsState.showDebugPanel) {
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
            'Mock app selected: ${mockState.isMockLocationApp == null ? '—' : mockState.isMockLocationApp == true ? 'YES' : 'NO'}',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Selected package: ${mockState.selectedMockApp ?? '—'}',
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
            child: mockState.debugLog.isEmpty
                ? Text('No debug events yet.', style: theme.textTheme.bodySmall)
                : SingleChildScrollView(
                    child: Text(mockState.debugLog.join('\n'), style: theme.textTheme.bodySmall),
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
      _messages.showSnack('Background mode is only supported on Android.');
      return false;
    }

    _settingsCubit.setBackgroundBusy(true);

    try {
      if (enabled) {
        final notificationStatus = await Permission.notification.request();
        if (!notificationStatus.isGranted) {
          _messages.showSnack('Notification permission is required for background mode.');
          return false;
        }

        final initialized = await FlutterBackground.initialize(androidConfig: _backgroundConfig);
        if (!initialized) {
          _messages.showSnack('Please disable battery optimizations to enable background mode.');
          return false;
        }
        final hasPermissions = await FlutterBackground.hasPermissions;
        if (!hasPermissions) {
          _messages.showSnack(
            'Background permissions not granted. Disable battery optimizations and retry.',
          );
          return false;
        }
        final success = await FlutterBackground.enableBackgroundExecution();
        if (!success) {
          _messages.showSnack('Failed to enable background mode.');
          return false;
        }
        _settingsCubit.setBackgroundEnabled(true);
        _messages.showSnack('Background mode enabled. Keep playback running to spoof.');
        return true;
      } else {
        await FlutterBackground.disableBackgroundExecution();
        _settingsCubit.setBackgroundEnabled(false);
        unawaited(_cancelBackgroundNotification());
        return true;
      }
    } catch (error) {
      _messages.showSnack('Background mode error: $error');
      return false;
    } finally {
      _settingsCubit.setBackgroundBusy(false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapLastMapStyleDark(null);
    unawaited(_applyMapStyle(force: true));
    unawaited(_retryInitialMapStyleApply());
    if (_mapState.pendingFitRoute) {
      _fitRouteToMap();
    }
  }

  Future<void> _retryInitialMapStyleApply() async {
    for (var attempt = 0; attempt < _initialMapStyleRetryCount; attempt += 1) {
      await Future<void>.delayed(_initialMapStyleRetryDelay);
      final applied = await _applyMapStyle(force: true);
      if (applied) {
        return;
      }
    }
  }

  Future<bool> _applyMapStyle({bool force = false}) async {
    if (_mapController == null) {
      return false;
    }
    final useDarkStyle = _shouldUseDarkMapStyle();
    if (!force && _mapState.lastMapStyleDark == useDarkStyle) {
      return true;
    }
    try {
      await _mapController!.setMapStyle(useDarkStyle ? darkMapStyle : null);
      _setMapLastMapStyleDark(useDarkStyle);
      return true;
    } catch (_) {
      _setMapLastMapStyleDark(null);
      return false;
    }
  }

  bool _shouldUseDarkMapStyle() {
    switch (_settingsState.darkModeSetting) {
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
    _settingsCubit.setDarkModeSetting(setting);
    unawaited(_applyMapStyle());
  }

  Future<void> _loadRouteFromInput() async {
    final input = _routeController.text.trim();
    if (input.isEmpty) {
      _messages.showSnack('Paste an encoded polyline or Routes API JSON.');
      return;
    }

    _stopPlayback();

    final bloc = context.read<SpooferRouteBloc>();
    final previousRevision = bloc.state.revision;
    bloc.add(SpooferRouteLoadRequested(input: input));

    try {
      final nextState = await bloc.stream.firstWhere((state) => state.revision > previousRevision);
      if (!mounted) {
        return;
      }
      if (nextState.hasRoute) {
        final position = nextState.currentRoutePosition ?? nextState.routePoints.first;
        _setMapCurrentPosition(position, updateLastInjected: true);
        _refreshMarkers(nextState);
        unawaited(_sendMockLocation(position));
        _fitRouteToMap();
      }
    } on StateError {
      // no-op
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

  void _togglePlayback() {
    if (context.read<SpooferPlaybackBloc>().state.isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }


  void _startPlayback() {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (!routeState.hasRoute || routeState.totalDistanceMeters == 0) {
      return;
    }
    context.read<SpooferPlaybackBloc>().add(const SpooferPlaybackPlayRequested());
  }

  void _stopPlayback() {
    if (!context.read<SpooferPlaybackBloc>().state.isPlaying) {
      return;
    }
    context.read<SpooferPlaybackBloc>().add(const SpooferPlaybackPauseRequested());
  }

  void _setProgress(double value) {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (!routeState.hasPoints) {
      return;
    }

    final clamped = _clamp01(value);
    final position = _coordinator.positionForProgress(routeState, clamped) ?? routeState.routePoints.first;
    context.read<SpooferRouteBloc>().add(SpooferRouteProgressSetRequested(progress: clamped));

    _setMapCurrentPosition(position, updateLastInjected: true);
    _refreshMarkers(routeState);
    unawaited(_sendMockLocation(position));
    _followCamera(position);
  }

  void _setManualLocation(LatLng position, {bool force = false, double? zoom}) {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (routeState.hasPoints || routeState.hasWaypointPoints) {
      if (!force) {
        return;
      }
      unawaited(_clearRoute());
    }
    _stopPlayback();
    _setMapCurrentPosition(position, updateLastInjected: true);
    _setMapAutoFollow(true);
    _refreshMarkers();
    unawaited(_sendMockLocation(position));
    if (_mapController != null) {
      _setMapProgrammaticMove(true);
      final update = zoom == null ? CameraUpdate.newLatLng(position) : CameraUpdate.newLatLngZoom(position, zoom);
      _mapController!.animateCamera(update);
      return;
    }
    _followCamera(position);
  }

  void _refreshMarkers([SpooferRouteState? routeState]) {
    final state = routeState ?? context.read<SpooferRouteBloc>().state;
    final markers = <Marker>{};
    final currentPosition = _mapState.currentPosition;
    if (_settingsState.showMockMarker && currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: currentPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Mocked GPS'),
          zIndexInt: 1,
        ),
      );
    }
    for (var i = 0; i < state.waypointPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('wp_$i'),
          position: state.waypointPoints[i],
          draggable: true,
          onDragEnd: (position) {
            context.read<SpooferRouteBloc>().add(
                  SpooferRouteWaypointUpdatedRequested(index: i, position: position),
                );
            context.read<SpooferRouteBloc>().add(
                  SpooferRouteWaypointSelectedRequested(index: i),
                );
          },
          onTap: () {
            context.read<SpooferRouteBloc>().add(
                  SpooferRouteWaypointSelectedRequested(index: i),
                );
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == state.selectedWaypointIndex ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: state.waypointNames.length > i ? state.waypointNames[i] : _defaultWaypointName(i),
            snippet: 'Hold and drag to move',
          ),
          zIndexInt: 2,
        ),
      );
    }
    _setMapMarkers(markers);
  }

  void _addCustomPoint(LatLng position) {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (routeState.hasPoints && !routeState.usingCustomRoute) {
      _messages.showSnack('Clear the loaded route to edit a custom route.');
      return;
    }
    context.read<SpooferRouteBloc>().add(SpooferRouteWaypointAddedRequested(position: position));
    if (context.read<SpooferRouteBloc>().state.hasPoints) {
      _setProgress(0);
    }
    _followCamera(position);
  }

  void _removeCustomPoint(int index) {
    context.read<SpooferRouteBloc>().add(SpooferRouteWaypointRemovedRequested(index: index));
    if (context.read<SpooferRouteBloc>().state.hasPoints) {
      _setProgress(0);
    }
  }

  void _selectCustomPoint(int index) {
    context.read<SpooferRouteBloc>().add(SpooferRouteWaypointSelectedRequested(index: index));
  }

  Future<void> _saveCustomRoute() async {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (routeState.waypointPoints.isEmpty) {
      _messages.showSnack('No custom route to save.');
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
    context.read<SpooferRouteBloc>().add(SpooferRouteSavedRouteSaveRequested(name: trimmed));
  }

  Future<bool> _openSavedRoutes() async {
    final bloc = context.read<SpooferRouteBloc>();
    final previousRevision = bloc.state.revision;
    bloc.add(const SpooferRouteSavedRoutesLoadRequested());
    final loadedState = await bloc.stream.firstWhere((state) => state.revision > previousRevision);
    final routes = List<Map<String, Object?>>.from(loadedState.savedRoutes);

    if (routes.isEmpty) {
      _messages.showSnack('No saved routes yet.');
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
                    context.read<SpooferRouteBloc>().add(SpooferRouteSavedRouteApplyRequested(index: index));
                    loaded = true;
                    Navigator.of(context).pop();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      context.read<SpooferRouteBloc>().add(
                            SpooferRouteSavedRouteDeleteRequested(index: index),
                          );
                      routes.removeAt(index);
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

  void _reorderCustomPoints(int oldIndex, int newIndex) {
    context.read<SpooferRouteBloc>().add(
          SpooferRouteWaypointsReorderedRequested(oldIndex: oldIndex, newIndex: newIndex),
        );
    if (context.read<SpooferRouteBloc>().state.hasPoints) {
      _setProgress(0);
    }
  }

  String _defaultWaypointName(int index) => 'Waypoint ${index + 1}';

  Future<void> _renameCustomPoint(int index) async {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (index < 0 || index >= routeState.waypointPoints.length) {
      return;
    }
    final currentName = routeState.waypointNames[index];
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
    context.read<SpooferRouteBloc>().add(
          SpooferRouteWaypointRenamedRequested(index: index, name: result),
        );
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
            final routeState = context.watch<SpooferRouteBloc>().state;
            final hasPoints = routeState.waypointPoints.isNotEmpty;
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
                              itemCount: routeState.waypointPoints.length,
                              buildDefaultDragHandles: false,
                              onReorder: (oldIndex, newIndex) {
                                _reorderCustomPoints(oldIndex, newIndex);
                                setSheetState(() {});
                              },
                              itemBuilder: (context, index) {
                                final name = routeState.waypointNames.length > index
                                    ? routeState.waypointNames[index]
                                    : _defaultWaypointName(index);
                                final position = routeState.waypointPoints[index];
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
    if (_mapController == null || !_mapState.autoFollowEnabled || _userInteracting) {
      return;
    }
    _setMapProgrammaticMove(true);
    _mapController!.moveCamera(CameraUpdate.newLatLng(position));
  }

  void _fitRouteToMap() {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (_mapController == null) {
      _setMapPendingFitRoute(true);
      return;
    }
    if (!routeState.hasPoints) {
      return;
    }
    _setMapPendingFitRoute(false);

    if (routeState.routePoints.length == 1) {
      _mapController!.moveCamera(CameraUpdate.newLatLngZoom(routeState.routePoints.first, 16));
      return;
    }

    final bounds = _boundsFromLatLngs(routeState.routePoints);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
  }

  Future<void> _sendMockLocation(LatLng position) async {
    final speedMps = context.read<SpooferPlaybackBloc>().state.speedMps.abs();
    context.read<SpooferMockBloc>().add(
          SpooferMockApplyLocationRequested(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: 3.0,
            speedMps: speedMps,
          ),
        );
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
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colors.onInverseSurface)),
        backgroundColor: colors.inverseSurface.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showOverlayMessage(String message) {
    if (!mounted) {
      return;
    }
    _overlayMessage?.remove();
    _overlayMessage = null;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
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

  void _handleUiMessageState(SpooferMessageState messageState) {
    final message = messageState.message;
    if (message == null || message.id == _lastMessageId || !mounted) {
      return;
    }
    _lastMessageId = message.id;
    switch (message.type) {
      case SpooferMessageType.snack:
        _showOverlayMessage(message.message);
        break;
      case SpooferMessageType.overlay:
        _showOverlayMessage(message.message);
        break;
    }
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

  void _requestStartupChecks({required bool showDialogs}) {
    context.read<SpooferMockBloc>().add(
          SpooferMockStartupChecksRequested(showDialogs: showDialogs),
        );
  }

  void _refreshMockAppStatus() {
    context.read<SpooferMockBloc>().add(const SpooferMockRefreshStatusRequested());
  }

  Future<void> _openSettingsSheet() async {
    if (!mounted) {
      return;
    }
    final initialSettings = _settingsState;
    var showSetupBar = initialSettings.showSetupBar;
    var showDebugPanel = initialSettings.showDebugPanel;
    var showMockMarker = initialSettings.showMockMarker;
    var backgroundEnabled = initialSettings.backgroundEnabled;
    var backgroundBusy = initialSettings.backgroundBusy;
    var darkModeSetting = initialSettings.darkModeSetting;
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
                            _settingsCubit.setShowSetupBar(value);
                          },
                        ),
                        buildToggle(
                          title: 'Show debug panel',
                          value: showDebugPanel,
                          onChanged: (value) {
                            setModalState(() {
                              showDebugPanel = value;
                            });
                            _settingsCubit.setShowDebugPanel(value);
                          },
                        ),
                        buildToggle(
                          title: 'Show mocked marker',
                          value: showMockMarker,
                          onChanged: (value) {
                            setModalState(() {
                              showMockMarker = value;
                            });
                            _settingsCubit.setShowMockMarker(value);
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
                                _settingsCubit.setBackgroundBusy(true);
                                final ok = await _setBackgroundMode(value);
                                setModalState(() {
                                  backgroundBusy = false;
                                  backgroundEnabled = _settingsState.backgroundEnabled;
                                });
                                _settingsCubit.setBackgroundBusy(false);
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
                            _settingsCubit.setBackgroundBusy(true);
                            final ok = await _setBackgroundMode(next);
                            setModalState(() {
                              backgroundBusy = false;
                              backgroundEnabled = _settingsState.backgroundEnabled;
                            });
                            _settingsCubit.setBackgroundBusy(false);
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
                            _clearMockLocation();
                            await Future.delayed(const Duration(milliseconds: 400));
                            var location = await _getRealLocation();
                            if (location == null) {
                              await Future.delayed(const Duration(milliseconds: 600));
                              location = await _getRealLocation();
                            }
                            if (location == null) {
                              _messages.showSnack('Real location not available yet.');
                              return;
                            }
                            _setMapCurrentPosition(location);
                            _setMapLastInjectedPosition(null);
                            _setMapAutoFollow(true);
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
                            _requestStartupChecks(showDialogs: true);
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Run setup checks'),
                        ),
                        if (showDebugPanel) ...[
                          const Divider(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildDebugPanel(context, context.watch<SpooferMockBloc>().state),
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
        builder: (context) => HelpScreen(helpSections: helpSections),
      ),
    );
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
