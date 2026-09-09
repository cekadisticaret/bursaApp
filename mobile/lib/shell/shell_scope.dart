import 'package:flutter/material.dart';

class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goTab, required super.child});

  final ValueChanged<int> goTab;

  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => goTab != oldWidget.goTab;
}
