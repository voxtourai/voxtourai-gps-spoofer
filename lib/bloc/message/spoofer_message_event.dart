import 'package:flutter/foundation.dart';

import 'spoofer_message_state.dart';

@immutable
abstract class SpooferMessageEvent {
  const SpooferMessageEvent();
}

class SpooferMessageShownRequested extends SpooferMessageEvent {
  const SpooferMessageShownRequested({
    required this.type,
    required this.message,
  });

  final SpooferMessageType type;
  final String message;
}

class SpooferMessageClearedRequested extends SpooferMessageEvent {
  const SpooferMessageClearedRequested();
}
