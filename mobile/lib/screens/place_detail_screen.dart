import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_page.dart';

Future<void> openPlaceDetail(BuildContext context, String slug) async {
  final s = slug.trim();
  if (s.isEmpty) return;
  await Navigator.of(context).push(appRoute(PlaceDetailScreen(slug: s)));
}

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  Map<String, dynamic>? _place;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthStore>();
      final row = await auth.api.placeDetail(widget.slug);
      if (mounted) setState(() => _place = row);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWeb() async {
    final p = _place;
    if (p == null) return;
    final path = (p['path'] as String?)?.trim();
    final slug = (p['slug'] as String?)?.trim() ?? widget.slug;
    final url = Uri.parse('${AppConfig.siteBase}${path?.isNotEmpty == true ? path : '/yer/$slug'}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Açılamadı: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _place;
    final title = p?['title']?.toString() ?? 'Detay';

    return AppPage(
      title: title,
      onRefresh: _load,
      body: _loading && p == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: const [SizedBox(height: 180), Center(child: CircularProgressIndicator())],
            )
          : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error!, textAlign: TextAlign.center)),
                    const SizedBox(height: 12),
                    Center(child: TextButton(onPressed: _load, child: const Text('Tekrar dene'))),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _HeroImage(url: p?['img_url']?.toString() ?? ''),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      [
                        p?['category_label']?.toString(),
                        p?['ilce']?.toString(),
                        p?['starts_at_label']?.toString() ?? p?['starts_at']?.toString(),
                      ].where((e) => e != null && e.isNotEmpty).join(' · '),
                      style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                    if ((p?['address']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: AppColors.accentDeep),
                          const SizedBox(width: 6),
                          Expanded(child: Text(p!['address'].toString(), style: const TextStyle(height: 1.4))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      (p?['blurb']?.toString().isNotEmpty == true ? p!['blurb'] : p?['body'])?.toString() ?? '',
                      style: const TextStyle(height: 1.5, fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _openWeb,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Web sayfasında aç'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.nav,
                        foregroundColor: AppColors.lime,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Icon(Icons.event, size: 48, color: AppColors.muted.withValues(alpha: 0.4)),
      );
    }
    final src = url.startsWith('http') ? url : '${AppConfig.siteBase}$url';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: CachedNetworkImage(imageUrl: src, fit: BoxFit.cover),
      ),
    );
  }
}
