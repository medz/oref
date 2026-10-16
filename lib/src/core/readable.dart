import 'subscription.dart';

/// A synchronous value that can be observed.
abstract interface class Readable<T> {
  /// Reads the current value and tracks the current synchronous observer.
  T get value;

  /// Reads without subscribing the caller.
  T peek();

  /// Observes changes without calling [listener] on registration.
  Subscription subscribe(void Function() listener);
}
