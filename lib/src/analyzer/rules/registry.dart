import 'package:analysis_server_plugin/registry.dart';

import 'signal_requires_context_rule.dart';

void registerRules(PluginRegistry registry) {
  registry.registerWarningRule(SignalRequiresContextRule());
}
