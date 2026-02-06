import 'dart:async';

import 'package:flutter/foundation.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({double initialSpeedMps = 2, Duration tickInterval = const Duration(milliseconds: 50)})
      : _speedMps = initialSpeedMps,
        _tickInterval = tickInterval;

  final Duration _tickInterval;
  Timer? _timer;
  DateTime? _lastTickAt;
  bool _isPlaying = false;
  bool _resumeAfterPause = false;
  double _speedMps;
  void Function()? _onTick;

  bool get isPlaying => _isPlaying;
  bool get resumeAfterPause => _resumeAfterPause;
  double get speedMps => _speedMps;

  set speedMps(double value) {
    if (_speedMps == value) {
      return;
    }
    _speedMps = value;
    notifyListeners();
  }

  void setResumeAfterPause(bool value) {
    if (_resumeAfterPause == value) {
      return;
    }
    _resumeAfterPause = value;
    notifyListeners();
  }

  void start(void Function() onTick) {
    if (_isPlaying) {
      return;
    }
    _onTick = onTick;
    _isPlaying = true;
    _lastTickAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) => _onTick?.call());
    notifyListeners();
  }

  void stop() {
    if (!_isPlaying) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _lastTickAt = null;
    _isPlaying = false;
    notifyListeners();
  }

  void markTick() {
    _lastTickAt = DateTime.now();
  }

  double? consumeDeltaSeconds() {
    final now = DateTime.now();
    if (_lastTickAt == null) {
      _lastTickAt = now;
      return null;
    }
    final deltaSeconds = now.difference(_lastTickAt!).inMicroseconds / 1000000.0;
    _lastTickAt = now;
    return deltaSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
