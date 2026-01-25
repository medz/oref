import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class NoHooksInNestedFunctionsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hooks_in_nested_functions',
    'Hooks must not be called inside nested functions in build scopes.',
    correctionMessage: 'Move the hook to the top level of the build scope.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.no_hooks_in_nested_functions',
  );

  NoHooksInNestedFunctionsRule()
    : super(
        name: 'no_hooks_in_nested_functions',
        description:
            'Disallow calling Oref hooks inside nested functions in build scopes.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _NoHooksInNestedFunctionsVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _NoHooksInNestedFunctionsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _NoHooksInNestedFunctionsVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null) {
      return;
    }
    final scope = enclosingHookScope(node);
    if (scope == null) {
      return;
    }
    if (!isInsideNestedFunction(node, scope.node)) {
      return;
    }
    rule.reportAtNode(node.methodName);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (skip) {
      return;
    }
    final hook = matchHookConstructor(node);
    if (hook == null) {
      return;
    }
    final scope = enclosingHookScope(node);
    if (scope == null) {
      return;
    }
    if (!isInsideNestedFunction(node, scope.node)) {
      return;
    }
    rule.reportAtNode(node.constructorName);
  }
}
