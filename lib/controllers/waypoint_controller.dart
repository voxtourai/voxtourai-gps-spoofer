import 'package:google_maps_flutter/google_maps_flutter.dart';

class WaypointController {
  final List<LatLng> points = [];
  final List<String> names = [];
  int? selectedIndex;
  bool usingCustomRoute = false;

  bool get hasPoints => points.isNotEmpty;

  void clear() {
    points.clear();
    names.clear();
    selectedIndex = null;
    usingCustomRoute = false;
  }
}
