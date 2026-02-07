import 'package:flutter/foundation.dart';

@immutable
abstract class SpooferMapEvent {
  const SpooferMapEvent();
}

class SpooferMapInitialized extends SpooferMapEvent {
  const SpooferMapInitialized();
}
