import 'package:flutter/foundation.dart';

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
class SpooferMessageState {
  const SpooferMessageState({this.message});

  final SpooferMessage? message;

  SpooferMessageState copyWith({
    SpooferMessage? message,
    bool clearMessage = false,
  }) {
    return SpooferMessageState(
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
