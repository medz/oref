import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class AvoidHooksInControlFlowRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hooks_in_control_flow',
    '{0} must be called unconditionally at the top level of build scopes.',
    correctionMessage: 'Move {0} out of the control flow.',
    severity: DiagnosticSeverity.ERROR,
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

class _AvoidHooksInControlFlowVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;
  final CustomHookRegistry customHooks;

  _AvoidHooksInControlFlowVisitor(this.rule, this.skip, this.customHooks);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook != null) {
      _reportIfNeeded(node, node.methodName, hook.name);
      return;
    }
    if (!customHooks.isCustomHookInvocation(node)) {
      return;
    }
    _reportIfNeeded(node, node.methodName, _hookName(node.methodName));
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (skip) {
      return;
    }
    if (!customHooks.isCustomHookInvocationExpression(node)) {
      return;
    }
    final nameNode = customHookInvocationNameNode(node);
    _reportIfNeeded(node, nameNode, _hookName(nameNode));
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
    _reportIfNeeded(node, node.constructorName, hook.name);
  }

  void _reportIfNeeded(AstNode node, AstNode target, String hookName) {
    final scope = enclosingHookScope(node, customHooks: customHooks);
    if (scope == null) {
      return;
    }
    if (isInsideNestedFunction(node, scope.node)) {
      return;
    }
    if (!isInsideControlFlow(node, scope.node)) {
      return;
    }
    rule.reportAtNode(target, arguments: [hookName]);
  }

  String _hookName(AstNode node) {
    if (node is SimpleIdentifier) {
      return node.name;
    }
    if (node is PrefixedIdentifier) {
      return node.identifier.name;
    }
    if (node is PropertyAccess) {
      return node.propertyName.name;
    }
    return node.toSource();
  }
}
