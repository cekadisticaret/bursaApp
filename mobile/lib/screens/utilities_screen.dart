import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.utilitiesInfo();
      if (mounted) setState(() => _data = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilities = (_data['utilities'] as Map?)?.cast<String, dynamic>() ?? _data;
    final providers = <String, dynamic>{};
    for (final key in ['buski', 'uedas', 'bursagaz', 'providers']) {
      if (utilities[key] != null) providers[key] = utilities[key];
    }

    return AppPage(
      title: 'Faturalar & tarifeler',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const Text(
                  'BUSKİ · UEDAŞ · Bursagaz güncel tarife ve iletişim özeti.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                if (providers.isEmpty)
                  const Text('Tarife verisi henüz yüklenmedi. Kısa süre içinde güncellenecek.', style: TextStyle(color: AppColors.muted))
                else
                  ...providers.entries.map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: AppShadows.card,
                      ),
                      child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
    );
  }
}
