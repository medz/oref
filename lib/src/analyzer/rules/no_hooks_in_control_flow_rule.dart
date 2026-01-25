import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class NoHooksInControlFlowRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hooks_in_control_flow',
    'Hooks must be called unconditionally at the top level of build scopes.',
    correctionMessage: 'Move the hook out of the control flow.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.no_hooks_in_control_flow',
  );

  NoHooksInControlFlowRule()
    : super(
        name: 'no_hooks_in_control_flow',
        description:
            'Disallow calling Oref hooks inside control flow in build scopes.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _NoHooksInControlFlowVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _NoHooksInControlFlowVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _NoHooksInControlFlowVisitor(this.rule, this.skip);

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
    if (isInsideNestedFunction(node, scope.node)) {
      return;
    }
    if (!isInsideControlFlow(node, scope.node)) {
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
    if (isInsideNestedFunction(node, scope.node)) {
      return;
    }
    if (!isInsideControlFlow(node, scope.node)) {
      return;
    }
    rule.reportAtNode(node.constructorName);
  }
}
