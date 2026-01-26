import 'package:analysis_server_plugin/registry.dart';

import 'custom_hooks_require_build_rule.dart';
import 'disallow_context_outside_build_rule.dart';
import 'discarded_global_effect_rule.dart';
import 'effect_cleanup_requires_effect_rule.dart';
import 'no_hooks_in_control_flow_rule.dart';
import 'no_hooks_in_nested_functions_rule.dart';
import 'no_writes_in_computed_rule.dart';
import 'require_context_in_build_rule.dart';
import 'scope_dispose_requires_scope_rule.dart';

void registerRules(PluginRegistry registry) {
  registry.registerWarningRule(RequireContextInBuildRule());
  registry.registerWarningRule(DisallowContextOutsideBuildRule());
  registry.registerWarningRule(CustomHooksRequireBuildRule());
  registry.registerWarningRule(NoHooksInControlFlowRule());
  registry.registerWarningRule(NoHooksInNestedFunctionsRule());
  registry.registerWarningRule(NoWritesInComputedRule());
  registry.registerWarningRule(EffectCleanupRequiresEffectRule());
  registry.registerWarningRule(ScopeDisposeRequiresScopeRule());
  registry.registerWarningRule(DiscardedGlobalEffectRule());
}
