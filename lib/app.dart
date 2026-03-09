import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/map/spoofer_map_bloc.dart';
import 'bloc/map/spoofer_map_event.dart';
import 'bloc/message/spoofer_message_bloc.dart';
import 'bloc/mock/spoofer_mock_bloc.dart';
import 'bloc/mock/spoofer_mock_event.dart';
import 'bloc/playback/spoofer_playback_bloc.dart';
import 'bloc/playback/spoofer_playback_event.dart';
import 'bloc/route/spoofer_route_bloc.dart';
import 'bloc/route/spoofer_route_event.dart';
import 'bloc/settings/spoofer_settings_bloc.dart';
import 'bloc/settings/spoofer_settings_state.dart';
import 'service/route_playback_math.dart';
import 'infrastructure/mock_location_gateway.dart';
import 'infrastructure/preferences_store.dart';
import 'ui/screens/spoofer_screen.dart';

class GpsSpooferAppDependencies {
  const GpsSpooferAppDependencies({
    this.mockGateway,
    this.preferencesStore,
    this.routePlaybackMath,
    this.playbackTickInterval,
    this.requestLocationPermission,
    this.openAppSettingsAction,
  });

  final MockLocationGateway? mockGateway;
  final PreferencesStore? preferencesStore;
  final RoutePlaybackMath? routePlaybackMath;
  final Duration? playbackTickInterval;
  final RequestLocationPermission? requestLocationPermission;
  final OpenAppSettingsAction? openAppSettingsAction;
}

class GpsSpooferApp extends StatelessWidget {
  const GpsSpooferApp({
    super.key,
    this.dependencies,
    this.screenLaunchOptions = const SpooferScreenLaunchOptions(),
  });

  final GpsSpooferAppDependencies? dependencies;
  final SpooferScreenLaunchOptions screenLaunchOptions;

  @override
  Widget build(BuildContext context) {
    final appDependencies = dependencies;
    final mockGateway = appDependencies?.mockGateway ?? mockLocationGateway;
    final preferencesStore =
        appDependencies?.preferencesStore ?? PreferencesStore();
    final routePlaybackMath =
        appDependencies?.routePlaybackMath ?? const RoutePlaybackMath();
    final playbackTickInterval =
        appDependencies?.playbackTickInterval ??
        const Duration(milliseconds: 50);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SpooferRouteBloc>(
          create: (_) => SpooferRouteBloc(
            preferencesStore: preferencesStore,
            routePlaybackMath: routePlaybackMath,
          )..add(const SpooferRouteInitialized()),
        ),
        BlocProvider<SpooferPlaybackBloc>(
          create: (_) =>
              SpooferPlaybackBloc(tickInterval: playbackTickInterval)
                ..add(const SpooferPlaybackInitialized()),
        ),
        BlocProvider<SpooferMockBloc>(
          create: (_) => SpooferMockBloc(
            mockGateway: mockGateway,
            requestLocationPermission:
                appDependencies?.requestLocationPermission,
            openAppSettingsAction: appDependencies?.openAppSettingsAction,
          )..add(const SpooferMockInitialized()),
        ),
        BlocProvider<SpooferMapBloc>(
          create: (_) => SpooferMapBloc()..add(const SpooferMapInitialized()),
        ),
        BlocProvider<SpooferMessageBloc>(create: (_) => SpooferMessageBloc()),
        BlocProvider<SpooferSettingsBloc>(create: (_) => SpooferSettingsBloc()),
      ],
      child: BlocBuilder<SpooferSettingsBloc, SpooferSettingsState>(
        buildWhen: (previous, current) =>
            previous.darkModeSetting != current.darkModeSetting,
        builder: (context, settingsState) {
          final themeMode = switch (settingsState.darkModeSetting) {
            DarkModeSetting.on => ThemeMode.system,
            DarkModeSetting.uiOnly => ThemeMode.dark,
            DarkModeSetting.mapOnly => ThemeMode.light,
            DarkModeSetting.off => ThemeMode.light,
          };
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
            themeMode: themeMode,
            home: SpooferScreen(
              mockGateway: mockGateway,
              preferencesStore: preferencesStore,
              routePlaybackMath: routePlaybackMath,
              launchOptions: screenLaunchOptions,
            ),
          );
        },
      ),
    );
  }
}
