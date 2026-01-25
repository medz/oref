import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class HookInNestedFunctionRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'hook_in_nested_function',
    'Hooks must not be called inside nested functions in build.',
    correctionMessage: 'Move the hook to the top level of build.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.hook_in_nested_function',
  );

  HookInNestedFunctionRule()
    : super(
        name: 'hook_in_nested_function',
        description:
            'Disallow calling Oref hooks inside nested functions in build.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _HookInNestedFunctionVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _HookInNestedFunctionVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _HookInNestedFunctionVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    final hook = matchHookInvocation(node);
    if (hook == null) {
      return;
    }
    final buildMethod = enclosingBuildMethod(node);
    if (buildMethod == null) {
      return;
    }
    if (!isInsideNestedFunction(node, buildMethod)) {
      return;
    }
    rule.reportAtNode(node.methodName);
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
    final buildMethod = enclosingBuildMethod(node);
    if (buildMethod == null) {
      return;
    }
    if (!isInsideNestedFunction(node, buildMethod)) {
      return;
    }
    rule.reportAtNode(node.constructorName);
  }
}
