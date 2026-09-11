import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_page.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  Map<String, dynamic>? _article;
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
      final data = await auth.api.bursaNewsDetail(widget.slug);
      if (mounted) setState(() => _article = (data['article'] as Map?)?.cast<String, dynamic>());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _article;
    return AppPage(
      title: 'Haber',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : a == null
              ? const Center(child: Text('Haber bulunamadı', style: TextStyle(color: AppColors.muted)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _HeroImage(img: a['img_url']?.toString() ?? ''),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TopicPill(label: a['topic_label']?.toString() ?? 'Gündem', topic: a['topic']?.toString() ?? 'genel'),
                        if ((a['date_label']?.toString() ?? '').isNotEmpty)
                          Text(a['date_label'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        if ((a['reading_minutes'] as num?) != null)
                          Text('${a['reading_minutes']} dk okuma', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(a['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, height: 1.2)),
                    if ((a['source']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Kaynak: ${a['source']}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                    if ((a['blurb']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(a['blurb'].toString(), style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink)),
                    ],
                    ..._buildSections(a),
                    if (a['video'] is Map) ...[
                      const SizedBox(height: 18),
                      _VideoBlock(video: Map<String, dynamic>.from(a['video'] as Map)),
                    ],
                    if ((a['url']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _openUrl(a['url'].toString()),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Orijinal kaynağı aç'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.nav, padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                    if (a['related'] is List && (a['related'] as List).isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('İlgili haberler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 10),
                      ...(a['related'] as List).whereType<Map>().map(
                            (r) => _RelatedRow(
                              item: Map<String, dynamic>.from(r),
                              onTap: () => _openRelated(context, r['slug']?.toString() ?? ''),
                            ),
                          ),
                    ],
                    if ((a['disclaimer']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(a['disclaimer'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4)),
                    ],
                  ],
                ),
    );
  }

  List<Widget> _buildSections(Map<String, dynamic> a) {
    final sections = a['sections'] as List? ?? [];
    if (sections.isNotEmpty) {
      return sections.whereType<Map>().expand((sec) {
        final map = Map<String, dynamic>.from(sec);
        final h2 = map['h2']?.toString() ?? '';
        final paras = (map['paras'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
        return [
          if (h2.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(h2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
          ...paras.map(
            (p) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(p, style: const TextStyle(height: 1.5, fontSize: 14, color: AppColors.ink)),
            ),
          ),
        ];
      }).toList();
    }
    final body = a['body_plain']?.toString() ?? '';
    if (body.isEmpty) return [];
    return [
      const SizedBox(height: 18),
      Text(body, style: const TextStyle(height: 1.5, fontSize: 14)),
    ];
  }

  void _openRelated(BuildContext context, String slug) {
    if (slug.isEmpty) return;
    Navigator.of(context).pushReplacement(appRoute(NewsDetailScreen(slug: slug)));
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.img});
  final String img;

  @override
  Widget build(BuildContext context) {
    if (img.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(AppRadii.lg)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: CachedNetworkImage(
        imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img',
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _VideoBlock extends StatelessWidget {
  const _VideoBlock({required this.video});
  final Map<String, dynamic> video;

  @override
  Widget build(BuildContext context) {
    final thumb = video['thumb']?.toString() ?? '';
    final watch = video['watch_url']?.toString() ?? '';
    return Material(
      color: AppColors.bgSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: watch.isEmpty ? null : () => _openUrl(watch),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumb.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(imageUrl: thumb, height: 180, width: double.infinity, fit: BoxFit.cover),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İlgili video', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.muted)),
                  Text(video['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedRow extends StatelessWidget {
  const _RelatedRow({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['topic_label']?.toString() ?? '', style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 10)),
                      Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.label, required this.topic});
  final String label;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final color = newsTopicColor(topic);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }
}

Color newsTopicColor(String topic) {
  switch (topic) {
    case 'spor':
      return AppColors.coral;
    case 'ekonomi':
      return AppColors.amber;
    case 'ulasim':
      return AppColors.sky;
    case 'kultur':
      return AppColors.pink;
    case 'egitim':
      return AppColors.peach;
    case 'saglik':
      return AppColors.accentDeep;
    case 'sehir':
      return AppColors.nav;
    default:
      return AppColors.muted;
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
