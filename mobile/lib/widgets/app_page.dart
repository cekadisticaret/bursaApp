import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, required this.body, this.actions});

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
        actions: actions,
      ),
      body: body,
    );
  }
}
