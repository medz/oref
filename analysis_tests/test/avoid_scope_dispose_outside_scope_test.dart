import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/avoid_scope_dispose_outside_scope_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidScopeDisposeOutsideScopeRuleTest);
  });
}

@reflectiveTest
class AvoidScopeDisposeOutsideScopeRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidScopeDisposeOutsideScopeRule();
    super.setUp();
  }

  void test_reports_outside_scope() async {
    const code = r'''
import 'package:oref/oref.dart';

void helper() {
  onScopeDispose(() {});
}
''';
    final offset = code.indexOf('onScopeDispose');
    await assertDiagnostics(code, [lint(offset, 'onScopeDispose'.length)]);
  }

  void test_allows_inside_effect_scope() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

void helper(BuildContext context) {
  effectScope(context, () {
    onScopeDispose(() {});
  });
}
''');
  }
}
