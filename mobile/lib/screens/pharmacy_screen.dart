import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
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
      final data = await auth.api.nobetciEczaneler();
      if (mounted) setState(() => _data = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pharmacies = (_data?['pharmacies'] as List? ?? []).cast<Map>();
    final dutyDate = _data?['duty_date']?.toString() ?? '';

    return AppPage(
      title: 'Nöbetçi eczaneler',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (dutyDate.isNotEmpty)
                    Text('Nöbet: $dutyDate', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...pharmacies.map((p) {
                    final map = Map<String, dynamic>.from(p);
                    final name = map['name']?.toString() ?? 'Eczane';
                    final district = map['district']?.toString() ?? '';
                    final phone = map['phone']?.toString() ?? '';
                    final address = map['address']?.toString() ?? '';
                    final maps = map['maps']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: AppShadows.card,
                      ),
                      child: ListTile(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text([district, address, phone].where((e) => e.isNotEmpty).join('\n')),
                        trailing: maps.isNotEmpty ? const Icon(Icons.directions_rounded) : null,
                        onTap: maps.isNotEmpty ? () => launchUrl(Uri.parse(maps), mode: LaunchMode.externalApplication) : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
