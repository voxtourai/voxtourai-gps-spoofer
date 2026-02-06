import 'package:flutter/foundation.dart';

enum UiMessageType { snack, overlay }

class UiMessage {
  const UiMessage({
    required this.id,
    required this.type,
    required this.message,
  });

  final int id;
  final UiMessageType type;
  final String message;
}

class UiMessageController extends ChangeNotifier {
  UiMessage? _message;
  int _nextId = 0;

  UiMessage? get message => _message;

  void showSnack(String message) => _emit(UiMessageType.snack, message);

  void showOverlay(String message) => _emit(UiMessageType.overlay, message);

  void clear() {
    _message = null;
    notifyListeners();
  }

  void _emit(UiMessageType type, String message) {
    _message = UiMessage(id: _nextId++, type: type, message: message);
    notifyListeners();
  }
}
