// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_message_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferMessageStateCWProxy {
  SpooferMessageState message(SpooferMessage? message);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it.
  ///
  /// Example:
  /// ```dart
  /// SpooferMessageState(...).copyWith(message: null)
  /// ```
  SpooferMessageState call({
    SpooferMessage? message,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferMessageState.copyWith(...)` or
/// `instanceOfSpooferMessageState.copyWith.message(...)`.
class _$SpooferMessageStateCWProxyImpl implements _$SpooferMessageStateCWProxy {
  const _$SpooferMessageStateCWProxyImpl(this._value);

  final SpooferMessageState _value;

  @override
  SpooferMessageState message(SpooferMessage? message) => call(message: message);

  @override
  SpooferMessageState call({
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return SpooferMessageState(
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          : message as SpooferMessage?,
    );
  }
}

extension $SpooferMessageStateCopyWith on SpooferMessageState {
  /// Returns a callable class used to build a new instance with modified fields.
  // ignore: library_private_types_in_public_api
  _$SpooferMessageStateCWProxy get copyWith =>
      _$SpooferMessageStateCWProxyImpl(this);
}
