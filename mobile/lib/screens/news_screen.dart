import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_page.dart';
import 'bursaspor_screen.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _videos = [];
  Map<String, dynamic> _topics = {};
  Map<String, dynamic> _meta = {};
  Map<String, dynamic>? _bursaspor;
  Map<String, dynamic>? _featuredVideo;
  String _topic = '';
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.bursaNews(
        topic: _topic.isEmpty ? null : _topic,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        page: _page,
        limit: 24,
      );
      final batch = (data['articles'] as List? ?? []).cast<Map<String, dynamic>>();
      final meta = (data['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      final pages = (meta['pages'] as num?)?.toInt() ?? 1;
      if (mounted) {
        setState(() {
          if (reset) {
            _articles = batch;
            _topics = (data['topics'] as Map?)?.cast<String, dynamic>() ?? {};
            _videos = (data['videos'] as List? ?? []).cast<Map<String, dynamic>>();
            _featuredVideo = (data['featured_video'] as Map?)?.cast<String, dynamic>();
            _bursaspor = (data['bursaspor'] as Map?)?.cast<String, dynamic>();
            _meta = meta;
          } else {
            _articles = [..._articles, ...batch];
          }
          _hasMore = _page < pages;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _page += 1;
    await _load(reset: false);
  }

  void _setTopic(String topic) {
    if (_topic == topic) return;
    setState(() => _topic = topic);
    _load(reset: true);
  }

  void _submitSearch() {
    _load(reset: true);
  }

  void _openArticle(Map<String, dynamic> a) {
    final slug = a['slug']?.toString() ?? a['id']?.toString() ?? '';
    if (slug.isEmpty) return;
    Navigator.of(context).push(appRoute(NewsDetailScreen(slug: slug)));
  }

  @override
  Widget build(BuildContext context) {
    final hero = _articles.isNotEmpty ? _articles.first : null;
    final sideList = _articles.length > 1 ? _articles.sublist(1, _articles.length > 7 ? 7 : _articles.length) : <Map<String, dynamic>>[];
    final rest = _articles.length > 7 ? _articles.sublist(7) : <Map<String, dynamic>>[];
    final updated = _meta['generated_at']?.toString() ?? '';

    return AppPage(
      title: 'Bursa haberleri',
      body: _loading && _articles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SearchBar(controller: _searchCtrl, onSearch: _submitSearch),
                  const SizedBox(height: 10),
                  const Text(
                    'Bursa gündemi — trafik, belediye, sanayi, kültür ve spor. Metin burada; kaynak linki detayda.',
                    style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
                  ),
                  if (updated.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Güncellendi $updated', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                  const SizedBox(height: 12),
                  _TopicBar(topics: _topics, selected: _topic, onPick: _setTopic),
                  if (_bursaspor != null && (_bursaspor!['next_match'] != null)) ...[
                    const SizedBox(height: 12),
                    _BursasporStrip(data: _bursaspor!, onOpen: () => Navigator.of(context).push(appRoute(const BursasporScreen()))),
                  ],
                  if (hero != null) ...[
                    const SizedBox(height: 14),
                    _HeroArticle(article: hero, onTap: () => _openArticle(hero)),
                  ],
                  if (sideList.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Son dakika', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 8),
                    ...sideList.map((a) => _SideRow(article: a, onTap: () => _openArticle(a))),
                  ],
                  if (_videos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _VideosSection(videos: _videos, featured: _featuredVideo),
                  ],
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Daha fazla haber${_meta['total'] != null ? ' · ${_meta['total']}' : ''}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 8),
                    ...rest.map((a) => _NewsCard(article: a, onTap: () => _openArticle(a))),
                  ],
                  if (_articles.isEmpty && !_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Bu filtrede haber yok.', style: TextStyle(color: AppColors.muted))),
                    ),
                  if (_hasMore && _articles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: _loadingMore
                          ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                          : OutlinedButton(onPressed: _loadMore, child: const Text('Daha fazla yükle')),
                    ),
                  ],
                  if ((_meta['disclaimer']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_meta['disclaimer'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});
  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Bursa haber ara…',
              filled: true,
              fillColor: AppColors.card,
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: onSearch, style: FilledButton.styleFrom(backgroundColor: AppColors.nav), child: const Text('Ara')),
      ],
    );
  }
}

class _TopicBar extends StatelessWidget {
  const _TopicBar({required this.topics, required this.selected, required this.onPick});
  final Map<String, dynamic> topics;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, String>>[const MapEntry('', 'Tümü'), ...topics.entries.map((e) => MapEntry(e.key, e.value.toString()))];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = entries[i];
          final on = selected == e.key;
          return FilterChip(
            label: Text(e.value, style: TextStyle(fontWeight: FontWeight.w700, color: on ? Colors.white : AppColors.ink, fontSize: 12)),
            selected: on,
            onSelected: (_) => onPick(e.key),
            selectedColor: AppColors.nav,
            backgroundColor: AppColors.card,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _BursasporStrip extends StatelessWidget {
  const _BursasporStrip({required this.data, required this.onOpen});
  final Map<String, dynamic> data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nm = (data['next_match'] as Map?)?.cast<String, dynamic>();
    if (nm == null) return const SizedBox.shrink();
    final form = (data['form'] as List? ?? []).map((e) => e.toString()).toList();
    return Material(
      color: AppColors.nav,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SIRADAKİ MAÇ · Bursaspor', style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 8),
              Text('${nm['home']}  ·  ${(nm['kickoff']?.toString() ?? '').split(' ').last}  ·  ${nm['away']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              if (form.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: form.map((ch) => Padding(padding: const EdgeInsets.only(right: 4), child: _FormDot(ch: ch))).toList()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormDot extends StatelessWidget {
  const _FormDot({required this.ch});
  final String ch;

  Color get _c {
    switch (ch.toUpperCase()) {
      case 'G':
        return AppColors.lime;
      case 'M':
        return AppColors.coral;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _c, shape: BoxShape.circle),
      child: Text(ch, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.nav)),
    );
  }
}

class _HeroArticle extends StatelessWidget {
  const _HeroArticle({required this.article, required this.onTap});
  final Map<String, dynamic> article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = article['img_url']?.toString() ?? '';
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img.isNotEmpty)
              CachedNetworkImage(
                imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopicPill(label: article['topic_label']?.toString() ?? 'Gündem', topic: article['topic']?.toString() ?? 'genel'),
                  const SizedBox(height: 8),
                  Text(article['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, height: 1.2)),
                  const SizedBox(height: 8),
                  Text(article['blurb']?.toString() ?? '', maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, height: 1.4)),
                  const SizedBox(height: 10),
                  const Text('Haberi oku →', style: TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideRow extends StatelessWidget {
  const _SideRow({required this.article, required this.onTap});
  final Map<String, dynamic> article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = article['img_url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                if (img.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 56, height: 56, child: CachedNetworkImage(imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img', fit: BoxFit.cover)),
                  ),
                if (img.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('${article['topic_label'] ?? ''} · ${article['date_label'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.onTap});
  final Map<String, dynamic> article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = article['img_url']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: AppColors.ink.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadii.lg), boxShadow: AppShadows.card),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (img.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadii.lg)),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CachedNetworkImage(imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img', fit: BoxFit.cover),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopicPill(label: article['topic_label']?.toString() ?? 'Gündem', topic: article['topic']?.toString() ?? 'genel'),
                        const SizedBox(height: 6),
                        Text(article['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, height: 1.25), maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${article['source'] ?? ''} · ${article['date_label'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideosSection extends StatelessWidget {
  const _VideosSection({required this.videos, this.featured});
  final List<Map<String, dynamic>> videos;
  final Map<String, dynamic>? featured;

  @override
  Widget build(BuildContext context) {
    final lead = featured ?? (videos.isNotEmpty ? videos.first : null);
    final rest = videos.length > 1 ? videos.sublist(1) : <Map<String, dynamic>>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bursa video gündemi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 8),
        if (lead != null) _VideoTile(video: lead, large: true),
        ...rest.take(4).map((v) => Padding(padding: const EdgeInsets.only(top: 8), child: _VideoTile(video: v))),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, this.large = false});
  final Map<String, dynamic> video;
  final bool large;

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
        child: Row(
          children: [
            if (thumb.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(imageUrl: thumb, width: large ? 140 : 96, height: large ? 88 : 64, fit: BoxFit.cover),
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 28),
                ],
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video['title']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w800, fontSize: large ? 14 : 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('${video['channel'] ?? ''} · ${video['date_label'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10)),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
