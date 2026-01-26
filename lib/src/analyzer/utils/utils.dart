import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
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

class HookScope {
  HookScope.build(this.buildMethod) : builderFunction = null;
  HookScope.builder(this.builderFunction) : buildMethod = null;

  final MethodDeclaration? buildMethod;
  final FunctionExpression? builderFunction;

  AstNode get node => buildMethod ?? builderFunction!;
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

FormalParameter? _firstPositionalFormalParameter(
  FormalParameterList? parameterList,
) {
  if (parameterList == null) {
    return null;
  }
  for (final parameter in parameterList.parameters) {
    if (parameter.isNamed) {
      continue;
    }
    return parameter;
  }
  return null;
}

FormalParameterElement? _firstPositionalParameter(
  List<FormalParameterElement> parameters,
) {
  for (final parameter in parameters) {
    if (parameter.isNamed) {
      continue;
    }
    return parameter;
  }
  return null;
}

HookScope? enclosingHookScope(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is MethodDeclaration &&
        current.name.lexeme == 'build' &&
        isWidgetBuildMethod(current)) {
      return HookScope.build(current);
    }
    if (current is FunctionDeclaration &&
        isCustomHookFunctionDeclaration(current)) {
      return HookScope.builder(current.functionExpression);
    }
    if (current is FunctionExpression &&
        (isHookBuilderFunction(current) ||
            isCustomHookFunctionExpression(current))) {
      return HookScope.builder(current);
    }
    if (current is FunctionDeclaration) {
      final function = current.functionExpression;
      if (isHookBuilderFunction(function)) {
        return HookScope.builder(function);
      }
    }
    current = current.parent;
  }
  return null;
}

MethodDeclaration? enclosingBuildMethod(AstNode node) {
  final scope = enclosingHookScope(node);
  return scope?.buildMethod;
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

bool isHookBuilderFunction(FunctionExpression node) {
  final type = node.staticType;
  if (type is! FunctionType) {
    return false;
  }

  final firstParam = _firstPositionalParameter(type.formalParameters);
  if (firstParam == null || !isBuildContextType(firstParam.type)) {
    return false;
  }

  return isWidgetType(type.returnType);
}

bool isCustomHookFunctionDeclaration(FunctionDeclaration node) {
  if (node.parent is! CompilationUnit) {
    return false;
  }
  return buildContextParameterNameFromParameters(
        node.functionExpression.parameters,
      ) !=
      null;
}

bool isCustomHookFunctionExpression(FunctionExpression node) {
  if (!isTopLevelVariableFunction(node)) {
    return false;
  }
  return buildContextParameterNameFromParameters(node.parameters) != null;
}

bool isTopLevelVariableFunction(FunctionExpression node) {
  final parent = node.parent;
  if (parent is! VariableDeclaration) {
    return false;
  }
  final list = parent.parent;
  if (list is! VariableDeclarationList) {
    return false;
  }
  final declaration = list.parent;
  return declaration is TopLevelVariableDeclaration &&
      declaration.parent is CompilationUnit;
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
        current is SwitchExpression ||
        (current is BinaryExpression &&
            (current.operator.type == TokenType.AMPERSAND_AMPERSAND ||
                current.operator.type == TokenType.BAR_BAR ||
                current.operator.type == TokenType.QUESTION_QUESTION))) {
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

bool isWidgetType(DartType? type) {
  if (type == null || type.isDartCoreNull) {
    return false;
  }
  if (type is InterfaceType) {
    if (_isFlutterWidgetType(type)) {
      return true;
    }
    for (final supertype in type.allSupertypes) {
      if (_isFlutterWidgetType(supertype)) {
        return true;
      }
    }
    return false;
  }
  if (type is TypeParameterType) {
    return isWidgetType(type.bound);
  }
  return false;
}

String? buildContextParameterName(MethodDeclaration method) {
  return buildContextParameterNameFromParameters(method.parameters);
}

String? buildContextParameterNameFromParameters(
  FormalParameterList? parameters,
) {
  final parameter = _firstPositionalFormalParameter(parameters);
  if (parameter == null) {
    return null;
  }

  FormalParameter unwrapped = parameter;
  if (unwrapped is DefaultFormalParameter) {
    unwrapped = unwrapped.parameter;
  }

  final element = unwrapped.declaredFragment?.element;
  final name = unwrapped.name?.lexeme;
  if (name == null) {
    return null;
  }
  if (element == null || !isBuildContextType(element.type)) {
    return null;
  }
  return name;
}

String? hookScopeContextName(HookScope scope) {
  if (scope.buildMethod != null) {
    return buildContextParameterName(scope.buildMethod!);
  }
  if (scope.builderFunction != null) {
    return buildContextParameterNameFromParameters(
      scope.builderFunction!.parameters,
    );
  }
  return null;
}

bool isOrefFunctionInvocation(MethodInvocation node, String name) {
  final element = node.methodName.element;
  if (element is! ExecutableElement) {
    return false;
  }
  if (element.name != name) {
    return false;
  }
  return _isOrefLibrary(element.library.uri);
}

int? positionalArgumentIndex(Expression expression, ArgumentList argumentList) {
  var index = 0;
  for (final argument in argumentList.arguments) {
    if (argument is NamedExpression) {
      continue;
    }
    if (identical(argument, expression)) {
      return index;
    }
    index++;
  }
  return null;
}

bool isComputedGetterFunction(FunctionExpression node) {
  final argumentContainer = _argumentContainer(node);
  if (argumentContainer == null) {
    return false;
  }

  if (argumentContainer is NamedExpression) {
    return false;
  }

  final argumentList = argumentContainer.parent;
  if (argumentList is! ArgumentList) {
    return false;
  }

  final invocation = argumentList.parent;
  if (invocation is! MethodInvocation) {
    return false;
  }
  if (!isOrefFunctionInvocation(invocation, 'computed')) {
    return false;
  }

  final index = positionalArgumentIndex(argumentContainer, argumentList);
  return index == 1;
}

bool isWritableComputedGetterFunction(FunctionExpression node) {
  final argumentContainer = _argumentContainer(node);
  if (argumentContainer is! NamedExpression) {
    return false;
  }
  if (argumentContainer.name.label.name != 'get') {
    return false;
  }

  final argumentList = argumentContainer.parent;
  if (argumentList is! ArgumentList) {
    return false;
  }

  final invocation = argumentList.parent;
  if (invocation is! MethodInvocation) {
    return false;
  }
  return isOrefFunctionInvocation(invocation, 'writableComputed');
}

bool isInsideEffectCallback(AstNode node) {
  return _isInsideCallback(node, _isEffectCallbackFunction);
}

bool isInsideEffectScopeCallback(AstNode node) {
  return _isInsideCallback(node, _isEffectScopeCallbackFunction);
}

bool isInsideComputedGetter(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression) {
      if (isComputedGetterFunction(current) ||
          isWritableComputedGetterFunction(current)) {
        return true;
      }
    }
    if (current is FunctionDeclaration) {
      final function = current.functionExpression;
      if (isComputedGetterFunction(function) ||
          isWritableComputedGetterFunction(function)) {
        return true;
      }
    }
    current = current.parent;
  }
  return false;
}

bool _isInsideCallback(
  AstNode node,
  bool Function(FunctionExpression) predicate,
) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression && predicate(current)) {
      return true;
    }
    if (current is FunctionDeclaration) {
      final function = current.functionExpression;
      if (predicate(function)) {
        return true;
      }
    }
    current = current.parent;
  }
  return false;
}

bool _isEffectCallbackFunction(FunctionExpression node) {
  return _isCallbackArgument(node, 'effect', positionalIndex: 1);
}

bool _isEffectScopeCallbackFunction(FunctionExpression node) {
  return _isCallbackArgument(node, 'effectScope', positionalIndex: 1);
}

bool _isCallbackArgument(
  FunctionExpression node,
  String methodName, {
  int? positionalIndex,
  String? named,
}) {
  final argumentContainer = _argumentContainer(node);
  if (argumentContainer == null) {
    return false;
  }

  final argumentList = argumentContainer.parent;
  if (argumentList is! ArgumentList) {
    return false;
  }

  final invocation = argumentList.parent;
  if (invocation is! MethodInvocation) {
    return false;
  }
  if (!isOrefFunctionInvocation(invocation, methodName)) {
    return false;
  }

  if (named != null) {
    return argumentContainer is NamedExpression &&
        argumentContainer.name.label.name == named;
  }

  if (positionalIndex != null) {
    if (argumentContainer is NamedExpression) {
      return false;
    }
    return positionalArgumentIndex(argumentContainer, argumentList) ==
        positionalIndex;
  }

  return false;
}

Expression? _argumentContainer(FunctionExpression node) {
  final parent = node.parent;
  if (parent is NamedExpression) {
    return parent;
  }
  if (parent is ArgumentList) {
    return node;
  }
  if (parent is ParenthesizedExpression &&
      parent.parent is ArgumentList &&
      parent.expression == node) {
    return parent;
  }
  return parent is Expression ? parent : null;
}

bool isWritableSignalType(DartType? type) {
  if (type == null || type.isDartCoreNull) {
    return false;
  }
  if (type is InterfaceType) {
    if (_isWritableSignalElement(type.element)) {
      return true;
    }
    for (final supertype in type.allSupertypes) {
      if (_isWritableSignalElement(supertype.element)) {
        return true;
      }
    }
    return false;
  }
  if (type is TypeParameterType) {
    return isWritableSignalType(type.bound);
  }
  return false;
}

bool _isWritableSignalElement(InterfaceElement element) {
  if (element.name != 'WritableSignal' && element.name != 'WritableComputed') {
    return false;
  }
  final uri = element.library.uri;
  return uri.scheme == 'package' &&
      (uri.path.startsWith('oref/') || uri.path.startsWith('alien_signals/'));
}

DartType? methodInvocationTargetType(MethodInvocation node) {
  final target = node.target;
  if (target != null) {
    return target.staticType;
  }
  final parent = node.parent;
  if (parent is CascadeExpression) {
    return parent.target.staticType;
  }
  return null;
}

bool shouldSkipHookLint(RuleContext context) {
  return _isOrefPackage(context);
}

bool isInsideTopLevelFunction(AstNode node) {
  final function = node.thisOrAncestorOfType<FunctionDeclaration>();
  if (function == null) {
    return false;
  }
  return function.parent is CompilationUnit;
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
