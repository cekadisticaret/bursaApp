import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/place_nav.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import '../widgets/category_pills.dart';

class DentistsScreen extends StatefulWidget {
  const DentistsScreen({super.key});

  @override
  State<DentistsScreen> createState() => _DentistsScreenState();
}

class _DentistsScreenState extends State<DentistsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  String _ilce = '';
  String _band = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.dentists(ilce: _ilce, band: _band);
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

  List<Map<String, dynamic>> _asGroups(dynamic raw) {
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _asPlaces(dynamic raw) {
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<(String, String)> _bandChips() {
    final bands = _asPlaces(_data['bands']);
    return [
      ('', 'Tümü'),
      ...bands.map((b) => (b['key']?.toString() ?? '', b['label']?.toString() ?? '')),
    ].where((e) => e.$2.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _asGroups(_data['groups']);
    final total = _data['total'] is int ? _data['total'] as int : 0;
    final groupCount = _data['group_count'] is int ? _data['group_count'] as int : groups.length;
    final devletCount = _data['devlet_count'] is int ? _data['devlet_count'] as int : 0;
    final heroImg = _data['hero_img']?.toString() ?? '';
    final pageSub = _data['page_sub']?.toString() ?? '';
    final heroNote = _data['hero_note']?.toString() ?? '';
    final districts = (_data['districts'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    return AppPage(
      title: 'Diş hekimleri',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              children: [
                _HeroBlock(
                  imgUrl: heroImg,
                  total: total,
                  groupCount: groupCount,
                  devletCount: devletCount,
                  subtitle: pageSub,
                  note: heroNote,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: CategoryPills(
                    items: _bandChips(),
                    selected: _band,
                    onSelected: (v) {
                      setState(() => _band = v);
                      _load();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$total kayıt · $groupCount ilçe${_band.isNotEmpty ? ' · $_band' : ''}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      _IlcePicker(
                        ilce: _ilce,
                        districts: districts,
                        onChanged: (v) {
                          setState(() => _ilce = v ?? '');
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading && groups.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Center(child: Text('Bu filtrede diş hekimi / klinik yok.', style: TextStyle(color: AppColors.muted))),
                  )
                else
                  ...groups.expand((g) {
                    final label = g['label']?.toString() ?? '';
                    final places = _asPlaces(g['places']);
                    return [
                      _GroupHeader(label: label, count: places.length),
                      ...places.map((p) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _DentistRow(place: p),
                          )),
                      const SizedBox(height: 8),
                    ];
                  }),
              ],
            ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({
    required this.imgUrl,
    required this.total,
    required this.groupCount,
    required this.devletCount,
    required this.subtitle,
    required this.note,
  });

  final String imgUrl;
  final int total;
  final int groupCount;
  final int devletCount;
  final String subtitle;
  final String note;

  static const _sky = Color(0xFF0284C7);
  static const _skyDeep = Color(0xFF0C4A6E);

  @override
  Widget build(BuildContext context) {
    final url = imgUrl.isNotEmpty ? (imgUrl.startsWith('http') ? imgUrl : '${AppConfig.siteBase}$imgUrl') : '';
    return SizedBox(
      height: 188,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_skyDeep, _sky]),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  _skyDeep.withValues(alpha: 0.94),
                  _sky.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🦷', style: TextStyle(fontSize: 28)),
                const Spacer(),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: '$total kayıt'),
                    _StatChip(label: '$groupCount ilçe'),
                    _StatChip(label: devletCount > 0 ? '$devletCount ADSM' : 'MHRS'),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.card,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ilce.isEmpty ? '' : ilce,
          isDense: true,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
          items: [
            const DropdownMenuItem(value: '', child: Text('Tüm ilçeler')),
            ...districts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ),
          Text('$count kayıt', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
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

String _metaLine(Map<String, dynamic> place) {
  final category = place['category']?.toString() ?? '';
  final priceBand = place['price_band']?.toString() ?? '';
  final hospitalTitle = place['hospital_title']?.toString() ?? '';
  final address = place['address']?.toString() ?? '';
  final ilce = place['ilce']?.toString() ?? '';

  if (category == 'doctor') {
    final parts = <String>[priceBand.isNotEmpty ? priceBand : 'Branş'];
    if (hospitalTitle.isNotEmpty) parts.add(hospitalTitle);
    return parts.join(' · ');
  }
  if (priceBand == 'Devlet' || priceBand == 'Özel' || priceBand == 'Klinik') {
    if (address.isNotEmpty) return '$priceBand · $address';
    if (ilce.isNotEmpty) return '$priceBand · $ilce';
    return priceBand;
  }
  if (address.isNotEmpty) return address;
  return ilce.isNotEmpty ? ilce : 'Bursa';
}

class _DentistRow extends StatelessWidget {
  const _DentistRow({required this.place});
  final Map<String, dynamic> place;

  @override
  Widget build(BuildContext context) {
    final slug = _placeSlug(place);
    final title = place['title']?.toString() ?? 'Diş hekimi';
    final initial = (place['initial']?.toString() ?? '').trim();
    final initialChar = initial.isNotEmpty ? initial : (title.isNotEmpty ? title[0].toUpperCase() : '?');
    final meta = _metaLine(place);
    final hours = place['hours_short']?.toString() ?? '';
    final rating = place['rating_label']?.toString() ?? '';
    final phone = place['phone']?.toString() ?? '';
    final maps = place['maps']?.toString() ?? '';
    final priceBand = place['price_band']?.toString() ?? '';
    final mhrsUrl = place['mhrs_url']?.toString() ?? '';
    final img = place['img_url']?.toString() ?? '';
    final imgUrl = img.isNotEmpty ? (img.startsWith('http') ? img : '${AppConfig.siteBase}$img') : '';

    final showMhrs = priceBand == 'Devlet' && mhrsUrl.isNotEmpty;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: slug.isEmpty ? null : () => openPlaceDetail(context, slug),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(initial: initialChar, imgUrl: imgUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          meta,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (showMhrs)
                          _ActionChip(
                            label: 'MHRS',
                            onTap: () => launchUrl(Uri.parse(mhrsUrl), mode: LaunchMode.externalApplication),
                          ),
                        if (phone.isNotEmpty)
                          _ActionChip(
                            label: 'Ara',
                            onTap: () => launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication),
                          ),
                        if (maps.isNotEmpty)
                          _ActionChip(
                            label: 'Yol tarifi',
                            ghost: true,
                            onTap: () => launchUrl(Uri.parse(maps), mode: LaunchMode.externalApplication),
                          ),
                        if (slug.isNotEmpty)
                          _ActionChip(
                            label: 'Detay',
                            ghost: true,
                            onTap: () => openPlaceDetail(context, slug),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hours.isNotEmpty || rating.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    hours.isNotEmpty ? hours : '★ $rating',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.initial, required this.imgUrl});
  final String initial;
  final String imgUrl;

  static const _tones = [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF0369A1), Color(0xFF38BDF8)];

  @override
  Widget build(BuildContext context) {
    final tone = _tones[initial.hashCode.abs() % _tones.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imgUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover)
            : Container(
                color: tone.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Text(initial, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: tone)),
              ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap, this.ghost = false});
  final String label;
  final VoidCallback onTap;
  final bool ghost;

  static const _sky = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ghost ? AppColors.bgSoft : _sky.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ghost ? AppColors.ink : _skyDeep(),
            ),
          ),
        ),
      ),
    );
  }

  static Color _skyDeep() => const Color(0xFF0C4A6E);
}
