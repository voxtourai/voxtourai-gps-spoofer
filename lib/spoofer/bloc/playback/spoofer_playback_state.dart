import 'package:flutter/foundation.dart';

@immutable
class SpooferPlaybackState {
  const SpooferPlaybackState({
    this.initialized = false,
    this.isPlaying = false,
    this.speedMps = 2,
    this.resumeAfterPause = false,
    this.tickSequence = 0,
    this.tickDeltaSeconds,
  });

  final bool initialized;
  final bool isPlaying;
  final double speedMps;
  final bool resumeAfterPause;
  final int tickSequence;
  final double? tickDeltaSeconds;

  SpooferPlaybackState copyWith({
    bool? initialized,
    bool? isPlaying,
    double? speedMps,
    bool? resumeAfterPause,
    int? tickSequence,
    double? tickDeltaSeconds,
    bool clearTickDeltaSeconds = false,
  }) {
    return SpooferPlaybackState(
      initialized: initialized ?? this.initialized,
      isPlaying: isPlaying ?? this.isPlaying,
      speedMps: speedMps ?? this.speedMps,
      resumeAfterPause: resumeAfterPause ?? this.resumeAfterPause,
      tickSequence: tickSequence ?? this.tickSequence,
      tickDeltaSeconds: clearTickDeltaSeconds
          ? null
          : (tickDeltaSeconds ?? this.tickDeltaSeconds),
    );
  }
}
