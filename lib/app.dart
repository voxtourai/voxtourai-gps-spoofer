import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'controllers/mock_location_controller.dart';
import 'controllers/theme_controller.dart';
import 'spoofer/bloc/map/spoofer_map_bloc.dart';
import 'spoofer/bloc/map/spoofer_map_event.dart';
import 'spoofer/bloc/message/spoofer_message_cubit.dart';
import 'spoofer/bloc/mock/spoofer_mock_bloc.dart';
import 'spoofer/bloc/mock/spoofer_mock_event.dart';
import 'spoofer/bloc/playback/spoofer_playback_bloc.dart';
import 'spoofer/bloc/playback/spoofer_playback_event.dart';
import 'spoofer/bloc/route/spoofer_route_bloc.dart';
import 'spoofer/bloc/route/spoofer_route_event.dart';
import 'spoofer/bloc/settings/spoofer_settings_cubit.dart';
import 'ui/screens/spoofer_screen.dart';

class GpsSpooferApp extends StatelessWidget {
  const GpsSpooferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.mode,
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
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SpooferRouteBloc>(
                create: (_) => SpooferRouteBloc()..add(const SpooferRouteInitialized()),
              ),
              BlocProvider<SpooferPlaybackBloc>(
                create: (_) => SpooferPlaybackBloc()..add(const SpooferPlaybackInitialized()),
              ),
              BlocProvider<SpooferMockBloc>(
                create: (_) => SpooferMockBloc(
                  mockController: mockLocationController,
                )..add(const SpooferMockInitialized()),
              ),
              BlocProvider<SpooferMapBloc>(
                create: (_) => SpooferMapBloc()..add(const SpooferMapInitialized()),
              ),
              BlocProvider<SpooferMessageCubit>(
                create: (_) => SpooferMessageCubit(),
              ),
              BlocProvider<SpooferSettingsCubit>(
                create: (_) => SpooferSettingsCubit(),
              ),
            ],
            child: SpooferScreen(mockController: mockLocationController),
          ),
        );
      },
    );
  }
}
