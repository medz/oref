import 'package:flutter/material.dart';
import 'package:oref/oref.dart';
import 'package:oxy/oxy.dart';

class AsyncDataExample extends StatelessWidget {
  const AsyncDataExample({super.key});

  @override
  Widget build(BuildContext context) {
    final result = useAsyncData(context, () async {
      final res = await oxy.get("https://www.schemastore.org/pubspec.json");
      if (!res.ok) {
        throw Exception('Failed to fetch data');
      }

      // Intentional, intuitive display of state flow.
      await Future.delayed(const Duration(seconds: 3));

      return res.json();
    });

    return Scaffold(
      appBar: AppBar(title: Text('Async Data Example')),
      floatingActionButton: SignalBuilder(
        builder: (context) {
          if (result.status == AsyncStatus.pending) {
            return SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: result.refresh,
            child: const Icon(Icons.refresh),
          );
        },
      ),
      body: Center(
        // Performance optimization!
        // child: SignalBuilder(
        //   builder: (_) => result.when(
        //     idle: (_) => const SizedBox.shrink(),
        //     pending: () => const CircularProgressIndicator(),
        //     error: (error) => Text(Error.safeToString(error)),
        //     success: (data) => Text(data.toString()),
        //   ),
        // ),
        child: result.when(
          idle: (_) => const SizedBox.shrink(),
          pending: (_) => const CircularProgressIndicator(),
          error: (error) => Text(Error.safeToString(error)),
          success: (data) => Text(data.toString()),
        ),
      ),
    );
  }
}
