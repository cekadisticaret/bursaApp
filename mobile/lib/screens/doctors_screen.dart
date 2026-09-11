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

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  String _ilce = '';
  String _spec = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.doctors(ilce: _ilce, spec: _spec);
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

  @override
  Widget build(BuildContext context) {
    final groups = _asGroups(_data['groups']);
    final total = _data['total'] is int ? _data['total'] as int : 0;
    final specCount = _data['spec_count'] is int ? _data['spec_count'] as int : groups.length;
    final heroImg = _data['hero_img']?.toString() ?? '';
    final pageSub = _data['page_sub']?.toString() ?? '';
    final heroNote = _data['hero_note']?.toString() ?? '';
    final districts = (_data['districts'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final specs = _asPlaces(_data['specs'])
        .map((s) => s['label']?.toString() ?? s['key']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    return AppPage(
      title: 'Doktorlar',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              children: [
                _HeroBlock(
                  imgUrl: heroImg,
                  total: total,
                  specCount: specCount,
                  subtitle: pageSub,
                  note: heroNote,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterPicker(
                          label: 'Branş',
                          value: _spec,
                          items: specs,
                          allLabel: 'Tüm branşlar',
                          onChanged: (v) {
                            setState(() => _spec = v ?? '');
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FilterPicker(
                          label: 'İlçe',
                          value: _ilce,
                          items: districts,
                          allLabel: 'Tüm ilçeler',
                          onChanged: (v) {
                            setState(() => _ilce = v ?? '');
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    '$total hekim · $specCount branş${_spec.isNotEmpty ? ' · $_spec' : ''}${_ilce.isNotEmpty ? ' · $_ilce' : ''}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading && groups.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Center(child: Text('Bu filtrede hekim yok.', style: TextStyle(color: AppColors.muted))),
                  )
                else
                  ...groups.expand((g) {
                    final label = g['label']?.toString() ?? '';
                    final places = _asPlaces(g['places']);
                    return [
                      _GroupHeader(label: label, count: places.length),
                      ...places.map((p) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _DoctorRow(place: p),
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
    required this.specCount,
    required this.subtitle,
    required this.note,
  });

  final String imgUrl;
  final int total;
  final int specCount;
  final String subtitle;
  final String note;

  static const _violet = Color(0xFF7C3AED);
  static const _violetDeep = Color(0xFF4C1D95);

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
                gradient: LinearGradient(colors: [_violetDeep, _violet]),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  _violetDeep.withValues(alpha: 0.94),
                  _violet.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🩺', style: TextStyle(fontSize: 28)),
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
                    _StatChip(label: '$total hekim'),
                    _StatChip(label: '$specCount branş'),
                    const _StatChip(label: 'MHRS'),
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

class _FilterPicker extends StatelessWidget {
  const _FilterPicker({
    required this.label,
    required this.value,
    required this.items,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? '' : value,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
              items: [
                DropdownMenuItem(value: '', child: Text(allLabel)),
                ...items.map((d) => DropdownMenuItem(value: d, child: Text(d))),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
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
          Text('$count hekim', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
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
  final priceBand = place['price_band']?.toString() ?? '';
  final hospitalTitle = place['hospital_title']?.toString() ?? '';
  final ilce = place['ilce']?.toString() ?? '';
  final parts = <String>[priceBand.isNotEmpty ? priceBand : 'Branş'];
  if (hospitalTitle.isNotEmpty) parts.add(hospitalTitle);
  if (ilce.isNotEmpty && hospitalTitle.isEmpty) parts.add(ilce);
  return parts.join(' · ');
}

class _DoctorRow extends StatelessWidget {
  const _DoctorRow({required this.place});
  final Map<String, dynamic> place;

  static const _violet = Color(0xFF7C3AED);
  static const _violetDeep = Color(0xFF4C1D95);

  @override
  Widget build(BuildContext context) {
    final slug = _placeSlug(place);
    final title = place['title']?.toString() ?? 'Doktor';
    final initial = (place['initial']?.toString() ?? '').trim();
    final initialChar = initial.isNotEmpty ? initial : (title.isNotEmpty ? title[0].toUpperCase() : '?');
    final meta = _metaLine(place);
    final hours = place['hours_short']?.toString() ?? '';
    final rating = place['rating_label']?.toString() ?? '';
    final phone = place['phone']?.toString() ?? '';
    final maps = place['maps']?.toString() ?? '';
    final mhrsUrl = place['mhrs_url']?.toString() ?? '';
    final img = place['img_url']?.toString() ?? '';
    final imgUrl = img.isNotEmpty ? (img.startsWith('http') ? img : '${AppConfig.siteBase}$img') : '';

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
                        if (mhrsUrl.isNotEmpty)
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

  static const _tones = [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFFA78BFA)];

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ghost ? AppColors.bgSoft : _DoctorRow._violet.withValues(alpha: 0.12),
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
              color: ghost ? AppColors.ink : _DoctorRow._violetDeep,
            ),
          ),
        ),
      ),
    );
  }
}
