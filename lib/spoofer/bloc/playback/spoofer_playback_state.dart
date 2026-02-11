import 'package:flutter/foundation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'spoofer_playback_state.g.dart';

@immutable
@CopyWith()
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
}
