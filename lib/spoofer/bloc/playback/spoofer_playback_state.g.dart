// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_playback_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferPlaybackStateCWProxy {
  SpooferPlaybackState initialized(bool initialized);

  SpooferPlaybackState isPlaying(bool isPlaying);

  SpooferPlaybackState speedMps(double speedMps);

  SpooferPlaybackState resumeAfterPause(bool resumeAfterPause);

  SpooferPlaybackState tickSequence(int tickSequence);

  SpooferPlaybackState tickDeltaSeconds(double? tickDeltaSeconds);

  /// Creates a new instance with the provided field values.
  SpooferPlaybackState call({
    bool initialized,
    bool isPlaying,
    double speedMps,
    bool resumeAfterPause,
    int tickSequence,
    double? tickDeltaSeconds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferPlaybackState.copyWith(...)` or
/// `instanceOfSpooferPlaybackState.copyWith.fieldName(...)`.
class _$SpooferPlaybackStateCWProxyImpl implements _$SpooferPlaybackStateCWProxy {
  const _$SpooferPlaybackStateCWProxyImpl(this._value);

  final SpooferPlaybackState _value;

  @override
  SpooferPlaybackState initialized(bool initialized) => call(initialized: initialized);

  @override
  SpooferPlaybackState isPlaying(bool isPlaying) => call(isPlaying: isPlaying);

  @override
  SpooferPlaybackState speedMps(double speedMps) => call(speedMps: speedMps);

  @override
  SpooferPlaybackState resumeAfterPause(bool resumeAfterPause) => call(resumeAfterPause: resumeAfterPause);

  @override
  SpooferPlaybackState tickSequence(int tickSequence) => call(tickSequence: tickSequence);

  @override
  SpooferPlaybackState tickDeltaSeconds(double? tickDeltaSeconds) => call(tickDeltaSeconds: tickDeltaSeconds);

  @override
  SpooferPlaybackState call({
    Object? initialized = const $CopyWithPlaceholder(),
    Object? isPlaying = const $CopyWithPlaceholder(),
    Object? speedMps = const $CopyWithPlaceholder(),
    Object? resumeAfterPause = const $CopyWithPlaceholder(),
    Object? tickSequence = const $CopyWithPlaceholder(),
    Object? tickDeltaSeconds = const $CopyWithPlaceholder(),
  }) {
    return SpooferPlaybackState(
      initialized: initialized == const $CopyWithPlaceholder() || initialized == null
          ? _value.initialized
          : initialized as bool,
      isPlaying: isPlaying == const $CopyWithPlaceholder() || isPlaying == null
          ? _value.isPlaying
          : isPlaying as bool,
      speedMps: speedMps == const $CopyWithPlaceholder() || speedMps == null
          ? _value.speedMps
          : speedMps as double,
      resumeAfterPause: resumeAfterPause == const $CopyWithPlaceholder() || resumeAfterPause == null
          ? _value.resumeAfterPause
          : resumeAfterPause as bool,
      tickSequence: tickSequence == const $CopyWithPlaceholder() || tickSequence == null
          ? _value.tickSequence
          : tickSequence as int,
      tickDeltaSeconds: tickDeltaSeconds == const $CopyWithPlaceholder()
          ? _value.tickDeltaSeconds
          : tickDeltaSeconds as double?,
    );
  }
}

extension $SpooferPlaybackStateCopyWith on SpooferPlaybackState {
  /// Returns a callable class used to build a new instance with modified fields.
  // ignore: library_private_types_in_public_api
  _$SpooferPlaybackStateCWProxy get copyWith => _$SpooferPlaybackStateCWProxyImpl(this);
}
