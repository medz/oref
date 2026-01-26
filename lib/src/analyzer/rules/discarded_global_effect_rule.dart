import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class DiscardedGlobalEffectRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'discarded_global_effect',
    'Global effects created without storing the disposer can leak resources.',
    correctionMessage: 'Store the disposer if you need to stop it later.',
    severity: DiagnosticSeverity.WARNING,
    uniqueName: 'LintCode.discarded_global_effect',
  );

  DiscardedGlobalEffectRule()
    : super(
        name: 'discarded_global_effect',
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
    var visitor = _DiscardedGlobalEffectVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _DiscardedGlobalEffectVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _DiscardedGlobalEffectVisitor(this.rule, this.skip);

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

    rule.reportAtNode(node.methodName);
  }
}
