import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../navigation/app_routes.dart';
import '../screens/auth_welcome_screen.dart';

/// Karşılama → giriş / kayıt akışını açar. Başarılı olursa `true` döner.
Future<bool> openAuthFlow(BuildContext context, {VoidCallback? onSuccess}) async {
  final auth = context.read<AuthStore>();
  if (auth.isLoggedIn) {
    onSuccess?.call();
    return true;
  }
  final ok = await Navigator.push<bool>(
    context,
    appRoute(AuthWelcomeScreen(onSuccess: onSuccess)),
  );
  return ok == true;
}

@Deprecated('openAuthFlow kullanın')
Future<void> showLoginSheet(BuildContext context, {VoidCallback? onSuccess}) async {
  await openAuthFlow(context, onSuccess: onSuccess);
}

Future<void> requireAuth(BuildContext context, VoidCallback onOk) async {
  final auth = context.read<AuthStore>();
  if (auth.isLoggedIn) {
    onOk();
    return;
  }
  final ok = await openAuthFlow(context);
  if (ok && context.mounted) {
    onOk();
  }
}
