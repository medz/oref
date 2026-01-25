import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class EffectCleanupRequiresEffectRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'effect_cleanup_requires_effect',
    'Effect cleanup hooks must be called inside an effect callback.',
    correctionMessage: 'Call this inside the callback passed to effect().',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.effect_cleanup_requires_effect',
  );

  EffectCleanupRequiresEffectRule()
    : super(
        name: 'effect_cleanup_requires_effect',
        description:
            'Require onEffectCleanup/onEffectDispose to be inside effect().',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _EffectCleanupRequiresEffectVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _EffectCleanupRequiresEffectVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _EffectCleanupRequiresEffectVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    if (!isOrefFunctionInvocation(node, 'onEffectCleanup') &&
        !isOrefFunctionInvocation(node, 'onEffectDispose')) {
      return;
    }
    if (isInsideEffectCallback(node)) {
      return;
    }
    rule.reportAtNode(node.methodName);
  }
}
