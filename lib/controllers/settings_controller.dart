import 'package:flutter/foundation.dart';

enum DarkModeSetting {
  on,
  uiOnly,
  mapOnly,
  off,
}

class SettingsController extends ChangeNotifier {
  bool _showMockMarker = false;
  bool _showSetupBar = false;
  bool _showDebugPanel = false;
  bool _backgroundEnabled = false;
  bool _backgroundBusy = false;
  bool _backgroundNotificationShown = false;
  DarkModeSetting _darkModeSetting = DarkModeSetting.on;

  bool get showMockMarker => _showMockMarker;
  bool get showSetupBar => _showSetupBar;
  bool get showDebugPanel => _showDebugPanel;
  bool get backgroundEnabled => _backgroundEnabled;
  bool get backgroundBusy => _backgroundBusy;
  bool get backgroundNotificationShown => _backgroundNotificationShown;
  DarkModeSetting get darkModeSetting => _darkModeSetting;

  void setShowMockMarker(bool value) {
    if (_showMockMarker == value) {
      return;
    }
    _showMockMarker = value;
    notifyListeners();
  }

  void setShowSetupBar(bool value) {
    if (_showSetupBar == value) {
      return;
    }
    _showSetupBar = value;
    notifyListeners();
  }

  void setShowDebugPanel(bool value) {
    if (_showDebugPanel == value) {
      return;
    }
    _showDebugPanel = value;
    notifyListeners();
  }

  void setBackgroundEnabled(bool value) {
    if (_backgroundEnabled == value) {
      return;
    }
    _backgroundEnabled = value;
    notifyListeners();
  }

  void setBackgroundBusy(bool value) {
    if (_backgroundBusy == value) {
      return;
    }
    _backgroundBusy = value;
    notifyListeners();
  }

  void setBackgroundNotificationShown(bool value) {
    if (_backgroundNotificationShown == value) {
      return;
    }
    _backgroundNotificationShown = value;
    notifyListeners();
  }

  void setDarkModeSetting(DarkModeSetting value) {
    if (_darkModeSetting == value) {
      return;
    }
    _darkModeSetting = value;
    notifyListeners();
  }
}
