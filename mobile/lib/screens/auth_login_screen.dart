import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import 'auth_register_screen.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthStore>().savedEmail;
    if (saved != null && saved.isNotEmpty) {
      _email.text = saved;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final auth = context.read<AuthStore>();
    try {
      await auth.login(_email.text, _password.text);
      if (!mounted) return;
      await auth.refreshUser();
      widget.onSuccess?.call();
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openRegister() async {
    final ok = await Navigator.push<bool>(
      context,
      appRoute(AuthRegisterScreen(onSuccess: widget.onSuccess)),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Giriş yap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AutofillGroup(
        child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hesabınla devam et',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Beğeni, yorum ve etkinlik için giriş yap.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Şifre',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.nav,
                foregroundColor: AppColors.lime,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              child: Text(auth.loading ? 'Giriş yapılıyor…' : 'Giriş yap'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _openRegister,
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(color: AppColors.muted),
                  children: [
                    TextSpan(text: 'Hesabın yok mu? '),
                    TextSpan(
                      text: 'Kayıt ol',
                      style: TextStyle(color: AppColors.nav, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
