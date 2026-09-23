import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds one simple UI selection (a filter, a search term, a toggle).
class ValueController<T> extends Notifier<T> {
  ValueController(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}
