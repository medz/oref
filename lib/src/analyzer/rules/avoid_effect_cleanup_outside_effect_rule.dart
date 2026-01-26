import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class AvoidEffectCleanupOutsideEffectRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_effect_cleanup_outside_effect',
    '{0} must be called inside an effect callback.',
    correctionMessage: 'Call {0} only inside the callback passed to effect().',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'oref.lint.avoid_effect_cleanup_outside_effect',
  );

  AvoidEffectCleanupOutsideEffectRule()
    : super(
        name: 'avoid_effect_cleanup_outside_effect',
        description:
            'Avoid calling onEffectCleanup/onEffectDispose outside effect().',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _AvoidEffectCleanupOutsideEffectVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _AvoidEffectCleanupOutsideEffectVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _AvoidEffectCleanupOutsideEffectVisitor(this.rule, this.skip);

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
    rule.reportAtNode(
      node.methodName,
      arguments: [formatLintArgument(node.methodName.name)],
    );
  }
}
