import 'package:flutter/widgets.dart';

class Dependency {
  Dependency(this.element);

  final Element element;

  Dependency? head;
  Dependency? next;

  void markNeedsBuild() {
    element.markNeedsBuild();
    for (Dependency? child = next; child != null; child = child.next) {
      child.markNeedsBuild();
    }
  }
}
