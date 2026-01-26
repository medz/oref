import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';
import 'hook_call_visitor.dart';

class AvoidHooksInNestedFunctionsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hooks_in_nested_functions',
    'Do not call {0} inside nested functions in the {1} scope.',
    correctionMessage: 'Move {0} to the top level of the {1} scope.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'oref.lint.avoid_hooks_in_nested_functions',
  );

  AvoidHooksInNestedFunctionsRule()
    : super(
        name: 'avoid_hooks_in_nested_functions',
        description:
            'Avoid calling Oref hooks inside nested functions in build scopes.',
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
    var visitor = _AvoidHooksInNestedFunctionsVisitor(this, skip, customHooks);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _AvoidHooksInNestedFunctionsVisitor extends HookCallVisitorBase {
  _AvoidHooksInNestedFunctionsVisitor(
    super.rule,
    super.skip,
    super.customHooks,
  );

  @override
  bool shouldReport(AstNode node, HookScope scope) {
    return isInsideNestedFunction(node, scope.node);
  }
}
