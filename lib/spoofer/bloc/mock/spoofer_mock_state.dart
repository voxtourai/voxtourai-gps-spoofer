import 'package:flutter/foundation.dart';

@immutable
class SpooferMockState {
  const SpooferMockState({
    this.initialized = false,
  });

  final bool initialized;

  SpooferMockState copyWith({
    bool? initialized,
  }) {
    return SpooferMockState(
      initialized: initialized ?? this.initialized,
    );
  }
}
