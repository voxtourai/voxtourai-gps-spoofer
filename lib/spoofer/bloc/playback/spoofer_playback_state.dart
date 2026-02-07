import 'package:flutter/foundation.dart';

@immutable
class SpooferPlaybackState {
  const SpooferPlaybackState({
    this.initialized = false,
    this.isPlaying = false,
    this.speedMps = 2,
  });

  final bool initialized;
  final bool isPlaying;
  final double speedMps;

  SpooferPlaybackState copyWith({
    bool? initialized,
    bool? isPlaying,
    double? speedMps,
  }) {
    return SpooferPlaybackState(
      initialized: initialized ?? this.initialized,
      isPlaying: isPlaying ?? this.isPlaying,
      speedMps: speedMps ?? this.speedMps,
    );
  }
}
