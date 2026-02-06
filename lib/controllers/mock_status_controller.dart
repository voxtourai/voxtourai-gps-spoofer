import 'package:flutter/foundation.dart';

class MockStatusController extends ChangeNotifier {
  bool? _hasLocationPermission;
  bool? _isDeveloperModeEnabled;
  bool? _isMockLocationApp;
  Map<String, Object?>? _lastMockStatus;
  String? _selectedMockApp;
  String? _mockError;
  DateTime? _lastMockErrorAt;
  final List<String> _debugLog = [];
  String? _lastDebugMessage;
  DateTime? _lastDebugAt;

  bool? get hasLocationPermission => _hasLocationPermission;
  bool? get isDeveloperModeEnabled => _isDeveloperModeEnabled;
  bool? get isMockLocationApp => _isMockLocationApp;
  Map<String, Object?>? get lastMockStatus => _lastMockStatus;
  String? get selectedMockApp => _selectedMockApp;
  String? get mockError => _mockError;
  List<String> get debugLog => List.unmodifiable(_debugLog);

  void setLocationPermission(bool? value) {
    if (_hasLocationPermission == value) {
      return;
    }
    _hasLocationPermission = value;
    notifyListeners();
  }

  void setDeveloperModeEnabled(bool? value) {
    if (_isDeveloperModeEnabled == value) {
      return;
    }
    _isDeveloperModeEnabled = value;
    notifyListeners();
  }

  void setMockLocationApp(bool? value) {
    if (_isMockLocationApp == value) {
      return;
    }
    _isMockLocationApp = value;
    notifyListeners();
  }

  void setLastMockStatus(Map<String, Object?>? value) {
    _lastMockStatus = value;
    notifyListeners();
  }

  void setSelectedMockApp(String? value) {
    if (_selectedMockApp == value) {
      return;
    }
    _selectedMockApp = value;
    notifyListeners();
  }

  void setMockError(String? value) {
    if (_mockError == value) {
      return;
    }
    _mockError = value;
    notifyListeners();
  }

  void clearMockError() => setMockError(null);

  bool shouldReportMockError(Duration interval) {
    final now = DateTime.now();
    if (_lastMockErrorAt == null || now.difference(_lastMockErrorAt!) > interval) {
      _lastMockErrorAt = now;
      return true;
    }
    return false;
  }

  void appendDebugLog(String message) {
    final now = DateTime.now();
    if (_lastDebugMessage == message &&
        _lastDebugAt != null &&
        now.difference(_lastDebugAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastDebugMessage = message;
    _lastDebugAt = now;
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final entry = '[$stamp] $message';
    _debugLog.add(entry);
    if (_debugLog.length > 50) {
      _debugLog.removeRange(0, _debugLog.length - 50);
    }
    notifyListeners();
  }
}
