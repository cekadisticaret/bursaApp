import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';

class AuthForgotPasswordScreen extends StatefulWidget {
  const AuthForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<AuthForgotPasswordScreen> createState() => _AuthForgotPasswordScreenState();
}

class _AuthForgotPasswordScreenState extends State<AuthForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _error;
  String? _success;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmail?.trim();
    if (initial != null && initial.isNotEmpty) {
      _email.text = initial;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trimmed = _email.text.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      setState(() {
        _error = 'Geçerli bir e-posta gir';
        _success = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final msg = await context.read<AuthStore>().api.forgotPassword(trimmed);
      if (!mounted) return;
      setState(() => _success = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Şifremi unuttum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yeni şifre e-posta ile',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kayıtlı e-posta adresine yeni geçici şifre gönderilir. Giriş yaptıktan sonra profilden değiştirebilirsin.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentDeep.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text(
                  _success!,
                  style: const TextStyle(color: AppColors.ink, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.nav,
                foregroundColor: AppColors.lime,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
              ),
              child: Text(_loading ? 'Gönderiliyor…' : 'Yeni şifre gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
