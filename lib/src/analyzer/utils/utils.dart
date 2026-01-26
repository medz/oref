import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
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

const _hookCallNames = {
  ..._optionalContextHookNames,
  ..._requiredContextHookNames,
};

final Map<String, String?> _packageNameCache = {};
final Map<String, _ParsedCustomHookLibrary> _customHookLibraryCache = {};

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

class CustomHookRegistry {
  CustomHookRegistry._(this._customHooks, this._definingLibrary);

  final Set<Element> _customHooks;
  final LibraryElement? _definingLibrary;

  bool isCustomHookElement(Element? element) {
    final normalized = _normalizeCustomHookElement(element);
    if (normalized == null) {
      return false;
    }
    if (_customHooks.contains(normalized)) {
      return true;
    }

    final library = normalized.library;
    final definingLibrary = _definingLibrary;
    if (library == null ||
        (definingLibrary != null &&
            library.identifier == definingLibrary.identifier)) {
      return false;
    }

    final name = normalized.name;
    if (name == null) {
      return false;
    }

    final externalHooks = _externalCustomHookNamesForLibrary(library);
    return externalHooks.contains(name);
  }

  bool isCustomHookFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! CompilationUnit) {
      return false;
    }
    return isCustomHookElement(node.declaredFragment?.element);
  }

  bool isCustomHookFunctionExpression(FunctionExpression node) {
    final element = _topLevelVariableElementForFunctionExpression(node);
    if (element == null) {
      return false;
    }
    return isCustomHookElement(element);
  }

  bool isCustomHookInvocation(MethodInvocation node) {
    return isCustomHookElement(node.methodName.element);
  }

  bool isCustomHookInvocationExpression(FunctionExpressionInvocation node) {
    final element = _invocationTargetElement(node.function);
    return isCustomHookElement(element);
  }
}

CustomHookRegistry buildCustomHookRegistry(RuleContext context) {
  final candidates = <Element, _CustomHookCandidate>{};
  for (final unit in context.allUnits) {
    _collectCustomHookCandidates(unit.unit, candidates);
  }

  if (candidates.isEmpty) {
    return CustomHookRegistry._(<Element>{}, context.libraryElement);
  }

  final candidateElements = candidates.keys.toSet();
  for (final candidate in candidates.values) {
    final collector = _CustomHookCallCollector(candidateElements);
    candidate.functionExpression.body.accept(collector);
    candidate.callsHookDirectly = collector.callsHookDirectly;
    candidate.callsCandidates.addAll(collector.calledCandidates);
  }

  final customHooks = <Element>{};
  for (final candidate in candidates.values) {
    if (candidate.callsHookDirectly) {
      customHooks.add(candidate.element);
    }
  }

  var changed = true;
  while (changed) {
    changed = false;
    for (final candidate in candidates.values) {
      if (customHooks.contains(candidate.element)) {
        continue;
      }
      if (candidate.callsCandidates.any(customHooks.contains)) {
        customHooks.add(candidate.element);
        changed = true;
      }
    }
  }

  return CustomHookRegistry._(customHooks, context.libraryElement);
}

class _CustomHookCandidate {
  _CustomHookCandidate(this.element, this.functionExpression);

  final Element element;
  final FunctionExpression functionExpression;
  bool callsHookDirectly = false;
  final Set<Element> callsCandidates = {};
}

class _CustomHookCallCollector extends RecursiveAstVisitor<void> {
  _CustomHookCallCollector(this.candidates);

  final Set<Element> candidates;
  bool callsHookDirectly = false;
  final Set<Element> calledCandidates = {};

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {}

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (matchHookConstructor(node) != null) {
      callsHookDirectly = true;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (matchHookInvocation(node) != null) {
      callsHookDirectly = true;
    } else {
      final element = _normalizeCustomHookElement(node.methodName.element);
      if (element != null && candidates.contains(element)) {
        calledCandidates.add(element);
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final element = _normalizeCustomHookElement(
      _invocationTargetElement(node.function),
    );
    if (element != null && candidates.contains(element)) {
      calledCandidates.add(element);
    }
    super.visitFunctionExpressionInvocation(node);
  }
}

class _HookImportInfo {
  const _HookImportInfo({required this.hasUnprefixed, required this.prefixes});

  final bool hasUnprefixed;
  final Set<String> prefixes;

  bool get hasAny => hasUnprefixed || prefixes.isNotEmpty;

  bool allowsPrefix(String? name) {
    if (name == null) {
      return false;
    }
    return prefixes.contains(name);
  }
}

class _ParsedCustomHookLibrary {
  _ParsedCustomHookLibrary({
    required this.signature,
    required this.customHookNames,
  });

  final String signature;
  final Set<String> customHookNames;
}

class _NameHookCandidate {
  _NameHookCandidate(this.name);

  final String name;
  bool callsHookDirectly = false;
  final Set<String> callsCandidates = {};
}

class _UnresolvedCustomHookCallCollector extends RecursiveAstVisitor<void> {
  _UnresolvedCustomHookCallCollector(this.imports, this.candidateNames);

  final _HookImportInfo imports;
  final Set<String> candidateNames;
  bool callsHookDirectly = false;
  final Set<String> calledCandidates = {};

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {}

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isOrefHookConstructor(node, imports)) {
      callsHookDirectly = true;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isOrefHookInvocation(node, imports)) {
      callsHookDirectly = true;
    } else if (node.target == null &&
        candidateNames.contains(node.methodName.name)) {
      calledCandidates.add(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final target = node.function;
    if (target is SimpleIdentifier && candidateNames.contains(target.name)) {
      calledCandidates.add(target.name);
    }
    super.visitFunctionExpressionInvocation(node);
  }
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

void _collectCustomHookCandidates(
  CompilationUnit unit,
  Map<Element, _CustomHookCandidate> candidates,
) {
  for (final declaration in unit.declarations) {
    if (declaration is FunctionDeclaration) {
      final functionExpression = declaration.functionExpression;
      if (buildContextParameterNameFromParameters(
            functionExpression.parameters,
          ) ==
          null) {
        continue;
      }
      final element = _normalizeCustomHookElement(
        declaration.declaredFragment?.element,
      );
      if (element == null) {
        continue;
      }
      candidates.putIfAbsent(
        element,
        () => _CustomHookCandidate(element, functionExpression),
      );
      continue;
    }

    if (declaration is TopLevelVariableDeclaration) {
      final variables = declaration.variables.variables;
      for (final variable in variables) {
        final initializer = variable.initializer;
        if (initializer is! FunctionExpression) {
          continue;
        }
        if (buildContextParameterNameFromParameters(initializer.parameters) ==
            null) {
          continue;
        }
        final element = _normalizeCustomHookElement(
          variable.declaredFragment?.element,
        );
        if (element == null) {
          continue;
        }
        candidates.putIfAbsent(
          element,
          () => _CustomHookCandidate(element, initializer),
        );
      }
    }
  }
}

Element? _normalizeCustomHookElement(Element? element) {
  if (element is PropertyAccessorElement) {
    return element.variable;
  }
  return element;
}

Element? _topLevelVariableElementForFunctionExpression(
  FunctionExpression node,
) {
  if (!isTopLevelVariableFunction(node)) {
    return null;
  }
  final parent = node.parent;
  if (parent is! VariableDeclaration) {
    return null;
  }
  return _normalizeCustomHookElement(parent.declaredFragment?.element);
}

Element? _invocationTargetElement(Expression expression) {
  if (expression is SimpleIdentifier) {
    return expression.element;
  }
  if (expression is PrefixedIdentifier) {
    return expression.identifier.element;
  }
  if (expression is PropertyAccess) {
    return expression.propertyName.element;
  }
  return null;
}

Set<String> _externalCustomHookNamesForLibrary(LibraryElement library) {
  if (library.isInSdk) {
    return const {};
  }
  if (_isOrefLibrary(library.firstFragment.source.uri)) {
    return const {};
  }

  final key = library.identifier;
  final signature = _librarySignature(library);
  final cached = _customHookLibraryCache[key];
  if (cached != null && cached.signature == signature) {
    return cached.customHookNames;
  }

  final customHooks = _computeCustomHookNamesForLibrary(library);
  _customHookLibraryCache[key] = _ParsedCustomHookLibrary(
    signature: signature,
    customHookNames: customHooks,
  );
  return customHooks;
}

String _librarySignature(LibraryElement library) {
  final buffer = StringBuffer();
  for (final fragment in library.fragments) {
    final path = fragment.source.fullName;
    buffer.write(path);
    buffer.write(':');
    try {
      buffer.write(File(path).statSync().modified.millisecondsSinceEpoch);
    } on FileSystemException {
      buffer.write('0');
    }
    buffer.write('|');
  }
  return buffer.toString();
}

Set<String> _computeCustomHookNamesForLibrary(LibraryElement library) {
  final importInfo = _hookImportInfoForLibrary(library);
  if (!importInfo.hasAny) {
    return const {};
  }

  final candidateNames = _candidateHookNamesForLibrary(library);
  if (candidateNames.isEmpty) {
    return const {};
  }

  final candidates = <String, _NameHookCandidate>{
    for (final name in candidateNames) name: _NameHookCandidate(name),
  };

  for (final fragment in library.fragments) {
    final path = fragment.source.fullName;
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    String content;
    try {
      content = file.readAsStringSync();
    } on FileSystemException {
      continue;
    }

    final unit = parseString(
      content: content,
      featureSet: library.featureSet,
      path: path,
    ).unit;

    for (final declaration in unit.declarations) {
      if (declaration is FunctionDeclaration) {
        final name = declaration.name.lexeme;
        final candidate = candidates[name];
        if (candidate == null) {
          continue;
        }
        final collector = _UnresolvedCustomHookCallCollector(
          importInfo,
          candidateNames,
        );
        declaration.functionExpression.body.accept(collector);
        candidate.callsHookDirectly =
            candidate.callsHookDirectly || collector.callsHookDirectly;
        candidate.callsCandidates.addAll(collector.calledCandidates);
        continue;
      }

      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          final name = variable.name.lexeme;
          final candidate = candidates[name];
          if (candidate == null) {
            continue;
          }
          final initializer = variable.initializer;
          if (initializer is! FunctionExpression) {
            continue;
          }
          final collector = _UnresolvedCustomHookCallCollector(
            importInfo,
            candidateNames,
          );
          initializer.body.accept(collector);
          candidate.callsHookDirectly =
              candidate.callsHookDirectly || collector.callsHookDirectly;
          candidate.callsCandidates.addAll(collector.calledCandidates);
        }
      }
    }
  }

  final customHooks = <String>{};
  for (final candidate in candidates.values) {
    if (candidate.callsHookDirectly) {
      customHooks.add(candidate.name);
    }
  }

  var changed = true;
  while (changed) {
    changed = false;
    for (final candidate in candidates.values) {
      if (customHooks.contains(candidate.name)) {
        continue;
      }
      if (candidate.callsCandidates.any(customHooks.contains)) {
        customHooks.add(candidate.name);
        changed = true;
      }
    }
  }

  return customHooks;
}

Set<String> _candidateHookNamesForLibrary(LibraryElement library) {
  final candidateNames = <String>{};
  for (final function in library.topLevelFunctions) {
    final name = function.name;
    if (name == null) {
      continue;
    }
    final firstParam = _firstPositionalParameter(
      function.type.formalParameters,
    );
    if (firstParam == null || !isBuildContextType(firstParam.type)) {
      continue;
    }
    candidateNames.add(name);
  }

  for (final variable in library.topLevelVariables) {
    final name = variable.name;
    if (name == null) {
      continue;
    }
    final type = variable.type;
    if (type is! FunctionType) {
      continue;
    }
    final firstParam = _firstPositionalParameter(type.formalParameters);
    if (firstParam == null || !isBuildContextType(firstParam.type)) {
      continue;
    }
    candidateNames.add(name);
  }

  return candidateNames;
}

_HookImportInfo _hookImportInfoForLibrary(LibraryElement library) {
  var hasUnprefixed = false;
  final prefixes = <String>{};

  for (final fragment in library.fragments) {
    for (final import in fragment.libraryImports) {
      final imported = import.importedLibrary;
      if (imported == null) {
        continue;
      }
      if (!_isOrefLibrary(imported.firstFragment.source.uri)) {
        continue;
      }
      final prefixName = import.prefix?.name;
      if (prefixName == null) {
        hasUnprefixed = true;
      } else {
        prefixes.add(prefixName);
      }
    }
  }

  return _HookImportInfo(hasUnprefixed: hasUnprefixed, prefixes: prefixes);
}

bool _isOrefHookInvocation(MethodInvocation node, _HookImportInfo imports) {
  if (!_hookCallNames.contains(node.methodName.name)) {
    return false;
  }

  final target = node.target;
  if (target == null) {
    return imports.hasUnprefixed;
  }
  if (target is SimpleIdentifier) {
    return imports.allowsPrefix(target.name);
  }
  if (target is PrefixedIdentifier) {
    return imports.allowsPrefix(target.prefix.name);
  }
  if (target is PropertyAccess) {
    final targetTarget = target.target;
    if (targetTarget is SimpleIdentifier) {
      return imports.allowsPrefix(targetTarget.name);
    }
  }
  return false;
}

bool _isOrefHookConstructor(
  InstanceCreationExpression node,
  _HookImportInfo imports,
) {
  final constructorName = node.constructorName.name?.name;
  if (constructorName != 'scoped') {
    return false;
  }

  final namedType = node.constructorName.type;
  final name = namedType.name.lexeme;
  final prefix = namedType.importPrefix?.name.lexeme;

  if (!_scopedCollectionTypes.contains(name)) {
    return false;
  }

  if (prefix == null) {
    return imports.hasUnprefixed;
  }
  return imports.allowsPrefix(prefix);
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
