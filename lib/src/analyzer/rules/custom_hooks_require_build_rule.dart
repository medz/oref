import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class CustomHooksRequireBuildRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'custom_hooks_require_build',
    '{0} must be called inside build scopes or other custom hooks.',
    correctionMessage: 'Move {0} into a build scope or another custom hook.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'oref.lint.custom_hooks_require_build',
  );

  CustomHooksRequireBuildRule()
    : super(
        name: 'custom_hooks_require_build',
        description:
            'Require custom hooks to be called inside build scopes or other custom hooks.',
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
    var visitor = _CustomHooksRequireBuildVisitor(this, skip, customHooks);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }
}

class _CustomHooksRequireBuildVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;
  final CustomHookRegistry customHooks;

  _CustomHooksRequireBuildVisitor(this.rule, this.skip, this.customHooks);

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
