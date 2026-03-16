import 'dart:async';
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

import '../../bloc/map/spoofer_map_bloc.dart';
import '../../bloc/map/spoofer_map_event.dart';
import '../../bloc/map/spoofer_map_state.dart';
import '../../bloc/message/spoofer_message_bloc.dart';
import '../../bloc/message/spoofer_message_event.dart';
import '../../bloc/message/spoofer_message_state.dart';
import '../../bloc/mock/spoofer_mock_bloc.dart';
import '../../bloc/mock/spoofer_mock_event.dart';
import '../../bloc/mock/spoofer_mock_state.dart';
import '../../bloc/playback/spoofer_playback_bloc.dart';
import '../../bloc/playback/spoofer_playback_event.dart';
import '../../bloc/playback/spoofer_playback_state.dart';
import '../../bloc/route/spoofer_route_bloc.dart';
import '../../bloc/route/spoofer_route_event.dart';
import '../../bloc/route/spoofer_route_state.dart';
import '../../bloc/settings/spoofer_settings_bloc.dart';
import '../../bloc/settings/spoofer_settings_event.dart';
import '../../bloc/settings/spoofer_settings_state.dart';
import '../../service/route_playback_math.dart';
import '../../service/route_input_parser.dart';
import '../../service/infrastructure/mock_location_gateway.dart';
import '../../service/infrastructure/preferences_store.dart';
import '../dialogs/spoofer_dialogs.dart';
import '../map/map_style.dart';
import '../map/route_map_projection.dart';
import '../help/help_content.dart';
import '../widgets/controls_panel.dart';
import '../widgets/route_input_dialog.dart';
import '../widgets/saved_routes_sheet.dart';
import '../widgets/settings_side_sheet.dart';
import '../widgets/spoofer_app_bar.dart';
import '../widgets/spoofer_debug_panel.dart';
import '../widgets/spoofer_google_map_view.dart';
import '../widgets/spoofer_map_overlays.dart';
import '../widgets/waypoint_list_sheet.dart';
import 'help_screen.dart';
import 'search_screen.dart';

const String _samplePolyline =
    'kenpGym~}@IsJo@Cm@Qm@_@e@i@Wa@EMYV?BWyC?EzFmA@?^u@nAcEpA_FD?CAAKDSF?^gBD@DU@?@I@?D[NHB@`@cB@?y@m@m@e@AQCC@??Pj@b@DDd@uBDAHFFEDF?DTRJFz@gD@?QIJoB@?yBe@vBd@@?HcB@?zBXFAB@@c@?e@RuCD??[@?VD@@YGDq@?IB?HK@?AOPqA@?b@gC@?Xo@@?X}@@?z@uC@?nFfBlARBBVgC^iCB?o@hEa@pE?DgAdK_A|G?BgA_@MxA?BA?';
const String _privacyPolicyUrl =
    'https://support.voxtour.ai/voxtourai-gps-spoofer/privacy-policy/';

class SpooferScreen extends StatefulWidget {
  SpooferScreen({
    super.key,
    required this.mockGateway,
    PreferencesStore? preferencesStore,
    RoutePlaybackMath? routePlaybackMath,
    this.launchOptions = const SpooferScreenLaunchOptions(),
  }) : preferencesStore = preferencesStore ?? PreferencesStore(),
       routePlaybackMath = routePlaybackMath ?? const RoutePlaybackMath();

  final MockLocationGateway mockGateway;
  final PreferencesStore preferencesStore;
  final RoutePlaybackMath routePlaybackMath;
  final SpooferScreenLaunchOptions launchOptions;

  @override
  State<SpooferScreen> createState() => _SpooferScreenState();
}

class SpooferScreenLaunchOptions {
  const SpooferScreenLaunchOptions({
    this.initializeNotifications = true,
    this.manageBackgroundNotifications = true,
    this.runFirstLaunchPrompts = true,
    this.enableBackgroundModeOnLaunch = true,
    this.runStartupChecksOnLaunch = true,
  });

  final bool initializeNotifications;
  final bool manageBackgroundNotifications;
  final bool runFirstLaunchPrompts;
  final bool enableBackgroundModeOnLaunch;
  final bool runStartupChecksOnLaunch;
}

class _SpooferScreenState extends State<SpooferScreen>
    with WidgetsBindingObserver {
  final TextEditingController _routeController = TextEditingController();

  GoogleMapController? _mapController;

  OverlayEntry? _overlayMessage;
  int _lastMessageId = -1;
  int _lastRouteMessageId = -1;
  int _lastMockMessageId = -1;
  int _lastMockPromptId = -1;
  int _activePointers = 0;
  bool _userInteracting = false;
  final flutter_local_notifications.FlutterLocalNotificationsPlugin
  _notifications =
      flutter_local_notifications.FlutterLocalNotificationsPlugin();
  static const int _backgroundNotificationId = 1001;
  static const String _backgroundNotificationActionReset =
      'reset_mock_location';
  bool _tosAccepted = false;
  PackageInfo? _packageInfo;
  bool _packageInfoLoading = false;
  int _titleTapCount = 0;
  DateTime? _lastTitleTapAt;

  SpooferSettingsBloc get _settingsBloc => context.read<SpooferSettingsBloc>();
  SpooferSettingsState get _settingsState => _settingsBloc.state;
  SpooferMessageBloc get _messagesBloc => context.read<SpooferMessageBloc>();
  SpooferMapBloc get _mapBloc => context.read<SpooferMapBloc>();
  SpooferMapState get _mapState => _mapBloc.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.launchOptions.initializeNotifications) {
      unawaited(_initNotifications());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accepted = await _ensureTosAccepted();
      if (accepted) {
        if (widget.launchOptions.runFirstLaunchPrompts) {
          await _runFirstLaunchPrompts();
        }
        if (widget.launchOptions.enableBackgroundModeOnLaunch) {
          await _setBackgroundMode(true, showFeedback: false);
        }
        if (!mounted) {
          return;
        }
        if (widget.launchOptions.runStartupChecksOnLaunch) {
          _requestStartupChecks(showDialogs: true);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayMessage?.remove();
    _overlayMessage = null;
    if (widget.launchOptions.manageBackgroundNotifications) {
      unawaited(_notifications.cancel(_backgroundNotificationId));
    }
    _routeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final playbackBloc = context.read<SpooferPlaybackBloc>();
    if (state == AppLifecycleState.resumed) {
      playbackBloc.add(const SpooferPlaybackAppResumed());
    } else {
      playbackBloc.add(const SpooferPlaybackAppPaused());
    }
    if (widget.launchOptions.manageBackgroundNotifications) {
      unawaited(
        _syncBackgroundNotificationVisibility(appLifecycleState: state),
      );
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (!mounted || _settingsState.darkModeSetting != DarkModeSetting.on) {
      return;
    }
    setState(() {});
  }

  Future<void> _initNotifications() async {
    final androidSettings =
        flutter_local_notifications.AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
    final settings = flutter_local_notifications.InitializationSettings(
      android: androidSettings,
    );
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  void _handleNotificationResponse(
    flutter_local_notifications.NotificationResponse response,
  ) {
    if (response.actionId == _backgroundNotificationActionReset) {
      unawaited(_handleResetFromBackgroundNotification());
    }
  }

  Future<void> _handleResetFromBackgroundNotification() async {
    if (!mounted) {
      return;
    }
    _stopPlayback();
    await _disableMockLocationAndRecenter();
    if (!mounted) {
      return;
    }
    _showUiOverlay('Mock location reset.');
    await _syncBackgroundNotificationVisibility();
  }

  Future<void> _runFirstLaunchPrompts() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final promptsShown = await widget.preferencesStore.isStartupPromptsShown();
    if (promptsShown) {
      return;
    }

    try {
      var notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        notificationStatus = await Permission.notification.request();
      }
      await FlutterBackground.initialize(androidConfig: _backgroundConfig);
    } catch (_) {
      // First-launch prompt flow is best effort only.
    } finally {
      await widget.preferencesStore.setStartupPromptsShown(true);
    }
  }

  Future<void> _showBackgroundNotification() async {
    if (!widget.launchOptions.manageBackgroundNotifications) {
      return;
    }
    if (_settingsState.backgroundNotificationShown) {
      return;
    }
    final androidDetails =
        flutter_local_notifications.AndroidNotificationDetails(
          'background_mode',
          'Background mode',
          channelDescription: 'Indicates mock GPS can run in the background.',
          importance: flutter_local_notifications.Importance.low,
          priority: flutter_local_notifications.Priority.low,
          ongoing: true,
          autoCancel: false,
          actions:
              const <flutter_local_notifications.AndroidNotificationAction>[
                flutter_local_notifications.AndroidNotificationAction(
                  _backgroundNotificationActionReset,
                  'Reset location',
                  cancelNotification: false,
                  showsUserInterface: true,
                ),
              ],
          showWhen: false,
        );
    final details = flutter_local_notifications.NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      _backgroundNotificationId,
      'GPS spoofing active',
      'Location is actively being spoofed in the background.',
      details,
    );
    _settingsBloc.add(
      const SpooferSettingsBackgroundNotificationShownSetRequested(value: true),
    );
  }

  Future<void> _cancelBackgroundNotification() async {
    if (!widget.launchOptions.manageBackgroundNotifications) {
      return;
    }
    if (!_settingsState.backgroundNotificationShown) {
      return;
    }
    await _notifications.cancel(_backgroundNotificationId);
    _settingsBloc.add(
      const SpooferSettingsBackgroundNotificationShownSetRequested(
        value: false,
      ),
    );
  }

  bool _shouldShowBackgroundNotification({
    SpooferPlaybackState? playbackState,
    SpooferRouteState? routeState,
    AppLifecycleState? appLifecycleState,
  }) {
    final playback = playbackState ?? context.read<SpooferPlaybackBloc>().state;
    final route = routeState ?? context.read<SpooferRouteBloc>().state;
    final lifecycle =
        appLifecycleState ?? WidgetsBinding.instance.lifecycleState;
    final appNotFocused =
        lifecycle == AppLifecycleState.inactive ||
        lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden;
    final activeSpoofing = playback.isPlaying && route.hasRoute;
    return appNotFocused && activeSpoofing;
  }

  Future<void> _syncBackgroundNotificationVisibility({
    SpooferPlaybackState? playbackState,
    SpooferRouteState? routeState,
    AppLifecycleState? appLifecycleState,
  }) async {
    if (!widget.launchOptions.manageBackgroundNotifications) {
      return;
    }
    if (_shouldShowBackgroundNotification(
      playbackState: playbackState,
      routeState: routeState,
      appLifecycleState: appLifecycleState,
    )) {
      await _showBackgroundNotification();
    } else {
      await _cancelBackgroundNotification();
    }
  }

  void _setMapCurrentPosition(
    LatLng? position, {
    bool updateLastInjected = false,
  }) {
    _mapBloc.add(
      SpooferMapCurrentPositionSetRequested(
        position: position,
        updateLastInjected: updateLastInjected,
      ),
    );
  }

  void _setMapLastInjectedPosition(LatLng? position) {
    _mapBloc.add(
      SpooferMapLastInjectedPositionSetRequested(position: position),
    );
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

  void _showUiSnack(String message) {
    _messagesBloc.add(
      SpooferMessageShownRequested(
        type: SpooferMessageType.snack,
        message: message,
      ),
    );
  }

  void _showUiOverlay(String message) {
    _messagesBloc.add(
      SpooferMessageShownRequested(
        type: SpooferMessageType.overlay,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SpooferRouteBloc, SpooferRouteState>(
          listener: (context, routeState) => _handleRouteBlocState(routeState),
        ),
        BlocListener<SpooferPlaybackBloc, SpooferPlaybackState>(
          listenWhen: (previous, current) =>
              previous.tickSequence != current.tickSequence,
          listener: (context, playbackState) =>
              _handlePlaybackTick(playbackState),
        ),
        BlocListener<SpooferPlaybackBloc, SpooferPlaybackState>(
          listenWhen: (previous, current) =>
              previous.isPlaying != current.isPlaying,
          listener: (context, playbackState) {
            unawaited(
              _syncBackgroundNotificationVisibility(
                playbackState: playbackState,
              ),
            );
          },
        ),
        BlocListener<SpooferMockBloc, SpooferMockState>(
          listener: (context, mockState) => _handleMockBlocState(mockState),
        ),
        BlocListener<SpooferMessageBloc, SpooferMessageState>(
          listener: (context, messageState) =>
              _handleUiMessageState(messageState),
        ),
      ],
      child: Scaffold(
        appBar: SpooferAppBar(
          onTitleTap: _handleTitleTap,
          onSearchTap: _openSearchScreen,
          onHelpTap: _openHelpScreen,
          onSettingsTap: _openSettingsSheet,
        ),
        body: Column(
          children: [
            Expanded(flex: 15, child: _buildMapSection(context)),
            _buildBottomControlsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return BlocBuilder<SpooferRouteBloc, SpooferRouteState>(
      builder: (context, routeState) {
        return BlocBuilder<SpooferPlaybackBloc, SpooferPlaybackState>(
          builder: (context, playbackState) {
            return BlocBuilder<SpooferMockBloc, SpooferMockState>(
              builder: (context, mockState) {
                return Stack(
                  children: [
                    BlocBuilder<SpooferMapBloc, SpooferMapState>(
                      builder: (context, mapState) {
                        return SpooferGoogleMapView(
                          hasLocationPermission:
                              mockState.hasLocationPermission == true,
                          currentPosition: mapState.currentPosition,
                          markers: mapState.markers,
                          polylines: mapState.polylines,
                          padding: _mapPaddingForCamera(context),
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
                            if (_userInteracting &&
                                mapState.autoFollowEnabled) {
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
                                const SpooferRouteWaypointSelectedRequested(
                                  index: null,
                                ),
                              );
                              return;
                            }
                            if (routeState.hasPoints ||
                                routeState.hasWaypointPoints) {
                              return;
                            }
                            _setManualLocation(position);
                          },
                          onLongPress: (position) {
                            if (routeState.hasPoints &&
                                !routeState.usingCustomRoute) {
                              _showUiSnack(
                                'Clear the loaded route to add points.',
                              );
                              return;
                            }
                            _addCustomPoint(position);
                          },
                          mapStyle: _currentMapStyle(),
                        );
                      },
                    ),
                    BlocBuilder<SpooferMapBloc, SpooferMapState>(
                      builder: (context, mapState) {
                        final hasRoute = routeState.hasRoute;
                        final bottomInset = MediaQuery.of(
                          context,
                        ).padding.bottom;
                        final controlsVisible = routeState.hasRoute;
                        final double overlayBottom =
                            12 + (controlsVisible ? 0.0 : bottomInset);
                        return SpooferMapOverlays(
                          hasRoute: hasRoute,
                          hasPoints: routeState.hasPoints,
                          isUsingCustomRoute: routeState.usingCustomRoute,
                          selectedWaypointIndex:
                              routeState.selectedWaypointIndex,
                          isPlaying: playbackState.isPlaying,
                          currentPosition: mapState.currentPosition,
                          autoFollowEnabled: mapState.autoFollowEnabled,
                          overlayBottom: overlayBottom,
                          onLoadOrClear: routeState.hasPoints
                              ? _clearRoute
                              : _openRouteInputSheet,
                          onTogglePlayback: hasRoute ? _togglePlayback : null,
                          onOpenWaypoints: _openWaypointList,
                          onFitRoute: () {
                            _fitRouteToMap();
                            _showUiOverlay('Map fit to route');
                          },
                          onRecenter: () {
                            final currentPosition = mapState.currentPosition;
                            if (currentPosition == null) {
                              return;
                            }
                            final wasAutoFollow = mapState.autoFollowEnabled;
                            _setMapAutoFollow(true);
                            _followCamera(currentPosition);
                            if (!wasAutoFollow) {
                              _showUiOverlay('Auto-follow enabled');
                            }
                          },
                          onRenameSelected: () {
                            final idx = routeState.selectedWaypointIndex;
                            if (idx != null) {
                              _renameCustomPoint(idx);
                            }
                          },
                          onDeleteSelected: () {
                            final idx = routeState.selectedWaypointIndex;
                            if (idx != null) {
                              _removeCustomPoint(idx);
                            }
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomControlsSection(BuildContext context) {
    return BlocBuilder<SpooferRouteBloc, SpooferRouteState>(
      builder: (context, routeState) {
        return AnimatedSwitcher(
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
                  child: BlocBuilder<SpooferPlaybackBloc, SpooferPlaybackState>(
                    builder: (context, playbackState) {
                      return BlocBuilder<SpooferMockBloc, SpooferMockState>(
                        builder: (context, mockState) {
                          return BlocBuilder<
                            SpooferSettingsBloc,
                            SpooferSettingsState
                          >(
                            builder: (context, settingsState) {
                              return _buildControls(
                                context,
                                routeState,
                                playbackState,
                                mockState,
                                settingsState,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no-controls')),
        );
      },
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
        ? '${formatDistanceMeters(routeState.progressDistance)} / ${formatDistanceMeters(routeState.totalDistanceMeters)}'
        : '0 m';

    return ControlsPanel(
      showSetupBar: settingsState.showSetupBar,
      setupLabel:
          'Setup: '
          'location ${_statusLabel(mockState.hasLocationPermission)} · '
          'dev ${_statusLabel(mockState.isDeveloperModeEnabled)} · '
          'mock ${_statusLabel(mockState.isMockLocationApp)}',
      onRunSetupChecks: () => _requestStartupChecks(showDialogs: true),
      progressLabel: progressLabel,
      distanceLabel: distanceLabel,
      progress: _clamp01(routeState.progress),
      onProgressChanged: hasRoute
          ? (value) {
              context.read<SpooferPlaybackBloc>().add(
                const SpooferPlaybackTickClockResetRequested(),
              );
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
    if (!mounted) {
      return;
    }
    final input = await showDialog<String>(
      context: context,
      builder: (context) => RouteInputDialog(
        initialValue: _routeController.text,
        sampleRoute: _samplePolyline,
        detectPolyline: extractPolylineFromInput,
        onDemoFilled: () => _showUiOverlay('Filled demo route.'),
      ),
    );
    if (input == null) {
      return;
    }
    _routeController.text = input;
    _loadRouteFromInput();
  }

  void _clearMockLocation() {
    context.read<SpooferMockBloc>().add(
      const SpooferMockClearLocationRequested(),
    );
  }

  Future<LatLng?> _getRealLocation() async {
    final current = await widget.mockGateway.getCurrentLocation();
    if (current != null) {
      return current;
    }
    return widget.mockGateway.getLastKnownLocation();
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
    if (!mounted) {
      return;
    }
    _stopPlayback();
    context.read<SpooferRouteBloc>().add(const SpooferRouteClearRequested());
    _setMapCurrentPosition(null, updateLastInjected: true);
    _setMapPolylines(const <Polyline>{});
    _refreshMarkers();
  }

  void _appendDebugLog(String message) {
    context.read<SpooferMockBloc>().add(
      SpooferMockDebugLogAppended(message: message),
    );
  }

  void _handleRouteBlocState(SpooferRouteState routeState) {
    final message = routeState.message;
    if (message != null && message.id != _lastRouteMessageId) {
      _lastRouteMessageId = message.id;
      _showUiSnack(message.text);
    }
    if (!routeState.hasRoute &&
        context.read<SpooferPlaybackBloc>().state.isPlaying) {
      _stopPlayback();
    }
    _setMapPolylines(buildRoutePolylines(routeState.routePoints));
    _refreshMarkers(routeState);
    unawaited(_syncBackgroundNotificationVisibility(routeState: routeState));
  }

  void _handleMockBlocState(SpooferMockState mockState) {
    final message = mockState.message;
    if (message != null && message.id != _lastMockMessageId) {
      _lastMockMessageId = message.id;
      _showUiSnack(message.text);
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
      SpooferMockPromptResolved(promptId: prompt.id, accepted: accepted),
    );
  }

  void _handlePlaybackTick(SpooferPlaybackState playbackState) {
    if (!playbackState.isPlaying) {
      return;
    }
    final routeState = context.read<SpooferRouteBloc>().state;
    final resolution = widget.routePlaybackMath.resolvePlaybackTick(
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

  EdgeInsets _mapPaddingForCamera(BuildContext context) {
    return EdgeInsets.zero;
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    if (_lastTitleTapAt == null ||
        now.difference(_lastTitleTapAt!) > const Duration(seconds: 2)) {
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
    await showAppInfoDialog(context: context, packageInfo: info);
  }

  Future<void> _openSearchScreen() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          mockGateway: widget.mockGateway,
          onSelect: (location, zoom) {
            _setManualLocation(location, force: true, zoom: zoom);
          },
          onLog: _appendDebugLog,
        ),
      ),
    );
  }

  Widget _buildDebugPanel(BuildContext context, SpooferMockState mockState) {
    return SpooferDebugPanel(
      lastInjectedPosition: _mapState.lastInjectedPosition,
      status: mockState.lastMockStatus,
      isMockLocationApp: mockState.isMockLocationApp,
      selectedMockApp: mockState.selectedMockApp,
      debugLog: mockState.debugLog,
      onRefreshMockStatus: _refreshMockAppStatus,
    );
  }

  static const FlutterBackgroundAndroidConfig _backgroundConfig =
      FlutterBackgroundAndroidConfig(
        notificationTitle: 'GPS Spoofer',
        notificationText: 'Mock location running in background',
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
      );

  Future<bool> _setBackgroundMode(
    bool enabled, {
    bool showFeedback = true,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (showFeedback) {
        _showUiSnack('Background mode is only supported on Android.');
      }
      return false;
    }

    _settingsBloc.add(
      const SpooferSettingsBackgroundBusySetRequested(value: true),
    );

    try {
      if (enabled) {
        var notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) {
          notificationStatus = await Permission.notification.request();
        }
        if (!notificationStatus.isGranted) {
          _settingsBloc.add(
            const SpooferSettingsBackgroundEnabledSetRequested(value: false),
          );
          if (showFeedback) {
            _showUiSnack(
              'Notification permission is required for background mode.',
            );
          }
          return false;
        }

        final initialized = await FlutterBackground.initialize(
          androidConfig: _backgroundConfig,
        );
        if (!initialized) {
          if (showFeedback) {
            _showUiSnack(
              'Please disable battery optimizations to enable background mode.',
            );
          }
          return false;
        }
        final hasPermissions = await FlutterBackground.hasPermissions;
        if (!hasPermissions) {
          if (showFeedback) {
            _showUiSnack(
              'Background permissions not granted. Disable battery optimizations and retry.',
            );
          }
          return false;
        }
        final success = await FlutterBackground.enableBackgroundExecution();
        if (!success) {
          if (showFeedback) {
            _showUiSnack('Failed to enable background mode.');
          }
          return false;
        }
        _settingsBloc.add(
          const SpooferSettingsBackgroundEnabledSetRequested(value: true),
        );
        unawaited(_syncBackgroundNotificationVisibility());
        if (showFeedback) {
          _showUiSnack(
            'Background mode enabled. Keep playback running to spoof.',
          );
        }
        return true;
      } else {
        await FlutterBackground.disableBackgroundExecution();
        _settingsBloc.add(
          const SpooferSettingsBackgroundEnabledSetRequested(value: false),
        );
        unawaited(_cancelBackgroundNotification());
        return true;
      }
    } catch (error) {
      if (showFeedback) {
        _showUiSnack('Background mode error: $error');
      }
      return false;
    } finally {
      _settingsBloc.add(
        const SpooferSettingsBackgroundBusySetRequested(value: false),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_mapState.pendingFitRoute) {
      _fitRouteToMap();
    }
  }

  bool _shouldUseDarkMapStyle() {
    switch (_settingsState.darkModeSetting) {
      case DarkModeSetting.on:
        return scheduler
                .SchedulerBinding
                .instance
                .platformDispatcher
                .platformBrightness ==
            Brightness.dark;
      case DarkModeSetting.uiOnly:
        return false;
      case DarkModeSetting.mapOnly:
        return true;
      case DarkModeSetting.off:
        return false;
    }
  }

  String? _currentMapStyle() {
    return _shouldUseDarkMapStyle() ? darkMapStyle : null;
  }

  void _applyDarkModeSetting(DarkModeSetting setting) {
    _settingsBloc.add(SpooferSettingsDarkModeSetRequested(value: setting));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRouteFromInput() async {
    final input = _routeController.text.trim();
    if (input.isEmpty) {
      _showUiSnack('Paste an encoded polyline or Routes API JSON.');
      return;
    }

    _stopPlayback();

    final bloc = context.read<SpooferRouteBloc>();
    final previousRevision = bloc.state.revision;
    bloc.add(SpooferRouteLoadRequested(input: input));

    try {
      final nextState = await bloc.stream.firstWhere(
        (state) => state.revision > previousRevision,
      );
      if (!mounted) {
        return;
      }
      if (nextState.hasRoute) {
        final position =
            nextState.currentRoutePosition ?? nextState.routePoints.first;
        _setMapCurrentPosition(position, updateLastInjected: true);
        _refreshMarkers(nextState);
        unawaited(_sendMockLocation(position));
        _fitRouteToMap();
      }
    } on StateError {
      // no-op
    }
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
    context.read<SpooferPlaybackBloc>().add(
      const SpooferPlaybackPlayRequested(),
    );
  }

  void _stopPlayback() {
    if (!context.read<SpooferPlaybackBloc>().state.isPlaying) {
      return;
    }
    context.read<SpooferPlaybackBloc>().add(
      const SpooferPlaybackPauseRequested(),
    );
  }

  void _setProgress(double value) {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (!routeState.hasPoints) {
      return;
    }

    final clamped = _clamp01(value);
    final position =
        widget.routePlaybackMath.positionForProgress(
          points: routeState.routePoints,
          totalDistanceMeters: routeState.totalDistanceMeters,
          progress: clamped,
        ) ??
        routeState.routePoints.first;
    context.read<SpooferRouteBloc>().add(
      SpooferRouteProgressSetRequested(progress: clamped),
    );

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
      final update = zoom == null
          ? CameraUpdate.newLatLng(position)
          : CameraUpdate.newLatLngZoom(position, zoom);
      _mapController!.animateCamera(update);
      return;
    }
    _followCamera(position);
  }

  void _refreshMarkers([SpooferRouteState? routeState]) {
    final state = routeState ?? context.read<SpooferRouteBloc>().state;
    _setMapMarkers(
      buildRouteMarkers(
        routeState: state,
        currentPosition: _mapState.currentPosition,
        showMockMarker: _settingsState.showMockMarker,
        onWaypointTap: _selectCustomPoint,
        onWaypointDragEnd: (index, position) {
          context.read<SpooferRouteBloc>().add(
            SpooferRouteWaypointUpdatedRequested(
              index: index,
              position: position,
            ),
          );
          _selectCustomPoint(index);
        },
      ),
    );
  }

  void _addCustomPoint(LatLng position) {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (routeState.hasPoints && !routeState.usingCustomRoute) {
      _showUiSnack('Clear the loaded route to edit a custom route.');
      return;
    }
    context.read<SpooferRouteBloc>().add(
      SpooferRouteWaypointAddedRequested(position: position),
    );
    if (context.read<SpooferRouteBloc>().state.hasPoints) {
      _setProgress(0);
    }
    _followCamera(position);
  }

  void _removeCustomPoint(int index) {
    context.read<SpooferRouteBloc>().add(
      SpooferRouteWaypointRemovedRequested(index: index),
    );
    if (context.read<SpooferRouteBloc>().state.hasPoints) {
      _setProgress(0);
    }
  }

  void _selectCustomPoint(int index) {
    context.read<SpooferRouteBloc>().add(
      SpooferRouteWaypointSelectedRequested(index: index),
    );
  }

  Future<void> _saveCustomRoute() async {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (routeState.waypointPoints.isEmpty) {
      _showUiSnack('No custom route to save.');
      return;
    }
    final suggested =
        'Custom route ${DateTime.now().toLocal().toString().substring(0, 16)}';
    final name = await showSaveRouteDialog(
      context: context,
      suggestedName: suggested,
    );
    if (!mounted || name == null) {
      return;
    }
    final trimmed = name.isEmpty ? suggested : name;
    context.read<SpooferRouteBloc>().add(
      SpooferRouteSavedRouteSaveRequested(name: trimmed),
    );
  }

  Future<bool> _openSavedRoutes() async {
    final bloc = context.read<SpooferRouteBloc>();
    final previousRevision = bloc.state.revision;
    bloc.add(const SpooferRouteSavedRoutesLoadRequested());
    final loadedState = await bloc.stream.firstWhere(
      (state) => state.revision > previousRevision,
    );
    if (!mounted) {
      return false;
    }
    final routes = List.of(loadedState.savedRoutes);

    if (routes.isEmpty) {
      _showUiSnack('No saved routes yet.');
      return false;
    }
    return showSavedRoutesSheet(
      context: context,
      routes: routes,
      onApply: (index) {
        bloc.add(SpooferRouteSavedRouteApplyRequested(index: index));
      },
      onDelete: (index) async {
        bloc.add(SpooferRouteSavedRouteDeleteRequested(index: index));
        routes.removeAt(index);
        return routes;
      },
    );
  }

  void _reorderCustomPoints(int oldIndex, int newIndex) {
    context.read<SpooferRouteBloc>().add(
      SpooferRouteWaypointsReorderedRequested(
        oldIndex: oldIndex,
        newIndex: newIndex,
      ),
    );
    if (context.read<SpooferRouteBloc>().state.hasPoints) {
      _setProgress(0);
    }
  }

  Future<void> _renameCustomPoint(int index) async {
    final routeState = context.read<SpooferRouteBloc>().state;
    if (index < 0 || index >= routeState.waypointPoints.length) {
      return;
    }
    final currentName = routeState.waypointNames[index];
    final result = await showRenameWaypointDialog(
      context: context,
      currentName: currentName,
    );
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
    await showWaypointListSheet(
      context: context,
      onSaveRoute: _saveCustomRoute,
      onLoadRoute: _openSavedRoutes,
      onReorder: _reorderCustomPoints,
      onSelect: _selectCustomPoint,
      onRename: _renameCustomPoint,
      onDelete: _removeCustomPoint,
      defaultWaypointName: defaultWaypointName,
    );
  }

  void _followCamera(LatLng position) {
    if (_mapController == null ||
        !_mapState.autoFollowEnabled ||
        _userInteracting) {
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
      _mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(routeState.routePoints.first, 16),
      );
      return;
    }

    final bounds = boundsFromLatLngs(routeState.routePoints);
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
        content: Text(
          message,
          style: TextStyle(color: colors.onInverseSurface),
        ),
        backgroundColor: colors.inverseSurface.withValues(alpha: 0.92),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.inverseSurface.withValues(alpha: 0.92),
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

    final accepted = await widget.preferencesStore.isTosAccepted();
    if (accepted) {
      _tosAccepted = true;
      return true;
    }

    if (!mounted) {
      return false;
    }

    await showTermsOfUseDialog(
      context: context,
      onAgree: () => widget.preferencesStore.setTosAccepted(true),
    );

    _tosAccepted = await widget.preferencesStore.isTosAccepted();
    return _tosAccepted;
  }

  void _requestStartupChecks({required bool showDialogs}) {
    context.read<SpooferMockBloc>().add(
      SpooferMockStartupChecksRequested(showDialogs: showDialogs),
    );
  }

  void _refreshMockAppStatus() {
    context.read<SpooferMockBloc>().add(
      const SpooferMockRefreshStatusRequested(),
    );
  }

  Future<void> _disableMockLocationAndRecenter() async {
    _clearMockLocation();
    await Future.delayed(const Duration(milliseconds: 400));
    var location = await _getRealLocation();
    if (location == null) {
      await Future.delayed(const Duration(milliseconds: 600));
      location = await _getRealLocation();
    }
    if (location == null) {
      _showUiSnack('Real location not available yet.');
      return;
    }
    _setMapCurrentPosition(location);
    _setMapLastInjectedPosition(null);
    _setMapAutoFollow(true);
    _refreshMarkers();
    _followCamera(location);
  }

  Future<void> _openSettingsSheet() async {
    if (!mounted) {
      return;
    }
    await showSpooferSettingsSideSheet(
      context: context,
      initialSettings: _settingsState,
      onShowSetupBarChanged: (value) {
        _settingsBloc.add(
          SpooferSettingsShowSetupBarSetRequested(value: value),
        );
      },
      onShowDebugPanelChanged: (value) {
        _settingsBloc.add(
          SpooferSettingsShowDebugPanelSetRequested(value: value),
        );
      },
      onShowMockMarkerChanged: (value) {
        _settingsBloc.add(
          SpooferSettingsShowMockMarkerSetRequested(value: value),
        );
        _refreshMarkers();
      },
      onDarkModeChanged: _applyDarkModeSetting,
      onDisableMockLocation: _disableMockLocationAndRecenter,
      onOpenPrivacyPolicy: _openPrivacyPolicy,
      onRunSetupChecks: () => _requestStartupChecks(showDialogs: true),
      debugPanelBuilder: (context) {
        return _buildDebugPanel(
          context,
          context.watch<SpooferMockBloc>().state,
        );
      },
    );
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      await widget.mockGateway.openExternalUrl(_privacyPolicyUrl);
    } on PlatformException {
      _showUiSnack('Failed to open privacy policy.');
    }
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

  Future<bool> _confirmDialog(
    String title,
    String message,
    String actionLabel,
  ) async {
    return showSpooferConfirmDialog(
      context: context,
      title: title,
      message: message,
      actionLabel: actionLabel,
    );
  }
}
