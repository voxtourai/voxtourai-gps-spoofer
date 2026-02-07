import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/message/spoofer_message_bloc.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/message/spoofer_message_event.dart';
import 'package:voxtourai_gps_spoofer/spoofer/bloc/message/spoofer_message_state.dart';

void main() {
  group('SpooferMessageBloc', () {
    blocTest<SpooferMessageBloc, SpooferMessageState>(
      'emits overlay and then clear',
      build: SpooferMessageBloc.new,
      act: (bloc) {
        bloc
          ..add(
            const SpooferMessageShownRequested(
              type: SpooferMessageType.overlay,
              message: 'hello',
            ),
          )
          ..add(const SpooferMessageClearedRequested());
      },
      verify: (bloc) {
        expect(bloc.state.message, isNull);
      },
    );
  });
}
