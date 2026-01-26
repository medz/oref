import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/avoid_hooks_in_nested_functions_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHooksInNestedFunctionsRuleTest);
  });
}

@reflectiveTest
class AvoidHooksInNestedFunctionsRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidHooksInNestedFunctionsRule();
    super.setUp();
  }

  void test_reports_nested_hook() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    void inner() {
      signal(context, 0);
    }
    inner();
    return Widget();
  }
}
''';
    final offset = code.indexOf('signal(context, 0);');
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
