import 'package:flutter/foundation.dart';

@immutable
abstract class SpooferPlaybackEvent {
  const SpooferPlaybackEvent();
}

class SpooferPlaybackInitialized extends SpooferPlaybackEvent {
  const SpooferPlaybackInitialized();
}
