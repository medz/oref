import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';

void main() {
  testWidgets('basic useSignal test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final count = useSignal(context, 0);
            
            return Column(
              children: [
                Text('count: ${count()}'),
                TextButton(
                  onPressed: () => count(count() + 1),
                  child: const Text('increment'),
                ),
              ],
            );
          },
        ),
      ),
    );
    
    // Check initial state
    expect(find.text('count: 0'), findsOneWidget);
    
    // Tap button and check update
    await tester.tap(find.text('increment'));
    await tester.pump();
    
    expect(find.text('count: 1'), findsOneWidget);
  });
  
  testWidgets('basic useComputed test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final count = useSignal(context, 5);
            final doubled = useComputed(context, (_) => count() * 2);
            
            return Column(
              children: [
                Text('count: ${count()}'),
                Text('doubled: ${doubled()}'),
                TextButton(
                  onPressed: () => count(count() + 1),
                  child: const Text('increment'),
                ),
              ],
            );
          },
        ),
      ),
    );
    
    expect(find.text('count: 5'), findsOneWidget);
    expect(find.text('doubled: 10'), findsOneWidget);
    
    await tester.tap(find.text('increment'));
    await tester.pump();
    
    expect(find.text('count: 6'), findsOneWidget);
    expect(find.text('doubled: 12'), findsOneWidget);
  });
  
  testWidgets('basic batch test', (tester) async {
    int buildCount = 0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            buildCount++;
            final count1 = useSignal(context, 0);
            final count2 = useSignal(context, 0);
            
            return Column(
              children: [
                Text('builds: $buildCount'),
                Text('count1: ${count1()}, count2: ${count2()}'),
                TextButton(
                  onPressed: () {
                    batch(() {
                      count1(count1() + 1);
                      count2(count2() + 1);
                    });
                  },
                  child: const Text('batch update'),
                ),
              ],
            );
          },
        ),
      ),
    );
    
    expect(buildCount, equals(1));
    expect(find.text('count1: 0, count2: 0'), findsOneWidget);
    
    await tester.tap(find.text('batch update'));
    await tester.pump();
    
    // The key question: does batch prevent multiple rebuilds?
    print('Build count after batch: $buildCount');
    expect(find.text('count1: 1, count2: 1'), findsOneWidget);
  });
}