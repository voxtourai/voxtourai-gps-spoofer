import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/bloc/playback/spoofer_playback_bloc.dart';
import 'package:voxtourai_gps_spoofer/bloc/playback/spoofer_playback_event.dart';
import 'package:voxtourai_gps_spoofer/bloc/playback/spoofer_playback_state.dart';

void main() {
  group('SpooferPlaybackBloc', () {
    blocTest<SpooferPlaybackBloc, SpooferPlaybackState>(
      'initializes when requested',
      build: () => SpooferPlaybackBloc(),
      act: (bloc) => bloc.add(const SpooferPlaybackInitialized()),
      expect: () => [
        isA<SpooferPlaybackState>().having(
          (s) => s.initialized,
          'initialized',
          true,
        ),
      ],
    );

    blocTest<SpooferPlaybackBloc, SpooferPlaybackState>(
      'starts ticking after play',
      build: () =>
          SpooferPlaybackBloc(tickInterval: const Duration(milliseconds: 10)),
      act: (bloc) => bloc.add(const SpooferPlaybackPlayRequested()),
      wait: const Duration(milliseconds: 40),
      verify: (bloc) {
        expect(bloc.state.isPlaying, true);
        expect(bloc.state.tickSequence, greaterThan(0));
        expect(bloc.state.tickDeltaSeconds, isNotNull);
      },
    );

    blocTest<SpooferPlaybackBloc, SpooferPlaybackState>(
      'pauses and resumes via app lifecycle events',
      build: () => SpooferPlaybackBloc(),
      act: (bloc) {
        bloc
          ..add(const SpooferPlaybackPlayRequested())
          ..add(const SpooferPlaybackAppPaused())
          ..add(const SpooferPlaybackAppResumed());
      },
      wait: const Duration(milliseconds: 30),
      verify: (bloc) {
        expect(bloc.state.isPlaying, true);
        expect(bloc.state.resumeAfterPause, false);
      },
    );

    blocTest<SpooferPlaybackBloc, SpooferPlaybackState>(
      'clamps speed to supported range',
      build: () => SpooferPlaybackBloc(),
      act: (bloc) {
        bloc
          ..add(const SpooferPlaybackSpeedSetRequested(speedMps: 500))
          ..add(const SpooferPlaybackSpeedSetRequested(speedMps: -500));
      },
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.speedMps, -200);
      },
    );

    blocTest<SpooferPlaybackBloc, SpooferPlaybackState>(
      'pause requested stops playback and clears tick delta',
      build: () =>
          SpooferPlaybackBloc(tickInterval: const Duration(milliseconds: 10)),
      act: (bloc) async {
        bloc.add(const SpooferPlaybackPlayRequested());
        await Future<void>.delayed(const Duration(milliseconds: 35));
        bloc.add(const SpooferPlaybackPauseRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.isPlaying, false);
        expect(bloc.state.tickSequence, greaterThan(0));
        expect(bloc.state.tickDeltaSeconds, isNull);
      },
    );

    blocTest<SpooferPlaybackBloc, SpooferPlaybackState>(
      'resume is ignored after an explicit pause',
      build: () =>
          SpooferPlaybackBloc(tickInterval: const Duration(milliseconds: 10)),
      act: (bloc) async {
        bloc.add(const SpooferPlaybackPlayRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc
          ..add(const SpooferPlaybackPauseRequested())
          ..add(const SpooferPlaybackAppResumed());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.isPlaying, false);
        expect(bloc.state.resumeAfterPause, false);
      },
    );
  });
}
