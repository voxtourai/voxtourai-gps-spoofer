import 'package:flutter/foundation.dart';

@immutable
abstract class SpooferRouteEvent {
  const SpooferRouteEvent();
}

class SpooferRouteInitialized extends SpooferRouteEvent {
  const SpooferRouteInitialized();
}
