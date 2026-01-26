part of 'utils.dart';

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

const _hookCallNames = {
  ..._optionalContextHookNames,
  ..._requiredContextHookNames,
};

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

  final Element enclosing = element.enclosingElement;
  final library = enclosing.library;

  if (library == null || !_isOrefLibrary(library.uri)) {
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

String formatLintArgument(String value) {
  if (value.isEmpty || value.contains('`')) {
    return value;
  }
  return '`$value`';
}
