import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapStateController extends ChangeNotifier {
  LatLng? _currentPosition;
  LatLng? _lastInjectedPosition;
  Set<Polyline> _polylines = const {};
  Set<Marker> _markers = const {};
  Set<Marker> _customMarkers = const {};
  bool _autoFollow = true;
  bool _pendingFitRoute = false;
  bool _isProgrammaticMove = false;
  bool? _lastMapStyleDark;

  LatLng? get currentPosition => _currentPosition;
  LatLng? get lastInjectedPosition => _lastInjectedPosition;
  Set<Polyline> get polylines => _polylines;
  Set<Marker> get markers => _markers;
  Set<Marker> get customMarkers => _customMarkers;
  bool get autoFollow => _autoFollow;
  bool get pendingFitRoute => _pendingFitRoute;
  bool get isProgrammaticMove => _isProgrammaticMove;
  bool? get lastMapStyleDark => _lastMapStyleDark;

  void setCurrentPosition(LatLng? value, {bool updateLastInjected = false}) {
    if (_currentPosition == value && (!updateLastInjected || _lastInjectedPosition == value)) {
      return;
    }
    _currentPosition = value;
    if (updateLastInjected) {
      _lastInjectedPosition = value;
    }
    notifyListeners();
  }

  void setLastInjectedPosition(LatLng? value) {
    if (_lastInjectedPosition == value) {
      return;
    }
    _lastInjectedPosition = value;
    notifyListeners();
  }

  void setPolylines(Set<Polyline> value) {
    if (setEquals(_polylines, value)) {
      return;
    }
    _polylines = value;
    notifyListeners();
  }

  void setMarkers(Set<Marker> value) {
    if (setEquals(_markers, value)) {
      return;
    }
    _markers = value;
    notifyListeners();
  }

  void setCustomMarkers(Set<Marker> value) {
    if (setEquals(_customMarkers, value)) {
      return;
    }
    _customMarkers = value;
    notifyListeners();
  }

  void setAutoFollow(bool value) {
    if (_autoFollow == value) {
      return;
    }
    _autoFollow = value;
    notifyListeners();
  }

  void setPendingFitRoute(bool value) {
    if (_pendingFitRoute == value) {
      return;
    }
    _pendingFitRoute = value;
    notifyListeners();
  }

  void setProgrammaticMove(bool value) {
    if (_isProgrammaticMove == value) {
      return;
    }
    _isProgrammaticMove = value;
    notifyListeners();
  }

  void setLastMapStyleDark(bool? value) {
    if (_lastMapStyleDark == value) {
      return;
    }
    _lastMapStyleDark = value;
    notifyListeners();
  }

  void clearRouteState() {
    _polylines = const {};
    _customMarkers = const {};
    _markers = const {};
    _currentPosition = null;
    _lastInjectedPosition = null;
    notifyListeners();
  }
}
