import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  test("Normal effect stop with clean", () {
    bool clean = false;
    int tick = 0;

    final src = signal(null, 0);
    final dispose = effect(null, () {
      src();
      tick++;

      onEffectDispose(() {
        clean = true;
      });
    });

    expect(clean, equals(false));
    expect(tick, equals(1));

    src.set(1);
    expect(clean, equals(false));
    expect(tick, equals(2));

    dispose();
    expect(clean, equals(true));
    expect(tick, equals(2));

    clean = false;
    src.set(2);
    expect(clean, equals(false));
    expect(tick, equals(2));
  });
}
