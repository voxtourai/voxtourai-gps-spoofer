import 'package:flutter/foundation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'spoofer_message_state.g.dart';

enum SpooferMessageType { snack, overlay }

@immutable
class SpooferMessage {
  const SpooferMessage({
    required this.id,
    required this.type,
    required this.message,
  });

  final int id;
  final SpooferMessageType type;
  final String message;
}

@immutable
@CopyWith()
class SpooferMessageState {
  const SpooferMessageState({this.message});

  final SpooferMessage? message;
}
