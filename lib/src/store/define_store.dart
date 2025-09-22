import 'package:oref/oref.dart';

final _rootStore = <Symbol, dynamic>{};

T Function() defineStore<T>(Symbol name, T Function() setup) {
  if (_rootStore.containsKey(name)) {
    throw StateError('Store with name $name already exists');
  }

  return () => _rootStore[name] ??= setup();
}

final useCounterStore = defineStore(#counter, () {
  final value = GlobalSignals.create(0);

  return (
    value: value,
    increment: () => value(value() + 1),
    decrement: () => value(value() - 1),
  );
});

final store = useCounterStore();
