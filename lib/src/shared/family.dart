part of 'shared.dart';

abstract interface class _ResourceDefinition {
  Object? _createResource(Object? key);
  void _disposeResource(Object resource);
}

/// Describes resources created lazily for immutable keys.
final class Family<K, R> implements _ResourceDefinition {
  Family({required this._create, required this._dispose});

  final R Function(K) _create;
  final void Function(R) _dispose;

  /// Creates a reference without creating or retaining a resource.
  ResourceRef<R> call(K key) => ResourceRef<R>._(
    definition: this,
    key: key,
    resolve: (resource, _) => resource as R,
  );

  @override
  Object? _createResource(Object? key) => _create(key as K);

  @override
  void _disposeResource(Object resource) => _dispose(resource as R);
}

/// A lazy resource reference, meaningful within a [Resources] directory.
final class ResourceRef<R> {
  const ResourceRef._({
    required this._definition,
    required this._key,
    required this._resolve,
    this._path = const [],
  });

  final _ResourceDefinition _definition;
  final Object? _key;
  final R Function(Object, Map<Object, Object?>) _resolve;
  final List<Object> _path;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResourceRef ||
        !identical(_definition, other._definition) ||
        _key != other._key ||
        _path.length != other._path.length) {
      return false;
    }
    for (var i = 0; i < _path.length; i++) {
      if (!identical(_path[i], other._path[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(_definition),
    _key,
    Object.hashAll(_path.map(identityHashCode)),
  );
}

// Package-internal: projections share their parent's entry and lifetime.
final _creatingView = Object();

ResourceRef<R> deriveResourceRef<P, R>(
  ResourceRef<P> parent,
  Object definition,
  R Function(P parent) project,
) => ResourceRef<R>._(
  definition: parent._definition,
  key: parent._key,
  path: List<Object>.unmodifiable([...parent._path, definition]),
  resolve: (resource, views) {
    final cached = views[definition];
    if (identical(cached, _creatingView)) {
      throw StateError('A shared projection cannot recursively create itself.');
    }
    if (cached is RemoteValue && resourceDisposed(cached)) {
      views.remove(definition);
    } else if (cached != null || views.containsKey(definition)) {
      return cached as R;
    }
    views[definition] = _creatingView;
    try {
      return views[definition] = project(parent._resolve(resource, views));
    } catch (_) {
      views.remove(definition);
      rethrow;
    }
  },
);

/// Defines writable fields once, beside the parent query family.
extension QueryFamilyFields<K, S, M> on Family<K, Query<S, M>> {
  ResourceRef<RemoteValue<S, V>> Function(K) field<V>({
    required V Function(M) select,
    required M Function(M, V) apply,
    required FutureOr<V> Function(S, V desired) write,
  }) {
    final definition = Object();
    return (key) => deriveResourceRef(
      call(key),
      definition,
      (query) => query.field(select: select, apply: apply, write: write),
    );
  }

  ResourceRef<RemoteValue<S, V>> Function(K) fieldAck<V>({
    required V Function(M) select,
    required M Function(M, V) apply,
    required FutureOr<void> Function(S, V desired) write,
  }) {
    final definition = Object();
    return (key) => deriveResourceRef(
      call(key),
      definition,
      (query) => query.fieldAck(select: select, apply: apply, write: write),
    );
  }
}
