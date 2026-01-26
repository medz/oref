import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../utils/utils.dart';

class NoWritesInComputedRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_writes_in_computed',
    'Computed getters must be pure and must not write to signals (found {0}).',
    correctionMessage: 'Move writes to an effect or event handler.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'oref.lint.no_writes_in_computed',
  );

  NoWritesInComputedRule()
    : super(
        name: 'no_writes_in_computed',
        description: 'Disallow writes to signals inside computed getters.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final skip = shouldSkipHookLint(context);
    var visitor = _NoWritesInComputedVisitor(this, skip);
    registry.addMethodInvocation(this, visitor);
  }
}

class _NoWritesInComputedVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final bool skip;

  _NoWritesInComputedVisitor(this.rule, this.skip);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (skip) {
      return;
    }
    if (node.methodName.name != 'set') {
      return;
    }
    if (!isInsideComputedGetter(node)) {
      return;
    }
    final targetType = methodInvocationTargetType(node);
    if (!isWritableSignalType(targetType)) {
      return;
    }
    rule.reportAtNode(node.methodName, arguments: [_writeTargetName(node)]);
  }

  String _writeTargetName(MethodInvocation node) {
    final target = node.target;
    if (target == null) {
      return 'signal';
    }
    final name = target.toSource();
    if (name.isEmpty) {
      return 'signal';
    }
    return name;
  }
}
