/// An observation or callback registration owned by its caller.
abstract interface class Subscription {
  /// Stops the registration. Repeated calls have no effect.
  void dispose();
}
