import 'package:flutter_test/flutter_test.dart';
import 'package:alien_signals/alien_signals.dart';

void main() {
  test('test raw alien_signals behavior', () {
    final calls = <String>[];
    
    // Create a signal
    final counter = signal(0);
    
    // Create a computed that depends on the signal
    final doubled = computed((prev) {
      final result = 'doubled-${counter() * 2}';
      calls.add(result);
      print('Computed called: $result');
      return result;
    });
    
    print('Initial calls: $calls');
    expect(calls, isEmpty); // Computed is lazy
    
    // Access computed to trigger initial calculation
    final initialValue = doubled();
    print('Initial value: $initialValue');
    print('Calls after initial access: $calls');
    
    // Update the signal
    counter(1);
    print('After counter update, calls: $calls');
    
    // Access computed again
    final updatedValue = doubled();
    print('Updated value: $updatedValue');
    print('Final calls: $calls');
  });
}