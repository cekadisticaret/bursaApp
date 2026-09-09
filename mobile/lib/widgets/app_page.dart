import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.onRefresh,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
        actions: actions,
      ),
      body: onRefresh == null
          ? body
          : RefreshIndicator(onRefresh: onRefresh!, child: body),
    );
  }
}
