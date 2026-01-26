import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../utils/utils.dart';

abstract class HookCallVisitorBase extends SimpleAstVisitor<void> {
  HookCallVisitorBase(this.rule, this.skip, this.customHooks);

  final AnalysisRule rule;
  final bool skip;
  final CustomHookRegistry customHooks;

  bool shouldReport(AstNode node, HookScope scope);

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
    if (!shouldReport(node, scope)) {
      return;
    }
    final scopeLabel = hookScopeLabel(scope, customHooks: customHooks);
    rule.reportAtNode(
      target,
      arguments: [formatLintArgument(hookName), formatLintArgument(scopeLabel)],
    );
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
