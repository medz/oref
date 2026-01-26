import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:oref/oref.dart' as oref;

import '../features/ui_state.dart';
import 'scopes.dart';
import 'shell.dart';
import 'theme.dart';

class OrefDevToolsApp extends StatelessWidget {
  const OrefDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final uiState = useUiState(context);
    return UiScope(
      state: uiState,
      child: oref.SignalBuilder(
        builder: (context) {
          final mode = uiState.themeMode();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Oref DevTools',
            theme: OrefTheme.light(),
            darkTheme: OrefTheme.dark(),
            themeMode: mode,
            home: const DevToolsShell(),
          );
        },
      ),
    );
  }
}

class DevToolsRoot extends StatelessWidget {
  const DevToolsRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: OrefDevToolsApp());
  }
}
