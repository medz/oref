part of 'utils.dart';

final Map<String, _ParsedCustomHookLibrary> _customHookLibraryCache = {};

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
  final session = library.session;
  final buffer = StringBuffer();
  for (final fragment in library.fragments) {
    final path = fragment.source.fullName;
    buffer.write(path);
    buffer.write(':');
    final parsed = session.getParsedUnit(path);
    if (parsed is ParsedUnitResult) {
      // ParsedUnitResult.content reflects overlays, and file.modificationStamp
      // is overlay-aware when the session uses OverlayResourceProvider.
      buffer.write(parsed.file.modificationStamp);
      buffer.write(':');
      buffer.write(parsed.content.hashCode);
    } else {
      final file = session.resourceProvider.getFile(path);
      buffer.write(file.modificationStamp);
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

  final session = library.session;
  for (final fragment in library.fragments) {
    final path = fragment.source.fullName;
    final parsed = session.getParsedUnit(path);
    if (parsed is! ParsedUnitResult) {
      continue;
    }
    final unit = parsed.unit;

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
