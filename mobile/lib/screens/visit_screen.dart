import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/place_nav.dart';
import '../shell/shell_scope.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import '../widgets/category_pills.dart';
import '../widgets/floating_tab_bar.dart';

class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key});

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  int _page = 1;

  String _q = '';
  String _sort = 'featured';
  String _ilce = '';
  final Set<String> _kinds = {};
  final Set<String> _fees = {};
  final Set<String> _tags = {};

  final _searchCtrl = TextEditingController();

  static const _sortChips = [
    ('featured', 'Öne çıkan'),
    ('rating', 'Puan'),
    ('name', 'A–Z'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = true}) async {
    if (refresh) _page = 1;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.visitPlaces(
        q: _q,
        ilce: _ilce,
        sort: _sort,
        kinds: _kinds.toList(),
        fees: _fees.toList(),
        tags: _tags.toList(),
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        if (refresh || _page <= 1) {
          _data = data;
        } else {
          final prev = _asList(_data['places']);
          final next = _asList(data['places']);
          _data = Map<String, dynamic>.from(data)..['places'] = [...prev, ...next];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submitSearch() {
    setState(() => _q = _searchCtrl.text.trim());
    _load();
  }

  void _toggleKind(String key) {
    setState(() {
      if (key.isEmpty) {
        _kinds.clear();
      } else if (_kinds.contains(key)) {
        _kinds.remove(key);
      } else {
        _kinds.add(key);
      }
    });
    _load();
  }

  void _toggleFee(String key) {
    setState(() {
      if (_fees.contains(key)) {
        _fees.remove(key);
      } else {
        _fees.add(key);
      }
    });
    _load();
  }

  void _toggleTag(String key) {
    setState(() {
      if (_tags.contains(key)) {
        _tags.remove(key);
      } else {
        _tags.add(key);
      }
    });
    _load();
  }

  void _openMap() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ShellScope.maybeOf(context)?.goTab(ShellTabs.explore);
  }

  List<Map<String, dynamic>> _asList(dynamic raw) {
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<(String, String)> _kindChips() {
    final kinds = _asList(_data['kinds']);
    return [
      ('', 'Tümü'),
      ...kinds.map((k) => (k['key']?.toString() ?? '', k['label']?.toString() ?? '')),
    ].where((e) => e.$2.isNotEmpty).toList();
  }

  bool get _hasFilters => _q.isNotEmpty || _ilce.isNotEmpty || _kinds.isNotEmpty || _fees.isNotEmpty || _tags.isNotEmpty;

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _q = '';
      _ilce = '';
      _kinds.clear();
      _fees.clear();
      _tags.clear();
      _sort = 'featured';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final places = _asList(_data['places']);
    final hero = _asList(_data['hero']);
    final total = _data['total'] is int ? _data['total'] as int : places.length;
    final districts = (_data['districts'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final fees = _asList(_data['fees']);
    final tags = _asList(_data['tags']);
    final heroImg = hero.isNotEmpty ? (hero.first['img_url']?.toString() ?? '') : '';

    return AppPage(
      title: 'Gezilecek yerler',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: () => _load(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              children: [
                _HeroBlock(imgUrl: heroImg, onMapTap: _openMap),
                if (hero.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _FeaturedCarousel(places: hero),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SearchBox(controller: _searchCtrl, onSubmit: _submitSearch),
                      const SizedBox(height: 12),
                      if (_kindChips().length > 1)
                        _MultiChipRow(
                          label: 'Tür',
                          items: _kindChips(),
                          selected: _kinds,
                          onToggle: _toggleKind,
                        ),
                      if (fees.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _MultiChipRow(
                          label: 'Giriş',
                          items: fees.map((f) => (f['key']?.toString() ?? '', f['label']?.toString() ?? '')).toList(),
                          selected: _fees,
                          onToggle: _toggleFee,
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _MultiChipRow(
                          label: 'Öne çıkan',
                          items: tags.map((t) => (t['key']?.toString() ?? '', t['label']?.toString() ?? '')).toList(),
                          selected: _tags,
                          onToggle: _toggleTag,
                        ),
                      ],
                      const SizedBox(height: 12),
                      CategoryPills(items: _sortChips, selected: _sort, onSelected: (v) {
                        setState(() => _sort = v);
                        _load();
                      }),
                      const SizedBox(height: 10),
                      _IlcePicker(ilce: _ilce, districts: districts, onChanged: (v) {
                        setState(() => _ilce = v ?? '');
                        _load();
                      }),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$total sonuç${_q.isNotEmpty ? ' · “$_q”' : ''}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_hasFilters)
                            TextButton(onPressed: _clearFilters, child: const Text('Temizle')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _FeatureRow(),
                      const SizedBox(height: 16),
                      if (_loading && places.isEmpty)
                        const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                      else if (places.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('Bu filtrede yer yok.', style: TextStyle(color: AppColors.muted))),
                        )
                      else
                        ...places.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _VisitHitCard(place: p),
                            )),
                      if ((_data['page'] is int ? _data['page'] as int : 1) < (_data['pages'] is int ? _data['pages'] as int : 1)) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    setState(() => _page += 1);
                                    await _load(refresh: false);
                                  },
                            child: const Text('Daha fazla yükle'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.imgUrl, required this.onMapTap});
  final String imgUrl;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    final url = imgUrl.isNotEmpty ? (imgUrl.startsWith('http') ? imgUrl : '${AppConfig.siteBase}$imgUrl') : '';
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bgDeep, AppColors.accentDeep],
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  AppColors.nav.withValues(alpha: 0.92),
                  AppColors.nav.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text('🌿 Gezi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.ink)),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onMapTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Harita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Bursa gezilecek yerler',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  'Müze, doğa, köy ve manzara — gerçek duraklar, mekanın kendi fotoğrafı.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.places});
  final List<Map<String, dynamic>> places;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _FeaturedTile(place: places[i]),
      ),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.place});
  final Map<String, dynamic> place;

  String get _slug => _placeSlug(place);

  @override
  Widget build(BuildContext context) {
    final img = place['img_url']?.toString() ?? '';
    final url = img.isNotEmpty ? (img.startsWith('http') ? img : '${AppConfig.siteBase}$img') : '';
    final title = place['title']?.toString() ?? 'Gezilecek yer';
    final ilce = place['ilce']?.toString() ?? '';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _slug.isEmpty ? null : () => openPlaceDetail(context, _slug),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: url.isNotEmpty
                    ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                    : ColoredBox(
                        color: AppColors.bgSoft,
                        child: Icon(Icons.landscape_rounded, color: AppColors.muted.withValues(alpha: 0.35), size: 32),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, height: 1.2)),
                    if (ilce.isNotEmpty)
                      Text(ilce, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Yer, müze, köy, ilçe ara…',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(onPressed: onSubmit, icon: const Icon(Icons.search_rounded, color: AppColors.accentDeep)),
        ],
      ),
    );
  }
}

class _MultiChipRow extends StatelessWidget {
  const _MultiChipRow({
    required this.label,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<(String, String)> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (key, lab) = items[i];
              final on = key.isEmpty ? selected.isEmpty : selected.contains(key);
              return GestureDetector(
                onTap: () => onToggle(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? AppColors.nav : AppColors.card,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: on ? AppColors.nav : AppColors.ink.withValues(alpha: 0.08)),
                    boxShadow: on ? null : AppShadows.card,
                  ),
                  child: Text(
                    lab,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: on ? Colors.white : AppColors.muted,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IlcePicker extends StatelessWidget {
  const _IlcePicker({required this.ilce, required this.districts, required this.onChanged});
  final String ilce;
  final List<String> districts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İlçe', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ilce.isEmpty ? '' : ilce,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm ilçeler')),
                ...districts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('📍', 'Gerçek duraklar', 'Müze, köy, şelale — OSM stok değil'),
      ('★', 'Misafir puanı', 'Puana göre sırala'),
      ('🆓', 'Giriş bilgisi', 'Ücretsiz / ücretli etiket'),
      ('📷', 'Fotoğraf', 'Mekanın kendi kapağı'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: items
          .map(
            (e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(e.$3, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

String _placeSlug(Map<String, dynamic> place) {
  final slug = (place['slug']?.toString() ?? '').trim();
  if (slug.isNotEmpty) return slug;
  final path = (place['path']?.toString() ?? '').trim();
  if (path.isEmpty) return '';
  final segment = path.split('/').where((s) => s.isNotEmpty).last;
  if (segment.startsWith('bursa-')) return segment.substring(6);
  return segment;
}

class _VisitHitCard extends StatelessWidget {
  const _VisitHitCard({required this.place});
  final Map<String, dynamic> place;

  @override
  Widget build(BuildContext context) {
    final slug = _placeSlug(place);
    final img = place['img_url']?.toString() ?? '';
    final imgUrl = img.isNotEmpty ? (img.startsWith('http') ? img : '${AppConfig.siteBase}$img') : '';
    final title = place['title']?.toString() ?? 'Gezilecek yer';
    final rank = place['rank'];
    final rankPrefix = rank is int ? '$rank. ' : '';
    final rating = place['rating'];
    final ratingText = rating is num ? rating.toStringAsFixed(1) : null;
    final sub = place['subcategory_label']?.toString() ?? 'Gezilecek yer';
    final fee = place['fee_label']?.toString() ?? '';
    final ilce = place['ilce']?.toString() ?? '';
    final hours = place['hours_text']?.toString() ?? '';
    final blurb = place['blurb']?.toString() ?? '';
    final gallery = (place['gallery'] as List? ?? []).length;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: slug.isEmpty ? null : () => openPlaceDetail(context, slug),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imgUrl.isNotEmpty)
                        CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover)
                      else
                        ColoredBox(
                          color: AppColors.bgSoft,
                          child: Icon(Icons.landscape_rounded, color: AppColors.muted.withValues(alpha: 0.35), size: 32),
                        ),
                      if (gallery > 1)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('$gallery foto', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$rankPrefix$title',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ratingText != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('★ $ratingText', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.accentDeep)),
                          const SizedBox(width: 6),
                          _RatingDots(rating: rating!.toDouble()),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [sub, fee, ilce, hours].where((e) => e.isNotEmpty).join(' · '),
                      style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.35, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (blurb.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '“${blurb.length > 100 ? '${blurb.substring(0, 100)}…' : blurb}”',
                        style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), fontSize: 11, height: 1.35, fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text('Detay →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.accentDeep)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingDots extends StatelessWidget {
  const _RatingDots({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = rating >= i + 0.8;
        final half = !full && rating >= i + 0.3;
        return Icon(
          full ? Icons.star_rounded : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: 12,
          color: AppColors.amber,
        );
      }),
    );
  }
}
