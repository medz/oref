part of 'utils.dart';

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
