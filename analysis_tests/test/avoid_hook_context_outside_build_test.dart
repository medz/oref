import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:oref/src/analyzer/rules/avoid_hook_context_outside_build_rule.dart';

import 'support/oref_rule_harness.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHookContextOutsideBuildRuleTest);
  });
}

@reflectiveTest
class AvoidHookContextOutsideBuildRuleTest extends OrefRuleHarness {
  @override
  void setUp() {
    rule = AvoidHookContextOutsideBuildRule();
    super.setUp();
  }

  void test_reports_optional_context_outside_build() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class Helper {
  void run(BuildContext context) {
    signal(context, 0);
  }
}
''';
    final offset = code.indexOf('context, 0');
    await assertDiagnostics(code, [lint(offset, 'context'.length)]);
  }

  void test_allows_null_optional_context() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class Helper {
  void run(BuildContext context) {
    signal(null, 0);
  }
}
''');
  }

  void test_reports_required_context_outside_build() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class Helper {
  void run(BuildContext context) {
    watch(context, () => 1);
  }
}
''';
    final offset = code.indexOf('context, ()');
    await assertDiagnostics(code, [lint(offset, 'context'.length)]);
  }

  void test_reports_scoped_constructor_outside_build() async {
    const code = r'''
import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

class Helper {
  void run(BuildContext context) {
    ReactiveList.scoped(context);
  }
}
''';
    final offset = code.indexOf('context);');
    await assertDiagnostics(code, [lint(offset, 'context'.length)]);
  }
}
