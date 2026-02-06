import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WaypointController extends ChangeNotifier {
  final List<LatLng> _points = [];
  final List<String> _names = [];
  int? _selectedIndex;
  bool _usingCustomRoute = false;

  List<LatLng> get points => List.unmodifiable(_points);
  List<String> get names => List.unmodifiable(_names);
  int? get selectedIndex => _selectedIndex;
  bool get usingCustomRoute => _usingCustomRoute;
  bool get hasPoints => _points.isNotEmpty;

  String defaultName(int index) => 'Waypoint ${index + 1}';

  void clear() {
    _points.clear();
    _names.clear();
    _selectedIndex = null;
    _usingCustomRoute = false;
    notifyListeners();
  }

  void setSelectedIndex(int? value) {
    if (_selectedIndex == value) {
      return;
    }
    _selectedIndex = value;
    notifyListeners();
  }

  void setUsingCustomRoute(bool value) {
    if (_usingCustomRoute == value) {
      return;
    }
    _usingCustomRoute = value;
    notifyListeners();
  }

  void addPoint(LatLng position) {
    _usingCustomRoute = true;
    _points.add(position);
    _names.add(defaultName(_points.length - 1));
    notifyListeners();
  }

  void updatePoint(int index, LatLng position) {
    if (index < 0 || index >= _points.length) {
      return;
    }
    _points[index] = position;
    notifyListeners();
  }

  void removePoint(int index) {
    if (index < 0 || index >= _points.length) {
      return;
    }
    _points.removeAt(index);
    _names.removeAt(index);
    if (_points.isEmpty) {
      _usingCustomRoute = false;
      _names.clear();
    }
    if (_selectedIndex == index) {
      _selectedIndex = null;
    }
    _normalizeDefaultNames();
    notifyListeners();
  }

  void renamePoint(int index, String name) {
    if (index < 0 || index >= _names.length) {
      return;
    }
    _names[index] = name;
    notifyListeners();
  }

  void setFromSaved(List<LatLng> points, List<String> names) {
    _usingCustomRoute = true;
    _points
      ..clear()
      ..addAll(points);
    _names
      ..clear()
      ..addAll(
        names.length == points.length ? names : List.generate(points.length, defaultName),
      );
    _selectedIndex = null;
    notifyListeners();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _points.length) {
      return;
    }
    if (newIndex < 0 || newIndex > _points.length) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex == oldIndex) {
      return;
    }
    final point = _points.removeAt(oldIndex);
    final name = _names.removeAt(oldIndex);
    _points.insert(newIndex, point);
    _names.insert(newIndex, name);

    if (_selectedIndex != null) {
      final selected = _selectedIndex!;
      if (selected == oldIndex) {
        _selectedIndex = newIndex;
      } else if (oldIndex < selected && newIndex >= selected) {
        _selectedIndex = selected - 1;
      } else if (oldIndex > selected && newIndex <= selected) {
        _selectedIndex = selected + 1;
      }
    }
    _normalizeDefaultNames();
    notifyListeners();
  }

  void _normalizeDefaultNames() {
    for (var i = 0; i < _names.length; i++) {
      if (RegExp(r'^Waypoint\\s+\\d+$').hasMatch(_names[i])) {
        _names[i] = defaultName(i);
      }
    }
  }
}
