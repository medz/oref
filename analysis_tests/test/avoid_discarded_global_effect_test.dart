import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../lib/src/analyzer/rules/avoid_discarded_global_effect_rule.dart';
import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDiscardedGlobalEffectRuleTest);
  });
}

@reflectiveTest
class AvoidDiscardedGlobalEffectRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidDiscardedGlobalEffectRule();
    super.setUp();
  }

  void test_reports_discarded_effect_in_build() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    effect(null, () {});
    return Widget();
  }
}
''';
    final offset = code.indexOf('effect(');
    await assertDiagnostics(code, [lint(offset, 'effect'.length)]);
  }

  void test_allows_assigned_effect() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cleanup = effect(null, () {});
    return Widget();
  }
}
''');
  }
}
