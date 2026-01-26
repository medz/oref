import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/use_build_context_for_hooks_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseBuildContextForHooksRuleTest);
  });
}

@reflectiveTest
class UseBuildContextForHooksRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = UseBuildContextForHooksRule();
    super.setUp();
  }

  void test_reports_missing_context() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    signal(null, 0);
    return Widget();
  }
}
''';
    final offset = code.indexOf('signal(null') + 'signal('.length;
    await assertDiagnostics(code, [lint(offset, 'null'.length)]);
  }

  void test_allows_context_argument() async {
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
