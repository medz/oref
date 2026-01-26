import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/avoid_custom_hooks_outside_build_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCustomHooksOutsideBuildRuleTest);
  });
}

@reflectiveTest
class AvoidCustomHooksOutsideBuildRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidCustomHooksOutsideBuildRule();
    super.setUp();
  }

  void test_reports_outside_build() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

void useLocalCounter(BuildContext context) {
  signal(context, 0);
}

class Helper {
  void run(BuildContext context) {
    useLocalCounter(context);
  }
}
''';
    final offset = code.indexOf('useLocalCounter(context);');
    await assertDiagnostics(code, [lint(offset, 'useLocalCounter'.length)]);
  }

  void test_allows_inside_build() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

void useLocalCounter(BuildContext context) {
  signal(context, 0);
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    useLocalCounter(context);
    return Widget();
  }
}
''');
  }
}
