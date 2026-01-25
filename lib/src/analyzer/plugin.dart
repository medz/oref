import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'assists/registry.dart';
import 'fixes/registry.dart';
import 'rules/registry.dart';

class AnalyzerPlugin extends Plugin {
  @override
  String get name => 'Oref Analyzer Plugin';

  @override
  void register(PluginRegistry registry) {
    registerRules(registry);
    registerFixes(registry);
    registerAssists(registry);
  }
}
