import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

const _optionalContextHookNames = {
  'signal',
  'computed',
  'writableComputed',
  'effect',
  'effectScope',
  'useAsyncData',
};

const _requiredContextHookNames = {
  'watch',
  'useMemoized',
  'useWidgetEffect',
  'useWidgetScope',
  'onMounted',
  'onUnmounted',
};

const _scopedCollectionTypes = {'ReactiveList', 'ReactiveMap', 'ReactiveSet'};

final Map<String, String?> _packageNameCache = {};

class HookCall {
  HookCall({
    required this.node,
    required this.name,
    required this.contextArgument,
    required this.isOptionalContext,
  });

  final AstNode node;
  final String name;
  final Expression? contextArgument;
  final bool isOptionalContext;

  bool get isRequiredContext => !isOptionalContext;
}

HookCall? matchHookInvocation(MethodInvocation node) {
  final element = node.methodName.element;
  if (element is! ExecutableElement) {
    return null;
  }
  final library = element.library;
  if (!_isOrefLibrary(library.uri)) {
    return null;
  }

  final name = element.name;
  if (name == null) {
    return null;
  }
  final firstArgument = firstPositionalArgument(node.argumentList);
  if (_optionalContextHookNames.contains(name)) {
    return HookCall(
      node: node,
      name: name,
      contextArgument: firstArgument,
      isOptionalContext: true,
    );
  }
  if (_requiredContextHookNames.contains(name)) {
    return HookCall(
      node: node,
      name: name,
      contextArgument: firstArgument,
      isOptionalContext: false,
    );
  }

  return null;
}

HookCall? matchHookConstructor(InstanceCreationExpression node) {
  final element = node.constructorName.element;
  if (element == null) {
    return null;
  }

  final enclosing = element.enclosingElement;

  final library = enclosing.library;
  if (!_isOrefLibrary(library.uri)) {
    return null;
  }

  final enclosingName = enclosing.name;
  if (enclosingName == null) {
    return null;
  }

  if (!_scopedCollectionTypes.contains(enclosingName)) {
    return null;
  }

  final constructorName = element.name;
  if (constructorName == null) {
    return null;
  }
  if (constructorName != 'scoped') {
    return null;
  }

  return HookCall(
    node: node,
    name: '$enclosingName.$constructorName',
    contextArgument: firstPositionalArgument(node.argumentList),
    isOptionalContext: false,
  );
}

Expression? firstPositionalArgument(ArgumentList argumentList) {
  for (final argument in argumentList.arguments) {
    if (argument is NamedExpression) {
      continue;
    }
    return argument;
  }
  return null;
}

MethodDeclaration? enclosingBuildMethod(AstNode node) {
  final method = node.thisOrAncestorOfType<MethodDeclaration>();
  if (method == null || method.name.lexeme != 'build') {
    return null;
  }
  if (!isWidgetBuildMethod(method)) {
    return null;
  }
  return method;
}

bool isWidgetBuildMethod(MethodDeclaration method) {
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

bool isInsideControlFlow(AstNode node, AstNode stopAt) {
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

bool isInsideNestedFunction(AstNode node, AstNode stopAt) {
  AstNode? current = node.parent;
  while (current != null && current != stopAt) {
    if (current is FunctionExpression || current is FunctionDeclaration) {
      return true;
    }
    current = current.parent;
  }
  return false;
}

bool isNullLiteral(Expression? expression) => expression is NullLiteral;

bool isBuildContextExpression(Expression? expression) {
  if (expression == null) {
    return false;
  }
  if (expression is SimpleIdentifier) {
    if (expression.name == 'context') {
      return true;
    }
  }
  if (expression is PrefixedIdentifier) {
    if (expression.identifier.name == 'context') {
      return true;
    }
  }
  if (expression is PropertyAccess) {
    if (expression.propertyName.name == 'context') {
      return true;
    }
  }
  return isBuildContextType(expression.staticType);
}

bool isBuildContextType(DartType? type) {
  if (type == null || type.isDartCoreNull) {
    return false;
  }
  if (type is InterfaceType) {
    return _isFlutterType(type, 'BuildContext');
  }
  if (type is TypeParameterType) {
    return isBuildContextType(type.bound);
  }
  return false;
}

String? buildContextParameterName(MethodDeclaration method) {
  final parameters = method.parameters?.parameters;
  if (parameters == null || parameters.isEmpty) {
    return null;
  }

  FormalParameter parameter = parameters.first;
  if (parameter is DefaultFormalParameter) {
    parameter = parameter.parameter;
  }

  final element = parameter.declaredFragment?.element;
  final name = parameter.name?.lexeme;
  if (name == null) {
    return null;
  }
  if (element == null || !isBuildContextType(element.type)) {
    return null;
  }
  return name;
}

bool shouldSkipHookLint(RuleContext context) {
  return _isOrefPackage(context);
}

bool _isOrefPackage(RuleContext context) {
  final package = context.package;
  if (package == null) {
    return false;
  }
  final rootPath = package.root.path;
  final name = _packageNameCache.putIfAbsent(
    rootPath,
    () => _readPackageName(rootPath),
  );
  return name == 'oref';
}

String? _readPackageName(String rootPath) {
  final pubspec = File('$rootPath${Platform.pathSeparator}pubspec.yaml');
  if (!pubspec.existsSync()) {
    return null;
  }
  try {
    for (final line in pubspec.readAsLinesSync()) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('name:')) {
        return trimmed
            .substring('name:'.length)
            .trim()
            .split(RegExp(r'\s'))
            .first;
      }
    }
  } on FileSystemException {
    return null;
  }
  return null;
}

bool _isFlutterWidgetType(InterfaceType type) {
  return _isFlutterType(type, 'Widget');
}

bool _isFlutterStateType(InterfaceType type) {
  return _isFlutterType(type, 'State');
}

bool _isFlutterType(InterfaceType type, String name) {
  final element = type.element;
  if (element.name != name) {
    return false;
  }

  final uri = element.library.uri;
  return uri.scheme == 'package' && uri.path.startsWith('flutter/');
}

bool _isOrefLibrary(Uri uri) {
  return uri.scheme == 'package' && uri.path.startsWith('oref/');
}
