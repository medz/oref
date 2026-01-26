import 'package:analysis_server_plugin/registry.dart';

import 'avoid_custom_hooks_outside_build_rule.dart';
import 'avoid_discarded_global_effect_rule.dart';
import 'avoid_effect_cleanup_outside_effect_rule.dart';
import 'avoid_hook_context_outside_build_rule.dart';
import 'avoid_hooks_in_control_flow_rule.dart';
import 'avoid_hooks_in_nested_functions_rule.dart';
import 'avoid_scope_dispose_outside_scope_rule.dart';
import 'avoid_writes_in_computed_rule.dart';
import 'use_build_context_for_hooks_rule.dart';

void registerRules(PluginRegistry registry) {
  registry.registerWarningRule(UseBuildContextForHooksRule());
  registry.registerWarningRule(AvoidHookContextOutsideBuildRule());
  registry.registerWarningRule(AvoidCustomHooksOutsideBuildRule());
  registry.registerWarningRule(AvoidHooksInControlFlowRule());
  registry.registerWarningRule(AvoidHooksInNestedFunctionsRule());
  registry.registerWarningRule(AvoidWritesInComputedRule());
  registry.registerWarningRule(AvoidEffectCleanupOutsideEffectRule());
  registry.registerWarningRule(AvoidScopeDisposeOutsideScopeRule());
  registry.registerWarningRule(AvoidDiscardedGlobalEffectRule());
}
