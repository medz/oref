part of 'utils.dart';

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
