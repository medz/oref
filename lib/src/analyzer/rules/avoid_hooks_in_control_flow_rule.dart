import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';
import 'hook_call_visitor.dart';

class AvoidHooksInControlFlowRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hooks_in_control_flow',
    'Call {0} unconditionally at the top level of the {1} scope.',
    correctionMessage: 'Move {0} out of control flow in the {1} scope.',
    severity: .ERROR,
    uniqueName: 'oref.lint.avoid_hooks_in_control_flow',
  );

  AvoidHooksInControlFlowRule()
    : super(
        name: 'avoid_hooks_in_control_flow',
        description:
            'Avoid calling Oref hooks inside control flow in build scopes.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    final customHooks = buildCustomHookRegistry(context);
    var visitor = _AvoidHooksInControlFlowVisitor(this, skip, customHooks);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _AvoidHooksInControlFlowVisitor extends HookCallVisitorBase {
  _AvoidHooksInControlFlowVisitor(super.rule, super.skip, super.customHooks);

  @override
  bool shouldReport(AstNode node, HookScope scope) {
    if (isInsideNestedFunction(node, scope.node)) {
      return false;
    }
    return isInsideControlFlow(node, scope.node);
  }
}
