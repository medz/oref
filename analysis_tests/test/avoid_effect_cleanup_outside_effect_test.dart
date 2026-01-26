import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../lib/src/analyzer/rules/avoid_effect_cleanup_outside_effect_rule.dart';
import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEffectCleanupOutsideEffectRuleTest);
  });
}

@reflectiveTest
class AvoidEffectCleanupOutsideEffectRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidEffectCleanupOutsideEffectRule();
    super.setUp();
  }

  void test_reports_cleanup_outside_effect() async {
    const code = r'''
import 'package:oref/oref.dart';

void helper() {
  onEffectCleanup(() {});
}
''';
    final offset = code.indexOf('onEffectCleanup');
    await assertDiagnostics(code, [lint(offset, 'onEffectCleanup'.length)]);
  }

  void test_allows_cleanup_inside_effect() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

void helper(BuildContext context) {
  effect(context, () {
    onEffectCleanup(() {});
  });
}
''');
  }
}
