import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class DisallowContextOutsideBuildRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'disallow_context_outside_build',
    'Hooks that rely on BuildContext must be called inside build scopes.',
    correctionMessage:
        'Move the hook into a build scope, or pass null if the hook allows it.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.disallow_context_outside_build',
  );

  DisallowContextOutsideBuildRule()
    : super(
        name: 'disallow_context_outside_build',
        description:
            'Require Oref hooks that use BuildContext to run inside build scopes.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _DisallowContextOutsideBuildVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _DisallowContextOutsideBuildVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _DisallowContextOutsideBuildVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null) {
      return;
    }
    if (enclosingHookScope(node) != null) {
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
    if (enclosingHookScope(node) != null) {
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
      rule.reportAtNode(contextArgument);
      return;
    }

    rule.reportAtNode(contextArgument ?? fallback);
  }
}
