import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class AvoidHookContextOutsideBuildRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hook_context_outside_build',
    'Passing BuildContext to {0} is only allowed inside a build scope.',
    correctionMessage:
        'Move {0} into a build scope, or pass null if supported.',
    severity: .ERROR,
    uniqueName: 'oref.lint.avoid_hook_context_outside_build',
  );

  AvoidHookContextOutsideBuildRule()
    : super(
        name: 'avoid_hook_context_outside_build',
        description:
            'Avoid passing BuildContext to Oref hooks outside build scopes.',
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
    var visitor = _AvoidHookContextOutsideBuildVisitor(this, skip, customHooks);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _AvoidHookContextOutsideBuildVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;
  final CustomHookRegistry customHooks;

  _AvoidHookContextOutsideBuildVisitor(this.rule, this.skip, this.customHooks);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null) {
      return;
    }
    if (enclosingHookScope(node, customHooks: customHooks) != null) {
      return;
    }

    _reportIfContextPresent(hook, node.methodName);
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
    if (enclosingHookScope(node, customHooks: customHooks) != null) {
      return;
    }

    _reportIfContextPresent(hook, node.constructorName);
  }

  void _reportIfContextPresent(HookCall hook, AstNode fallback) {
    final contextArgument = hook.contextArgument;
    if (hook.isOptionalContext) {
      if (contextArgument == null || isNullLiteral(contextArgument)) {
        return;
      }
      if (!isBuildContextExpression(contextArgument)) {
        return;
      }
      rule.reportAtNode(
        contextArgument,
        arguments: [formatLintArgument(hook.name)],
      );
      return;
    }

    rule.reportAtNode(
      contextArgument ?? fallback,
      arguments: [formatLintArgument(hook.name)],
    );
  }
}
