import 'package:analysis_server_plugin/registry.dart';

import 'add_build_context_argument_assist.dart';
import 'replace_context_with_null_assist.dart';

void registerAssists(PluginRegistry registry) {
  registry.registerAssist(AddBuildContextArgumentAssist.new);
  registry.registerAssist(ReplaceContextWithNullAssist.new);
}
