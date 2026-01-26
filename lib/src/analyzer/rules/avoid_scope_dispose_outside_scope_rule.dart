import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class AvoidScopeDisposeOutsideScopeRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_scope_dispose_outside_scope',
    '{0} must be called inside an effect scope callback.',
    correctionMessage:
        'Call {0} only inside the callback passed to effectScope().',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'oref.lint.avoid_scope_dispose_outside_scope',
  );

  AvoidScopeDisposeOutsideScopeRule()
    : super(
        name: 'avoid_scope_dispose_outside_scope',
        description: 'Avoid calling onScopeDispose outside effectScope().',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _AvoidScopeDisposeOutsideScopeVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _AvoidScopeDisposeOutsideScopeVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _AvoidScopeDisposeOutsideScopeVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    if (!isOrefFunctionInvocation(node, 'onScopeDispose')) {
      return;
    }
    if (isInsideEffectScopeCallback(node)) {
      return;
    }
    rule.reportAtNode(node.methodName, arguments: [node.methodName.name]);
  }
}
