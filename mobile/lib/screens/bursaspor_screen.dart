import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';

class BursasporScreen extends StatefulWidget {
  const BursasporScreen({super.key});

  @override
  State<BursasporScreen> createState() => _BursasporScreenState();
}

class _BursasporScreenState extends State<BursasporScreen> {
  Map<String, dynamic>? _desk;
  List<Map<String, dynamic>> _news = [];
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
      final data = await auth.api.bursasporFeed();
      if (mounted) {
        setState(() {
          _desk = (data['desk'] as Map?)?.cast<String, dynamic>();
          _news = (data['news'] as List? ?? []).cast<Map<String, dynamic>>();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Bursaspor',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_desk != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.nav,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_desk!['standings_note']?.toString() ?? '', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(_desk!['analysis']?.toString() ?? '', style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ..._news.map((n) {
                    final img = n['img_url']?.toString() ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          if (img.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: CachedNetworkImage(
                                  imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          if (img.isNotEmpty) const SizedBox(width: 12),
                          Expanded(child: Text(n['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
