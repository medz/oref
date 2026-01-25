import 'package:analysis_server_plugin/registry.dart';

import 'hook_disallow_context_outside_build_rule.dart';
import 'hook_in_control_flow_rule.dart';
import 'hook_in_nested_function_rule.dart';
import 'hook_requires_context_in_build_rule.dart';

void registerRules(PluginRegistry registry) {
  registry.registerWarningRule(HookRequiresContextInBuildRule());
  registry.registerWarningRule(HookDisallowContextOutsideBuildRule());
  registry.registerWarningRule(HookInControlFlowRule());
  registry.registerWarningRule(HookInNestedFunctionRule());
}
