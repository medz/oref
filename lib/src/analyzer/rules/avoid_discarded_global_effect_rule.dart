import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class AvoidDiscardedGlobalEffectRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_discarded_global_effect',
    'Discarding the result of {0} can leak resources.',
    correctionMessage: 'Store the result if you need to stop {0} later.',
    severity: DiagnosticSeverity.WARNING,
    uniqueName: 'oref.lint.avoid_discarded_global_effect',
  );

  AvoidDiscardedGlobalEffectRule()
    : super(
        name: 'avoid_discarded_global_effect',
        description:
            'Warn when global effects/scopes are created and immediately discarded.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _AvoidDiscardedGlobalEffectVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _AvoidDiscardedGlobalEffectVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _AvoidDiscardedGlobalEffectVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
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

    if (isInsideTopLevelFunction(node)) {
      return;
    }

    rule.reportAtNode(
      node.methodName,
      arguments: [formatLintArgument(node.methodName.name)],
    );
  }
}
