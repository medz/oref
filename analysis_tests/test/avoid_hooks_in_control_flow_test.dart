import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/avoid_hooks_in_control_flow_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHooksInControlFlowRuleTest);
  });
}

@reflectiveTest
class AvoidHooksInControlFlowRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidHooksInControlFlowRule();
    super.setUp();
  }

  void test_reports_hook_in_if() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (true) {
      signal(context, 0);
    }
    return Widget();
  }
}
''';
    final offset = code.indexOf('signal(');
    await assertDiagnostics(code, [lint(offset, 'signal'.length)]);
  }

  void test_allows_top_level_call() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    signal(context, 0);
    return Widget();
  }
}
''');
  }
}
