import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../utils/utils.dart';

class ReplaceContextWithNullFix extends ResolvedCorrectionProducer {
  static const FixKind kind = FixKind(
    'oref.fix.replace_context_with_null',
    DartFixKindPriority.standard,
    'Oref: replace {0} with `null` in {1}',
  );

  static const FixKind multiKind = FixKind(
    'oref.fix.replace_context_with_null.multi',
    DartFixKindPriority.standard,
    'Oref: replace contexts with null',
  );

  ReplaceContextWithNullFix({required super.context});

  List<String>? _arguments;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String>? get fixArguments => _arguments;

  @override
  FixKind get fixKind => kind;

  @override
  FixKind get multiFixKind => multiKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final methodInvocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (methodInvocation == null) {
      return;
    }

    final hook = matchHookInvocation(methodInvocation);
    if (hook == null || !hook.isOptionalContext) {
      return;
    }

    final contextArgument = hook.contextArgument;
    if (contextArgument == null ||
        isNullLiteral(contextArgument) ||
        !isBuildContextExpression(contextArgument)) {
      return;
    }

    final contextName = contextArgument.toSource();
    _arguments = [
      formatLintArgument(contextName),
      formatLintArgument(hook.name),
    ];

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(contextArgument), 'null');
    });
  }
}
