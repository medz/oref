import 'package:oref/oref.dart';

void main() {
  final count = Signal(0);
  final doubled = Computed(() => count.value * 2);
  final scope = ReactiveScope();

  try {
    scope.run(() {
      Effect((onCleanup) {
        print('Count: ${count.value}; doubled: ${doubled.value}');
        onCleanup(() => print('Clean up this run'));
      });
    });

    batch(() {
      count.value = 1;
      count.value = 2;
    });
    print('Snapshot: ${untracked(() => doubled.value)}');
  } finally {
    scope.dispose();
  }
}
