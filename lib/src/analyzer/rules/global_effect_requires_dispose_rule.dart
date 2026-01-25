import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class GlobalEffectRequiresDisposeRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'global_effect_requires_dispose',
    'Global effects should be stored and disposed to avoid leaks.',
    correctionMessage: 'Store the disposer and call it when no longer needed.',
    severity: DiagnosticSeverity.WARNING,
    uniqueName: 'LintCode.global_effect_requires_dispose',
  );

  GlobalEffectRequiresDisposeRule()
    : super(
        name: 'global_effect_requires_dispose',
        description:
            'Warn when global effects/scopes are created without storing them.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _GlobalEffectRequiresDisposeVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _GlobalEffectRequiresDisposeVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _GlobalEffectRequiresDisposeVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    if (enclosingHookScope(node) != null) {
      return;
    }
    if (!isOrefFunctionInvocation(node, 'effect') &&
        !isOrefFunctionInvocation(node, 'effectScope') &&
        !isOrefFunctionInvocation(node, 'useAsyncData')) {
      return;
    }

    final contextArgument = firstPositionalArgument(node.argumentList);
    if (!isNullLiteral(contextArgument)) {
      return;
    }

    if (node.parent is! ExpressionStatement) {
      return;
    }

    rule.reportAtNode(node.methodName);
  }
}
