import 'package:flutter/foundation.dart';

@immutable
class SpooferRouteState {
  const SpooferRouteState({
    this.initialized = false,
  });

  final bool initialized;

  SpooferRouteState copyWith({
    bool? initialized,
  }) {
    return SpooferRouteState(
      initialized: initialized ?? this.initialized,
    );
  }
}
