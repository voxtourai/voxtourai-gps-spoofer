import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/map/spoofer_map_bloc.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/map/spoofer_map_event.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/map/spoofer_map_state.dart';

void main() {
  group('SpooferMapBloc', () {
    blocTest<SpooferMapBloc, SpooferMapState>(
      'sets current position and auto-updates last injected when requested',
      build: () => SpooferMapBloc(),
      act: (bloc) => bloc.add(
        const SpooferMapCurrentPositionSetRequested(
          position: LatLng(43.6532, -79.3832),
          updateLastInjected: true,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.currentPosition, const LatLng(43.6532, -79.3832));
        expect(bloc.state.lastInjectedPosition, const LatLng(43.6532, -79.3832));
      },
    );

    blocTest<SpooferMapBloc, SpooferMapState>(
      'updates follow and programmatic move flags',
      build: () => SpooferMapBloc(),
      act: (bloc) {
        bloc
          ..add(const SpooferMapAutoFollowSetRequested(value: false))
          ..add(const SpooferMapProgrammaticMoveSetRequested(value: true));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.autoFollowEnabled, false);
        expect(bloc.state.isProgrammaticMove, true);
      },
    );

    blocTest<SpooferMapBloc, SpooferMapState>(
      'sets markers and polylines',
      build: () => SpooferMapBloc(),
      act: (bloc) {
        bloc
          ..add(
            SpooferMapMarkersSetRequested(
              markers: <Marker>{
                const Marker(
                  markerId: MarkerId('current'),
                  position: LatLng(40.0, -73.0),
                ),
              },
            ),
          )
          ..add(
            SpooferMapPolylinesSetRequested(
              polylines: <Polyline>{
                const Polyline(
                  polylineId: PolylineId('route'),
                  points: <LatLng>[
                    LatLng(40.0, -73.0),
                    LatLng(40.1, -73.1),
                  ],
                ),
              },
            ),
          );
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.markers.length, 1);
        expect(bloc.state.polylines.length, 1);
      },
    );
  });
}
