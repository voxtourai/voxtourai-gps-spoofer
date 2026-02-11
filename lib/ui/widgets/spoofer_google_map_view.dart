import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SpooferGoogleMapView extends StatelessWidget {
  const SpooferGoogleMapView({
    super.key,
    required this.hasLocationPermission,
    required this.currentPosition,
    required this.mapStyle,
    required this.markers,
    required this.polylines,
    required this.padding,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
    required this.onMapCreated,
    required this.onCameraMoveStarted,
    required this.onCameraMove,
    required this.onCameraIdle,
    required this.onTap,
    required this.onLongPress,
  });

  final bool hasLocationPermission;
  final LatLng? currentPosition;
  final String? mapStyle;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final EdgeInsets padding;
  final PointerDownEventListener onPointerDown;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final void Function(GoogleMapController controller) onMapCreated;
  final VoidCallback onCameraMoveStarted;
  final void Function(CameraPosition position) onCameraMove;
  final VoidCallback onCameraIdle;
  final void Function(LatLng position) onTap;
  final void Function(LatLng position) onLongPress;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: GoogleMap(
        key: ValueKey('map-${hasLocationPermission ? 'loc-on' : 'loc-off'}'),
        initialCameraPosition: CameraPosition(
          target: currentPosition ?? const LatLng(0, 0),
          zoom: currentPosition == null ? 2 : 16,
        ),
        onMapCreated: onMapCreated,
        onCameraMoveStarted: onCameraMoveStarted,
        onCameraMove: onCameraMove,
        onCameraIdle: onCameraIdle,
        onTap: onTap,
        onLongPress: onLongPress,
        style: mapStyle,
        markers: markers,
        polylines: polylines,
        mapToolbarEnabled: false,
        padding: padding,
        myLocationEnabled: hasLocationPermission,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}
