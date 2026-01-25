import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class RequireContextInBuildRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'require_context_in_build',
    'Hook calls inside build scopes must pass context.',
    correctionMessage: 'Pass the build context as the first argument.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.require_context_in_build',
  );

  RequireContextInBuildRule()
    : super(
        name: 'require_context_in_build',
        description:
            'Require BuildContext when using Oref hooks in build scopes.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _RequireContextInBuildVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _RequireContextInBuildVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _RequireContextInBuildVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null || !hook.isOptionalContext) {
      return;
    }

    final scope = enclosingHookScope(node);
    if (scope == null) {
      return;
    }

    if (isInsideControlFlow(node, scope.node) ||
        isInsideNestedFunction(node, scope.node)) {
      return;
    }

    final contextArgument = hook.contextArgument;
    if (isBuildContextExpression(contextArgument)) {
      return;
    }

    rule.reportAtNode(contextArgument ?? node.methodName);
  }
}
