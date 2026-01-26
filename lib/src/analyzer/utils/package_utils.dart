part of 'utils.dart';

final Map<String, String?> _packageNameCache = {};
final RegExp _whitespaceRegExp = RegExp(r'\s');

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
            .split(_whitespaceRegExp)
            .first;
      }
    }
  } on FileSystemException {
    return null;
  }
  return null;
}

bool _isOrefLibrary(Uri uri) {
  return uri.scheme == 'package' && uri.path.startsWith('oref/');
}
