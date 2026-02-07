import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'spoofer_playback_event.dart';
import 'spoofer_playback_state.dart';

class SpooferPlaybackBloc extends Bloc<SpooferPlaybackEvent, SpooferPlaybackState> {
  SpooferPlaybackBloc({
    Duration tickInterval = const Duration(milliseconds: 50),
  })  : _tickInterval = tickInterval,
        super(const SpooferPlaybackState()) {
    on<SpooferPlaybackInitialized>(_onInitialized);
    on<SpooferPlaybackPlayRequested>(_onPlayRequested);
    on<SpooferPlaybackPauseRequested>(_onPauseRequested);
    on<SpooferPlaybackSpeedSetRequested>(_onSpeedSetRequested);
    on<SpooferPlaybackAppPaused>(_onAppPaused);
    on<SpooferPlaybackAppResumed>(_onAppResumed);
    on<SpooferPlaybackTickClockResetRequested>(_onTickClockResetRequested);
    on<SpooferPlaybackTicked>(_onTicked);
  }

  final Duration _tickInterval;
  Timer? _timer;
  DateTime? _lastTickAt;

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    _lastTickAt = null;
    return super.close();
  }

  void _onInitialized(
    SpooferPlaybackInitialized event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (!state.initialized) {
      emit(state.copyWith(initialized: true));
    }
  }

  void _onPlayRequested(
    SpooferPlaybackPlayRequested event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (state.isPlaying) {
      return;
    }
    _startTimer();
    emit(
      state.copyWith(
        isPlaying: true,
        resumeAfterPause: false,
        clearTickDeltaSeconds: true,
      ),
    );
  }

  void _onPauseRequested(
    SpooferPlaybackPauseRequested event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (!state.isPlaying) {
      return;
    }
    _stopTimer();
    emit(
      state.copyWith(
        isPlaying: false,
        clearTickDeltaSeconds: true,
      ),
    );
  }

  void _onSpeedSetRequested(
    SpooferPlaybackSpeedSetRequested event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    final clamped = _clampSpeed(event.speedMps);
    if (clamped == state.speedMps) {
      return;
    }
    emit(state.copyWith(speedMps: clamped));
  }

  void _onAppPaused(
    SpooferPlaybackAppPaused event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (!state.isPlaying) {
      return;
    }
    _stopTimer();
    emit(
      state.copyWith(
        isPlaying: false,
        resumeAfterPause: true,
        clearTickDeltaSeconds: true,
      ),
    );
  }

  void _onAppResumed(
    SpooferPlaybackAppResumed event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (!state.resumeAfterPause || state.isPlaying) {
      return;
    }
    _startTimer();
    emit(
      state.copyWith(
        isPlaying: true,
        resumeAfterPause: false,
        clearTickDeltaSeconds: true,
      ),
    );
  }

  void _onTickClockResetRequested(
    SpooferPlaybackTickClockResetRequested event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    _lastTickAt = DateTime.now();
  }

  void _onTicked(
    SpooferPlaybackTicked event,
    Emitter<SpooferPlaybackState> emit,
  ) {
    if (!state.isPlaying) {
      return;
    }
    final now = DateTime.now();
    final previous = _lastTickAt;
    _lastTickAt = now;
    if (previous == null) {
      return;
    }
    final deltaSeconds = now.difference(previous).inMicroseconds / 1000000.0;
    emit(
      state.copyWith(
        tickSequence: state.tickSequence + 1,
        tickDeltaSeconds: deltaSeconds,
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _lastTickAt = DateTime.now();
    _timer = Timer.periodic(_tickInterval, (_) {
      if (!isClosed) {
        add(const SpooferPlaybackTicked());
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _lastTickAt = null;
  }

  double _clampSpeed(double value) {
    if (value < -200) {
      return -200;
    }
    if (value > 200) {
      return 200;
    }
    return value;
  }
}
