import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/avoid_writes_in_computed_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidWritesInComputedRuleTest);
  });
}

@reflectiveTest
class AvoidWritesInComputedRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidWritesInComputedRule();
    super.setUp();
  }

  void test_reports_write_inside_computed() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

void helper(BuildContext context) {
  final counter = WritableSignal<int>();
  computed(context, () {
    counter.set(1);
    return 0;
  });
}
''';
    final offset = code.indexOf('set(1)');
    await assertDiagnostics(code, [lint(offset, 'set'.length)]);
  }

  void test_allows_write_outside_computed() async {
    await assertNoDiagnostics(r'''
import 'package:oref/oref.dart';

void helper() {
  final counter = WritableSignal<int>();
  counter.set(1);
}
''');
  }
}
