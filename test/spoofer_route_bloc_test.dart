import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voxtourai_gps_spoofer/controllers/preferences_controller.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/route/spoofer_route_bloc.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/route/spoofer_route_event.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/route/spoofer_route_state.dart';

const String _samplePolyline =
    'kenpGym~}@IsJo@Cm@Qm@_@e@i@Wa@EMYV?BWyC?EzFmA@?^u@nAcEpA_FD?CAAKDSF?^gBD@DU@?@I@?D[NHB@`@cB@?y@m@m@e@AQCC@??Pj@b@DDd@uBDAHFFEDF?DTRJFz@gD@?QIJoB@?yBe@vBd@@?HcB@?zBXFAB@@c@?e@RuCD??[@?VD@@YGDq@?IB?HK@?AOPqA@?b@gC@?Xo@@?X}@@?z@uC@?nFfBlARBBVgC^iCB?o@hEa@pE?DgAdK_A|G?BgA_@MxA?BA?';

void main() {
  group('SpooferRouteBloc', () {
    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'initializes when requested',
      build: () => SpooferRouteBloc(
        preferencesController: _InMemoryPreferencesController(),
      ),
      act: (bloc) => bloc.add(const SpooferRouteInitialized()),
      expect: () => [
        isA<SpooferRouteState>().having((s) => s.initialized, 'initialized', true),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'loads encoded polyline into route points',
      build: () => SpooferRouteBloc(
        preferencesController: _InMemoryPreferencesController(),
      ),
      act: (bloc) => bloc.add(const SpooferRouteLoadRequested(input: _samplePolyline)),
      expect: () => [
        isA<SpooferRouteState>()
            .having((s) => s.hasRoute, 'hasRoute', true)
            .having((s) => s.progress, 'progress', 0.0)
            .having((s) => s.routePoints.length, 'routePoints', greaterThan(2)),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'surfaces invalid polyline input as message',
      build: () => SpooferRouteBloc(
        preferencesController: _InMemoryPreferencesController(),
      ),
      act: (bloc) => bloc.add(const SpooferRouteLoadRequested(input: '{"routes": []}')),
      expect: () => [
        isA<SpooferRouteState>().having(
          (s) => s.message?.text,
          'message',
          'Invalid polyline: input is incomplete or malformed.',
        ),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'creates custom route, saves it, and reapplies saved route',
      build: () => SpooferRouteBloc(
        preferencesController: _InMemoryPreferencesController(),
      ),
      act: (bloc) async {
        bloc
          ..add(const SpooferRouteWaypointAddedRequested(position: LatLng(43.6532, -79.3832)))
          ..add(const SpooferRouteWaypointAddedRequested(position: LatLng(43.7001, -79.4163)))
          ..add(const SpooferRouteSavedRouteSaveRequested(name: 'Downtown test'))
          ..add(const SpooferRouteClearRequested())
          ..add(const SpooferRouteSavedRoutesLoadRequested())
          ..add(const SpooferRouteSavedRouteApplyRequested(index: 0));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.hasRoute, true);
        expect(bloc.state.usingCustomRoute, true);
        expect(bloc.state.waypointPoints.length, 2);
        expect(bloc.state.savedRoutes, isNotEmpty);
      },
    );
  });
}

class _InMemoryPreferencesController extends PreferencesController {
  bool _tosAccepted = false;
  List<Map<String, Object?>> _routes = const <Map<String, Object?>>[];

  @override
  Future<bool> isTosAccepted() async => _tosAccepted;

  @override
  Future<void> setTosAccepted(bool accepted) async {
    _tosAccepted = accepted;
  }

  @override
  Future<List<Map<String, Object?>>> loadSavedRoutes() async {
    return _routes.map(_copyRoute).toList();
  }

  @override
  Future<void> saveRoutes(List<Map<String, Object?>> routes) async {
    _routes = routes.map(_copyRoute).toList();
  }

  @override
  Future<void> upsertSavedRoute({
    required String name,
    required List<LatLng> points,
    required List<String> names,
  }) async {
    final routes = await loadSavedRoutes();
    final entry = <String, Object?>{
      'name': name,
      'points': <Map<String, double>>[
        for (final p in points)
          <String, double>{
            'lat': p.latitude,
            'lng': p.longitude,
          },
      ],
      'names': List<String>.from(names),
    };
    final index = routes.indexWhere((e) => e['name'] == name);
    if (index >= 0) {
      routes[index] = entry;
    } else {
      routes.add(entry);
    }
    await saveRoutes(routes);
  }

  static Map<String, Object?> _copyRoute(Map<String, Object?> input) {
    final points = (input['points'] as List?)
            ?.map(
              (e) => e is Map
                  ? <String, Object?>{
                      'lat': e['lat'],
                      'lng': e['lng'],
                    }
                  : <String, Object?>{},
            )
            .toList() ??
        <Map<String, Object?>>[];
    final names = (input['names'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    return <String, Object?>{
      'name': input['name']?.toString() ?? '',
      'points': points,
      'names': names,
    };
  }
}
