import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import 'auth_login_screen.dart';
import 'auth_register_screen.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  Future<void> _finish(BuildContext context, bool ok) async {
    if (!ok || !context.mounted) return;
    onSuccess?.call();
    Navigator.of(context).pop(true);
  }

  Future<void> _openLogin(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      appRoute(AuthLoginScreen(onSuccess: onSuccess)),
    );
    await _finish(context, ok == true);
  }

  Future<void> _openRegister(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      appRoute(AuthRegisterScreen(onSuccess: onSuccess)),
    );
    await _finish(context, ok == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE8DC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    color: AppColors.ink,
                    letterSpacing: -0.8,
                  ),
                  children: [
                    TextSpan(text: 'Bursa\'yı\n'),
                    TextSpan(
                      text: 'Keşfet',
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: AppColors.nav,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 24,
                      right: 24,
                      child: Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accentDeep.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(120),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      right: 36,
                      child: Container(
                        width: 72,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: const Icon(Icons.air_rounded, size: 42, color: AppColors.nav),
                      ),
                    ),
                    Positioned(
                      bottom: 28,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.lime.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentDeep, width: 3),
                        ),
                        child: const Icon(Icons.hiking_rounded, size: 46, color: AppColors.nav),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 48,
                      child: Icon(Icons.location_on_rounded, color: AppColors.coral.withValues(alpha: 0.85), size: 34),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'BursaApp ile şehrini tanı',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.nav,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Restoran, gezi, etkinlik ve nöbetçi eczane — hepsi tek rehberde.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => _openLogin(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.nav,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.nav),
                    ),
                    const SizedBox(width: 12),
                    const Text('Başlayalım!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => _openRegister(context),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.muted, fontSize: 15),
                    children: [
                      TextSpan(text: 'Hesabın yok mu? '),
                      TextSpan(
                        text: 'Kayıt ol',
                        style: TextStyle(
                          color: AppColors.nav,
                          fontWeight: FontWeight.w900,
                        ),
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
