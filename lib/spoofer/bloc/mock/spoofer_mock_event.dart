import 'package:flutter/foundation.dart';

@immutable
abstract class SpooferMockEvent {
  const SpooferMockEvent();
}

class SpooferMockInitialized extends SpooferMockEvent {
  const SpooferMockInitialized();
}
