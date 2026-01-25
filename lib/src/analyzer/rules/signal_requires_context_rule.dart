import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

class SignalRequiresContextRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'signal_requires_context',
    'Signal calls in a widget build method must pass context.',
    correctionMessage: 'Pass the build context as the first argument.',
    severity: DiagnosticSeverity.ERROR,
    uniqueName: 'LintCode.signal_requires_context',
  );

  SignalRequiresContextRule()
    : super(
        name: 'signal_requires_context',
        description:
            'Require a BuildContext when calling signal() in widget builds.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _SignalRequiresContextVisitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _SignalRequiresContextVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _SignalRequiresContextVisitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isSignalInvocation(node)) {
      return;
    }

    final buildMethod = node.thisOrAncestorOfType<MethodDeclaration>();
    if (buildMethod == null || buildMethod.name.lexeme != 'build') {
      return;
    }

    if (!_isWidgetBuild(buildMethod)) {
      return;
    }

    if (_isInsideControlFlow(node, buildMethod)) {
      return;
    }

    if (_hasContextArgument(node)) {
      return;
    }

    final arguments = node.argumentList.arguments;
    if (arguments.isNotEmpty) {
      rule.reportAtNode(arguments.first);
    } else {
      rule.reportAtNode(node.methodName);
    }
  }

  bool _isWidgetBuild(MethodDeclaration method) {
    final parent = method.thisOrAncestorOfType<ClassDeclaration>();
    if (parent == null) {
      return false;
    }

    final element = parent.declaredFragment?.element;
    if (element == null) {
      return false;
    }

    if (_isFlutterWidgetType(element.thisType) ||
        _isFlutterStateType(element.thisType)) {
      return true;
    }

    for (final supertype in element.allSupertypes) {
      if (_isFlutterWidgetType(supertype) || _isFlutterStateType(supertype)) {
        return true;
      }
    }

    return false;
  }

  bool _isFlutterWidgetType(InterfaceType type) {
    return _isFlutterType(type, 'Widget');
  }

  bool _isFlutterStateType(InterfaceType type) {
    return _isFlutterType(type, 'State');
  }

  bool _isSignalInvocation(MethodInvocation node) {
    final element = node.methodName.element;
    if (element == null || element.name != 'signal') {
      return false;
    }

    final library = element.library;
    if (library == null) {
      return false;
    }
    final uri = library.uri;
    return uri.scheme == 'package' && uri.path.startsWith('oref/');
  }

  bool _isInsideControlFlow(AstNode node, AstNode stopAt) {
    AstNode? current = node.parent;
    while (current != null && current != stopAt) {
      if (current is IfStatement ||
          current is IfElement ||
          current is ConditionalExpression ||
          current is ForStatement ||
          current is ForElement ||
          current is WhileStatement ||
          current is DoStatement ||
          current is SwitchStatement ||
          current is SwitchExpression) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _hasContextArgument(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) {
      return false;
    }

    final first = arguments.first;
    if (first is NamedExpression) {
      return false;
    }

    if (first is NullLiteral) {
      return false;
    }

    if (_looksLikeContextExpression(first)) {
      return true;
    }

    return _isBuildContextType(first.staticType);
  }

  bool _looksLikeContextExpression(Expression expression) {
    if (expression is SimpleIdentifier) {
      return expression.name == 'context';
    }
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name == 'context';
    }
    if (expression is PropertyAccess) {
      return expression.propertyName.name == 'context';
    }
    return false;
  }

  bool _isBuildContextType(DartType? type) {
    if (type == null || type.isDartCoreNull) {
      return false;
    }
    if (type is InterfaceType) {
      return _isFlutterType(type, 'BuildContext');
    }
    if (type is TypeParameterType) {
      return _isBuildContextType(type.bound);
    }
    return false;
  }

  bool _isFlutterType(InterfaceType type, String name) {
    final element = type.element;
    if (element.name != name) {
      return false;
    }

    final uri = element.library.uri;
    return uri.scheme == 'package' && uri.path.startsWith('flutter/');
  }
}
