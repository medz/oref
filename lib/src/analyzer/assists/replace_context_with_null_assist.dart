import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../utils/utils.dart';

class ReplaceContextWithNullAssist extends ResolvedCorrectionProducer {
  static const AssistKind kind = AssistKind(
    'oref.assist.replace_context_with_null',
    30,
    'Oref: replace {0} with `null` in {1}',
  );

  ReplaceContextWithNullAssist({required super.context});

  List<String>? _arguments;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String>? get assistArguments => _arguments;

  @override
  AssistKind get assistKind => kind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final methodInvocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (methodInvocation == null) {
      return;
    }

    final hook = matchHookInvocation(methodInvocation);
    if (hook == null || !hook.isOptionalContext) {
      return;
    }

    final buildMethod = enclosingBuildMethod(methodInvocation);
    if (buildMethod != null) {
      return;
    }

    final contextArgument = hook.contextArgument;
    if (contextArgument == null ||
        isNullLiteral(contextArgument) ||
        !isBuildContextExpression(contextArgument)) {
      return;
    }

    final contextName = contextArgument.toSource();
    _arguments = [
      formatLintArgument(contextName),
      formatLintArgument(hook.name),
    ];

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(contextArgument), 'null');
    });
  }
}
