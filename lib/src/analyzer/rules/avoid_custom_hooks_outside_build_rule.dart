import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class AvoidCustomHooksOutsideBuildRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_custom_hooks_outside_build',
    '{0} must be called inside a build scope or another hook.',
    correctionMessage: 'Move {0} into a build scope or another hook.',
    severity: .ERROR,
    uniqueName: 'oref.lint.avoid_custom_hooks_outside_build',
  );

  AvoidCustomHooksOutsideBuildRule()
    : super(
        name: 'avoid_custom_hooks_outside_build',
        description:
            'Avoid calling custom hooks outside build scopes or other hooks.',
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
    var visitor = _AvoidCustomHooksOutsideBuildVisitor(this, skip, customHooks);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }
}

class _AvoidCustomHooksOutsideBuildVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;
  final CustomHookRegistry customHooks;

  _AvoidCustomHooksOutsideBuildVisitor(this.rule, this.skip, this.customHooks);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    if (!customHooks.isCustomHookInvocation(node)) {
      return;
    }
    _reportIfOutsideScope(node, node.methodName, _hookName(node.methodName));
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
    _reportIfOutsideScope(node, nameNode, _hookName(nameNode));
  }

  void _reportIfOutsideScope(AstNode node, AstNode target, String hookName) {
    if (enclosingHookScope(node, customHooks: customHooks) != null) {
      return;
    }
    rule.reportAtNode(target, arguments: [formatLintArgument(hookName)]);
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
