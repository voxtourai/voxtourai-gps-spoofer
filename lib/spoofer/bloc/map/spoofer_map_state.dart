import 'package:flutter/foundation.dart';

@immutable
class SpooferMapState {
  const SpooferMapState({
    this.initialized = false,
    this.autoFollowEnabled = true,
  });

  final bool initialized;
  final bool autoFollowEnabled;

  SpooferMapState copyWith({
    bool? initialized,
    bool? autoFollowEnabled,
  }) {
    return SpooferMapState(
      initialized: initialized ?? this.initialized,
      autoFollowEnabled: autoFollowEnabled ?? this.autoFollowEnabled,
    );
  }
}
