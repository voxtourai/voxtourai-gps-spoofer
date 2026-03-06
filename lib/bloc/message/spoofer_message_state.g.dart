// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoofer_message_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpooferMessageStateCWProxy {
  SpooferMessageState message(SpooferMessage? message);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SpooferMessageState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SpooferMessageState(...).copyWith(id: 12, name: "My name")
  /// ```
  SpooferMessageState call({SpooferMessage? message});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpooferMessageState.copyWith(...)` or call `instanceOfSpooferMessageState.copyWith.fieldName(value)` for a single field.
class _$SpooferMessageStateCWProxyImpl implements _$SpooferMessageStateCWProxy {
  const _$SpooferMessageStateCWProxyImpl(this._value);

  final SpooferMessageState _value;

  @override
  SpooferMessageState message(SpooferMessage? message) =>
      call(message: message);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SpooferMessageState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SpooferMessageState(...).copyWith(id: 12, name: "My name")
  /// ```
  SpooferMessageState call({Object? message = const $CopyWithPlaceholder()}) {
    return SpooferMessageState(
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as SpooferMessage?,
    );
  }
}

extension $SpooferMessageStateCopyWith on SpooferMessageState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSpooferMessageState.copyWith(...)` or `instanceOfSpooferMessageState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SpooferMessageStateCWProxy get copyWith =>
      _$SpooferMessageStateCWProxyImpl(this);
}
