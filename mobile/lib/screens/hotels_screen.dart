import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../navigation/place_nav.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import '../widgets/category_pills.dart';
import 'category_places_screen.dart';

class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  String _q = '';
  String _band = '';
  String _price = '';
  String _sort = 'rating';
  String _ilce = '';
  String _sub = '';

  final _searchCtrl = TextEditingController();

  static const _bandChips = [
    ('', 'Tümü'),
    ('termal', 'Termal'),
    ('uludag', 'Uludağ'),
    ('sehir', 'Şehir'),
    ('butik', 'Butik'),
  ];

  static const _priceChips = [
    ('', 'Tümü'),
    ('lt10', '10K altı'),
    ('10-18', '10–18K'),
    ('18plus', '18K+'),
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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final apiBand = _band == 'butik' ? '' : _band;
      final apiSub = _band == 'butik' ? 'butik' : _sub;
      final data = await auth.api.hotels(
        q: _q,
        ilce: _ilce,
        sub: apiSub,
        band: apiBand,
        sort: _sort,
        price: _price,
      );
      if (!mounted) return;
      setState(() => _data = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyBand(String key) {
    setState(() {
      _band = key;
      if (key == 'butik') {
        _sub = 'butik';
      } else if (_sub == 'butik') {
        _sub = '';
      }
    });
    _load();
  }

  void _applyPrice(String key) {
    setState(() => _price = key);
    _load();
  }

  void _applySort(String key) {
    setState(() => _sort = key);
    _load();
  }

  void _applyIlce(String? val) {
    setState(() => _ilce = val ?? '');
    _load();
  }

  void _submitSearch() {
    setState(() => _q = _searchCtrl.text.trim());
    _load();
  }

  List<Map<String, dynamic>> _asPlaces(dynamic raw) {
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final places = _asPlaces(_data['places']);
    final featured = _asPlaces(_data['featured']);
    final featuredSlugs = (_data['featured_slugs'] as List? ?? []).map((e) => e.toString()).toSet();
    final heroImg = _data['hero_img']?.toString() ?? '';
    final priceMeta = (_data['price_meta'] as Map?)?.cast<String, dynamic>() ?? {};
    final districts = (_data['districts'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final total = _data['total'] is int ? _data['total'] as int : places.length;
    final rest = places.where((p) => !featuredSlugs.contains(p['slug']?.toString())).toList();

    return AppPage(
      title: 'Oteller',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              children: [
                _HeroBlock(imgUrl: heroImg),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _SearchBox(
                        controller: _searchCtrl,
                        onSubmit: _submitSearch,
                      ),
                      const SizedBox(height: 12),
                      CategoryPills(items: _bandChips, selected: _band, onSelected: _applyBand),
                      const SizedBox(height: 10),
                      CategoryPills(items: _priceChips, selected: _price, onSelected: _applyPrice),
                      const SizedBox(height: 12),
                      _FilterRow(
                        sort: _sort,
                        ilce: _ilce,
                        districts: districts,
                        onSort: _applySort,
                        onIlce: _applyIlce,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _metaNote(total, priceMeta, _sort, _price),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      const _FeatureRow(),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        eyebrow: _sort.startsWith('price') ? 'Fiyata göre' : 'Öne çıkanlar',
                        title: _sectionTitle(_sort),
                      ),
                      const SizedBox(height: 12),
                      if (featured.isEmpty && places.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('Bu filtrede otel yok.', style: TextStyle(color: AppColors.muted))),
                        )
                      else
                        _HotelGrid(places: featured.isNotEmpty ? featured : places.take(8).toList()),
                      if (rest.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const _SectionHeader(eyebrow: 'Tüm liste', title: 'Bursa otelleri'),
                        const SizedBox(height: 12),
                        _HotelGrid(places: rest),
                      ],
                      const SizedBox(height: 20),
                      _CampCta(heroImg: heroImg),
                      const SizedBox(height: 20),
                      const _WhyBlock(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _sectionTitle(String sort) {
    switch (sort) {
      case 'price_asc':
        return 'En uygun oteller';
      case 'price_desc':
        return 'En yüksek fiyatlı oteller';
      default:
        return 'Beğeneceğin oteller';
    }
  }

  String _metaNote(int total, Map<String, dynamic> meta, String sort, String price) {
    final parts = <String>['$total otel'];
    final cin = meta['check_in']?.toString();
    final cout = meta['check_out']?.toString();
    if (cin != null && cin.isNotEmpty && cout != null && cout.isNotEmpty) {
      parts.add('gecelik fiyat ($cin → $cout)');
    } else {
      parts.add('gecelik fiyat');
    }
    if (sort == 'price_asc') {
      parts.add('en ucuz üstte');
    } else if (sort == 'price_desc') {
      parts.add('en pahalı üstte');
    }
    if (price.isNotEmpty) parts.add('fiyat filtresi aktif');
    return parts.join(' · ');
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.imgUrl});
  final String imgUrl;

  @override
  Widget build(BuildContext context) {
    final url = imgUrl.isNotEmpty ? (imgUrl.startsWith('http') ? imgUrl : '${AppConfig.siteBase}$imgUrl') : '';
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          else
            Container(color: AppColors.nav),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.nav.withValues(alpha: 0.92),
                  AppColors.nav.withValues(alpha: 0.55),
                  AppColors.nav.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Bursa otelleri',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Termal Çekirge, şehir otelleri ve Uludağ — rezervasyon siteden yapılmaz.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
        ],
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
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      elevation: 0,
      shadowColor: AppColors.ink.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
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
                  hintText: 'Otel, semt, ilçe…',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(onPressed: onSubmit, icon: const Icon(Icons.search_rounded, color: AppColors.accentDeep)),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.sort,
    required this.ilce,
    required this.districts,
    required this.onSort,
    required this.onIlce,
  });

  final String sort;
  final String ilce;
  final List<String> districts;
  final ValueChanged<String> onSort;
  final ValueChanged<String?> onIlce;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DropdownField(
            label: 'Sırala',
            value: sort,
            items: const [
              ('rating', 'Puana göre'),
              ('price_asc', 'Fiyat ↑'),
              ('price_desc', 'Fiyat ↓'),
            ],
            onChanged: onSort,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DropdownField(
            label: 'İlçe',
            value: ilce.isEmpty ? '' : ilce,
            items: [('', 'Tümü'), ...districts.map((d) => (d, d))],
            onChanged: (v) => onIlce(v.isEmpty ? null : v),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

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
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
              items: items
                  .map(
                    (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2, overflow: TextOverflow.ellipsis)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
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
      ('🏨', 'Doğru oteli bul', 'Termal, Uludağ, şehir'),
      ('📍', 'İlçe ilçe', 'Gerçek konum bilgisi'),
      ('★', 'Misafir puanı', 'Skora göre sırala'),
      ('💸', 'Örnek fiyat', 'Kesin teklif otelden'),
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
                  Text(e.$1, style: const TextStyle(fontSize: 22)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: const TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      ],
    );
  }
}

class _HotelGrid extends StatelessWidget {
  const _HotelGrid({required this.places});
  final List<Map<String, dynamic>> places;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: places.length,
      itemBuilder: (context, i) => _HotelCard(place: places[i]),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.place});
  final Map<String, dynamic> place;

  String get _slug {
    final slug = (place['slug']?.toString() ?? '').trim();
    if (slug.isNotEmpty) return slug;
    final path = (place['path']?.toString() ?? '').trim();
    if (path.isEmpty) return '';
    final segment = path.split('/').where((s) => s.isNotEmpty).last;
    if (segment.startsWith('bursa-')) return segment.substring(6);
    return segment;
  }

  Color _badgeColor(String band) {
    switch (band) {
      case 'termal':
        return const Color(0xFF0F766E);
      case 'uludag':
        return const Color(0xFF1D4ED8);
      case 'butik':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.nav;
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = place['img_url']?.toString() ?? '';
    final imgUrl = img.isNotEmpty ? (img.startsWith('http') ? img : '${AppConfig.siteBase}$img') : '';
    final band = (place['price_band']?.toString() ?? 'sehir').toLowerCase();
    final badge = place['badge_label']?.toString() ?? 'OTEL';
    final priceLabel = place['price_label']?.toString() ?? 'Fiyat sor';
    final title = place['title']?.toString() ?? 'Otel';
    final ilce = place['ilce']?.toString() ?? 'Bursa';
    final address = place['address']?.toString() ?? '';
    final addrShort = address.isNotEmpty ? address.split(',').first.trim() : '';
    final rating = place['rating'];
    final ratingText = rating is num ? rating.toStringAsFixed(1) : null;
    final subLabel = place['subcategory_label']?.toString() ?? '';
    final extra = (place['extra'] as Map?)?.cast<String, dynamic>() ?? {};
    final checkIn = extra['price_check_in']?.toString() ?? '';

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _slug.isEmpty
            ? null
            : () => openPlaceDetail(context, _slug),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imgUrl.isNotEmpty)
                      CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover)
                    else
                      ColoredBox(
                        color: AppColors.bgSoft,
                        child: Icon(Icons.hotel_rounded, size: 36, color: AppColors.muted.withValues(alpha: 0.35)),
                      ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeColor(band),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: priceLabel,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink),
                            ),
                            TextSpan(
                              text: checkIn.isNotEmpty ? ' / gece · $checkIn' : ' / gece',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: AppColors.muted),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        addrShort.isNotEmpty ? '$ilce · $addrShort' : ilce,
                        style: const TextStyle(color: AppColors.muted, fontSize: 10, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (ratingText != null)
                            _StatChip(text: '★ $ratingText'),
                          if (subLabel.isNotEmpty) _StatChip(text: subLabel),
                        ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted));
  }
}

class _CampCta extends StatelessWidget {
  const _CampCta({required this.heroImg});
  final String heroImg;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.nav,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          appRoute(const CategoryPlacesScreen(title: 'Kamp alanları', category: 'camp')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Doğa mı, termal mi? Kamp da listede.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, height: 1.25),
              ),
              const SizedBox(height: 8),
              Text(
                'Uludağ koyları, gölet kenarı ve ücretsiz alanlar — otel istemeyenler için.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('Kamp yerlerine git →', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.nav)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhyBlock extends StatelessWidget {
  const _WhyBlock();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('🗺', 'Yerel liste', 'Bursa odaklı — şehir, termal ve dağ bir arada.'),
      ('📷', 'Gerçek fotoğraflar', 'Otel sayfalarında galeri; mekanı önce gör.'),
      ('🔒', 'Rezervasyon yok', 'Kart bilgisi istemeyiz; oteli sen ararsın.'),
      ('🌿', 'Gezi + yemek', 'Konaklamanın yanına rota ve restoran ekle.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(eyebrow: 'Neden BursaApp', title: 'Konaklamayı sade tutuyoruz'),
        const SizedBox(height: 12),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(e.$3, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
