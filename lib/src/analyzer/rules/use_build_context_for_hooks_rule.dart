import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class UseBuildContextForHooksRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_build_context_for_hooks',
    '{0} inside build scopes must pass context.',
    correctionMessage: 'Pass the build context as the first argument to {0}.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'oref.lint.use_build_context_for_hooks',
  );

  UseBuildContextForHooksRule()
    : super(
        name: 'use_build_context_for_hooks',
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
    final customHooks = buildCustomHookRegistry(context);
    var visitor = _UseBuildContextForHooksVisitor(this, skip, customHooks);
    registry.addMethodInvocation(this, visitor);
  }
}

class _UseBuildContextForHooksVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;
  final CustomHookRegistry customHooks;

  _UseBuildContextForHooksVisitor(this.rule, this.skip, this.customHooks);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null || !hook.isOptionalContext) {
      return;
    }

    final scope = enclosingHookScope(node, customHooks: customHooks);
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

    rule.reportAtNode(
      contextArgument ?? node.methodName,
      arguments: [hook.name],
    );
  }
}
