import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class HookRequiresContextInBuildRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'hook_requires_context_in_build',
    'Hook calls in a widget build method must pass context.',
    correctionMessage: 'Pass the build context as the first argument.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.hook_requires_context_in_build',
  );

  HookRequiresContextInBuildRule()
    : super(
        name: 'hook_requires_context_in_build',
        description:
            'Require BuildContext when using Oref hooks in widget builds.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _HookRequiresContextInBuildVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _HookRequiresContextInBuildVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _HookRequiresContextInBuildVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null || !hook.isOptionalContext) {
      return;
    }

    final buildMethod = enclosingBuildMethod(node);
    if (buildMethod == null) {
      return;
    }

    if (isInsideControlFlow(node, buildMethod) ||
        isInsideNestedFunction(node, buildMethod)) {
      return;
    }

    final contextArgument = hook.contextArgument;
    if (isBuildContextExpression(contextArgument)) {
      return;
    }

    rule.reportAtNode(contextArgument ?? node.methodName);
  }
}
