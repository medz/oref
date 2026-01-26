import 'package:analysis_server_plugin/registry.dart';

import '../rules/avoid_hook_context_outside_build_rule.dart';
import '../rules/use_build_context_for_hooks_rule.dart';
import 'add_build_context_argument_fix.dart';
import 'replace_context_with_null_fix.dart';

void registerFixes(PluginRegistry registry) {
  registry.registerFixForRule(
    UseBuildContextForHooksRule.code,
    AddBuildContextArgumentFix.new,
  );
  registry.registerFixForRule(
    AvoidHookContextOutsideBuildRule.code,
    ReplaceContextWithNullFix.new,
  );
}
