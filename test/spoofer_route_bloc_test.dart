import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voxtourai_gps_spoofer/bloc/route/spoofer_route_bloc.dart';
import 'package:voxtourai_gps_spoofer/bloc/route/spoofer_route_event.dart';
import 'package:voxtourai_gps_spoofer/bloc/route/spoofer_route_state.dart';
import 'package:voxtourai_gps_spoofer/infrastructure/preferences_store.dart';
import 'package:voxtourai_gps_spoofer/model/saved_route.dart';

const String _samplePolyline =
    'kenpGym~}@IsJo@Cm@Qm@_@e@i@Wa@EMYV?BWyC?EzFmA@?^u@nAcEpA_FD?CAAKDSF?^gBD@DU@?@I@?D[NHB@`@cB@?y@m@m@e@AQCC@??Pj@b@DDd@uBDAHFFEDF?DTRJFz@gD@?QIJoB@?yBe@vBd@@?HcB@?zBXFAB@@c@?e@RuCD??[@?VD@@YGDq@?IB?HK@?AOPqA@?b@gC@?Xo@@?X}@@?z@uC@?nFfBlARBBVgC^iCB?o@hEa@pE?DgAdK_A|G?BgA_@MxA?BA?';
const String _sampleRoutesJson =
    '{"routes":[{"polyline":{"encodedPolyline":"$_samplePolyline"}}]}';

void main() {
  group('SpooferRouteBloc', () {
    late _InMemoryPreferencesStore store;

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'initializes when requested',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) => bloc.add(const SpooferRouteInitialized()),
      expect: () => [
        isA<SpooferRouteState>().having(
          (s) => s.initialized,
          'initialized',
          true,
        ),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'loads encoded polyline into route points',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) =>
          bloc.add(const SpooferRouteLoadRequested(input: _samplePolyline)),
      expect: () => [
        isA<SpooferRouteState>()
            .having((s) => s.hasRoute, 'hasRoute', true)
            .having((s) => s.progress, 'progress', 0.0)
            .having((s) => s.routePoints.length, 'routePoints', greaterThan(2)),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'loads Routes API JSON into route points',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) =>
          bloc.add(const SpooferRouteLoadRequested(input: _sampleRoutesJson)),
      expect: () => [
        isA<SpooferRouteState>()
            .having((s) => s.hasRoute, 'hasRoute', true)
            .having((s) => s.routePoints.length, 'routePoints', greaterThan(2)),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'surfaces invalid polyline input as message',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) =>
          bloc.add(const SpooferRouteLoadRequested(input: '{"routes": []}')),
      expect: () => [
        isA<SpooferRouteState>().having(
          (s) => s.message?.text,
          'message',
          'Invalid polyline: input is incomplete or malformed.',
        ),
      ],
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'clamps progress updates to the route end',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) {
        bloc
          ..add(const SpooferRouteLoadRequested(input: _samplePolyline))
          ..add(const SpooferRouteProgressSetRequested(progress: 2.0));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.progress, 1.0);
        expect(bloc.state.currentRoutePosition, bloc.state.routePoints.last);
      },
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'clear resets both route and custom waypoint state',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) {
        bloc
          ..add(
            const SpooferRouteWaypointAddedRequested(
              position: LatLng(43.6532, -79.3832),
            ),
          )
          ..add(
            const SpooferRouteWaypointAddedRequested(
              position: LatLng(43.7001, -79.4163),
            ),
          )
          ..add(const SpooferRouteWaypointSelectedRequested(index: 1))
          ..add(const SpooferRouteClearRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.hasPoints, false);
        expect(bloc.state.hasWaypointPoints, false);
        expect(bloc.state.usingCustomRoute, false);
        expect(bloc.state.selectedWaypointIndex, isNull);
      },
    );

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'creates custom route, saves it, and reapplies saved route',
      build: () =>
          SpooferRouteBloc(preferencesStore: _InMemoryPreferencesStore()),
      act: (bloc) async {
        bloc
          ..add(
            const SpooferRouteWaypointAddedRequested(
              position: LatLng(43.6532, -79.3832),
            ),
          )
          ..add(
            const SpooferRouteWaypointAddedRequested(
              position: LatLng(43.7001, -79.4163),
            ),
          )
          ..add(
            const SpooferRouteSavedRouteSaveRequested(name: 'Downtown test'),
          )
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

    blocTest<SpooferRouteBloc, SpooferRouteState>(
      'deletes saved routes from state and persistence',
      build: () => SpooferRouteBloc(
        preferencesStore: store = _InMemoryPreferencesStore(),
      ),
      act: (bloc) async {
        bloc
          ..add(
            const SpooferRouteWaypointAddedRequested(
              position: LatLng(43.6532, -79.3832),
            ),
          )
          ..add(
            const SpooferRouteWaypointAddedRequested(
              position: LatLng(43.7001, -79.4163),
            ),
          )
          ..add(const SpooferRouteSavedRouteSaveRequested(name: 'Delete me'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const SpooferRouteSavedRouteDeleteRequested(index: 0));
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.state.savedRoutes, isEmpty);
        expect(store.savedRouteNames, isEmpty);
      },
    );
  });
}

class _InMemoryPreferencesStore extends PreferencesStore {
  bool _tosAccepted = false;
  List<SavedRoute> _routes = const <SavedRoute>[];

  List<String> get savedRouteNames =>
      _routes.map((route) => route.name).toList();

  @override
  Future<bool> isTosAccepted() async => _tosAccepted;

  @override
  Future<void> setTosAccepted(bool accepted) async {
    _tosAccepted = accepted;
  }

  @override
  Future<List<SavedRoute>> loadSavedRoutes() async {
    return _routes.map((route) => SavedRoute.fromJson(route.toJson())).toList();
  }

  @override
  Future<void> saveRoutes(List<SavedRoute> routes) async {
    _routes = routes
        .map((route) => SavedRoute.fromJson(route.toJson()))
        .toList();
  }

  @override
  Future<void> upsertSavedRoute({
    required String name,
    required List<LatLng> points,
    required List<String> names,
  }) async {
    final routes = await loadSavedRoutes();
    final entry = SavedRoute(
      name: name,
      points: List<LatLng>.unmodifiable(points),
      waypointNames: List<String>.unmodifiable(names),
    );
    final index = routes.indexWhere((route) => route.name == name);
    if (index >= 0) {
      routes[index] = entry;
    } else {
      routes.add(entry);
    }
    await saveRoutes(routes);
  }
}
