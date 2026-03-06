import 'package:flutter/foundation.dart';

@immutable
abstract class SpooferPlaybackEvent {
  const SpooferPlaybackEvent();
}

class SpooferPlaybackInitialized extends SpooferPlaybackEvent {
  const SpooferPlaybackInitialized();
}

class SpooferPlaybackPlayRequested extends SpooferPlaybackEvent {
  const SpooferPlaybackPlayRequested();
}

class SpooferPlaybackPauseRequested extends SpooferPlaybackEvent {
  const SpooferPlaybackPauseRequested();
}

class SpooferPlaybackSpeedSetRequested extends SpooferPlaybackEvent {
  const SpooferPlaybackSpeedSetRequested({required this.speedMps});

  final double speedMps;
}

class SpooferPlaybackAppPaused extends SpooferPlaybackEvent {
  const SpooferPlaybackAppPaused();
}

class SpooferPlaybackAppResumed extends SpooferPlaybackEvent {
  const SpooferPlaybackAppResumed();
}

class SpooferPlaybackTickClockResetRequested extends SpooferPlaybackEvent {
  const SpooferPlaybackTickClockResetRequested();
}

class SpooferPlaybackTicked extends SpooferPlaybackEvent {
  const SpooferPlaybackTicked();
}
