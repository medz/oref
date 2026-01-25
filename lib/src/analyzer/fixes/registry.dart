import 'package:analysis_server_plugin/registry.dart';

import '../rules/hook_disallow_context_outside_build_rule.dart';
import '../rules/hook_requires_context_in_build_rule.dart';
import 'add_build_context_argument_fix.dart';
import 'replace_context_with_null_fix.dart';

void registerFixes(PluginRegistry registry) {
  registry.registerFixForRule(
    HookRequiresContextInBuildRule.code,
    AddBuildContextArgumentFix.new,
  );
  registry.registerFixForRule(
    HookDisallowContextOutsideBuildRule.code,
    ReplaceContextWithNullFix.new,
  );
}
