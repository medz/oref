part of 'utils.dart';

class HookScope {
  HookScope.build(this.buildMethod) : builderFunction = null;
  HookScope.builder(this.builderFunction) : buildMethod = null;

  final MethodDeclaration? buildMethod;
  final FunctionExpression? builderFunction;

  AstNode get node => buildMethod ?? builderFunction!;
}

HookScope? enclosingHookScope(AstNode node, {CustomHookRegistry? customHooks}) {
  AstNode? current = node;
  while (current != null) {
    if (current is MethodDeclaration &&
        current.name.lexeme == 'build' &&
        isWidgetBuildMethod(current)) {
      return HookScope.build(current);
    }
    if (current is FunctionDeclaration) {
      final function = current.functionExpression;
      if (isHookBuilderFunction(function)) {
        return HookScope.builder(function);
      }
      if (isCustomHookFunctionDeclaration(current, customHooks: customHooks)) {
        return HookScope.builder(function);
      }
    }
    if (current is FunctionExpression) {
      if (isHookBuilderFunction(current) ||
          isCustomHookFunctionExpression(current, customHooks: customHooks)) {
        return HookScope.builder(current);
      }
    }
    current = current.parent;
  }
  return null;
}

MethodDeclaration? enclosingBuildMethod(
  AstNode node, {
  CustomHookRegistry? customHooks,
}) {
  final scope = enclosingHookScope(node, customHooks: customHooks);
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

bool isCustomHookFunctionDeclaration(
  FunctionDeclaration node, {
  CustomHookRegistry? customHooks,
}) {
  if (node.parent is! CompilationUnit) {
    return false;
  }
  if (customHooks != null) {
    return customHooks.isCustomHookFunctionDeclaration(node);
  }
  return buildContextParameterNameFromParameters(
        node.functionExpression.parameters,
      ) !=
      null;
}

bool isCustomHookFunctionExpression(
  FunctionExpression node, {
  CustomHookRegistry? customHooks,
}) {
  if (!isTopLevelVariableFunction(node)) {
    return false;
  }
  if (customHooks != null) {
    return customHooks.isCustomHookFunctionExpression(node);
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

AstNode customHookInvocationNameNode(FunctionExpressionInvocation node) {
  final target = node.function;
  if (target is SimpleIdentifier) {
    return target;
  }
  if (target is PrefixedIdentifier) {
    return target.identifier;
  }
  if (target is PropertyAccess) {
    return target.propertyName;
  }
  return target;
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
