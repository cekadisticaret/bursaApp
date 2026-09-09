import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';

class TeleferikScreen extends StatefulWidget {
  const TeleferikScreen({super.key});

  @override
  State<TeleferikScreen> createState() => _TeleferikScreenState();
}

class _TeleferikScreenState extends State<TeleferikScreen> {
  Map<String, dynamic>? _data;
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
      final data = await auth.api.teleferikInfo();
      if (mounted) setState(() => _data = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stations = (_data?['stations'] as List? ?? []).cast<Map>();
    final prices = (_data?['prices'] as List? ?? []).cast<Map>();
    final hours = (_data?['hours'] as List? ?? []).cast<Map>();

    return AppPage(
      title: 'Uludağ teleferik',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if ((_data?['disclaimer']?.toString() ?? '').isNotEmpty)
                  Text(_data!['disclaimer'].toString(), style: const TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 16),
                const Text('İstasyonlar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 8),
                ...stations.map((s) => _InfoTile(
                      title: s['name']?.toString() ?? '',
                      subtitle: '${s['ilce'] ?? ''} · ${s['note'] ?? ''}',
                    )),
                const SizedBox(height: 16),
                const Text('Bilet tarifesi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 8),
                ...prices.map((p) => _InfoTile(
                      title: p['label']?.toString() ?? '',
                      subtitle: p['amount_tl'] != null ? '${p['amount_tl']} TL' : '',
                    )),
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Sefer saatleri', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  const SizedBox(height: 8),
                  ...hours.map((h) => _InfoTile(
                        title: h['label']?.toString() ?? h['season']?.toString() ?? '',
                        subtitle: h['text']?.toString() ?? h['hours']?.toString() ?? '',
                      )),
                ],
              ],
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
