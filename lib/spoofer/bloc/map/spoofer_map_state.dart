import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'spoofer_map_state.g.dart';

@immutable
@CopyWith()
class SpooferMapState {
  const SpooferMapState({
    this.initialized = false,
    this.currentPosition,
    this.lastInjectedPosition,
    this.polylines = const <Polyline>{},
    this.markers = const <Marker>{},
    this.autoFollowEnabled = true,
    this.pendingFitRoute = false,
    this.isProgrammaticMove = false,
    this.lastMapStyleDark,
  });

  final bool initialized;
  final LatLng? currentPosition;
  final LatLng? lastInjectedPosition;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final bool autoFollowEnabled;
  final bool pendingFitRoute;
  final bool isProgrammaticMove;
  final bool? lastMapStyleDark;
}
