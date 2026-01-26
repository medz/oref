import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../utils/utils.dart';

class AddBuildContextArgumentFix extends ResolvedCorrectionProducer {
  static const FixKind kind = FixKind(
    'oref.fix.add_build_context_argument',
    DartFixKindPriority.standard,
    'Oref: add build context argument',
  );

  AddBuildContextArgumentFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => kind;

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

    final scope = enclosingHookScope(methodInvocation);
    if (scope == null) {
      return;
    }

    if (isInsideControlFlow(methodInvocation, scope.node) ||
        isInsideNestedFunction(methodInvocation, scope.node)) {
      return;
    }

    final contextName = hookScopeContextName(scope);
    if (contextName == null) {
      return;
    }

    final contextArgument = hook.contextArgument;
    if (contextArgument == null) {
      final arguments = methodInvocation.argumentList.arguments;
      final insertion = arguments.isEmpty ? contextName : '$contextName, ';
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(
          methodInvocation.argumentList.leftParenthesis.end,
          insertion,
        );
      });
      return;
    }

    if (isNullLiteral(contextArgument)) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(contextArgument), contextName);
      });
      return;
    }

    if (isBuildContextExpression(contextArgument)) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(contextArgument.offset, '$contextName, ');
    });
  }
}
