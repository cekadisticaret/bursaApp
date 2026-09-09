import 'package:flutter/material.dart';

/// ListView ekranları için pull-to-refresh.
Widget appRefreshList({
  required Future<void> Function() onRefresh,
  EdgeInsetsGeometry? padding,
  required List<Widget> children,
}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: children,
    ),
  );
}

/// Harita / sabit yükseklikli içerik için pull-to-refresh.
Widget appRefreshBox({
  required Future<void> Function() onRefresh,
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    ),
  );
}
