import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/place_nav.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import '../widgets/category_pills.dart';

class VetsScreen extends StatefulWidget {
  const VetsScreen({super.key});

  @override
  State<VetsScreen> createState() => _VetsScreenState();
}

class _VetsScreenState extends State<VetsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _locating = false;

  String _tab = 'hepsi';
  String _ilce = '';
  String _sub = '';
  double? _lat;
  double? _lng;

  static const _tabChips = [
    ('hepsi', 'Tümü'),
    ('yakin', 'Yakınımda'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.vets(
        tab: _tab,
        ilce: _tab == 'hepsi' ? _ilce : null,
        sub: _tab == 'hepsi' ? _sub : null,
        lat: _tab == 'yakin' ? _lat : null,
        lng: _tab == 'yakin' ? _lng : null,
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

  Future<void> _findNearby() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni verilmedi. Ayarlardan açıp tekrar dene.')),
          );
        }
        setState(() {
          _tab = 'yakin';
          _lat = null;
          _lng = null;
        });
        await _load();
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _tab = 'yakin';
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<Map<String, dynamic>> _asGroups(dynamic raw) {
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _placesInGroups(List<Map<String, dynamic>> groups) {
    final out = <Map<String, dynamic>>[];
    for (final g in groups) {
      out.addAll(_asPlaces(g['places']));
    }
    return out;
  }

  List<Map<String, dynamic>> _asPlaces(dynamic raw) {
    return (raw as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<(String, String)> _subChips() {
    final subs = _asPlaces(_data['subs']);
    return [
      ('', 'Tümü'),
      ...subs.map((s) => (s['key']?.toString() ?? '', s['label']?.toString() ?? '')),
    ].where((e) => e.$2.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _asGroups(_data['groups']);
    final total = _data['total'] is int ? _data['total'] as int : _placesInGroups(groups).length;
    final groupCount = _data['group_count'] is int ? _data['group_count'] as int : groups.length;
    final hospitalCount = _data['hospital_count'] is int ? _data['hospital_count'] as int : 0;
    final heroImg = _data['hero_img']?.toString() ?? '';
    final pageSub = _data['page_sub']?.toString() ?? '';
    final heroNote = _data['hero_note']?.toString() ?? '';
    final usedFallback = _data['used_fallback'] == true;
    final districts = (_data['districts'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    return AppPage(
      title: 'Veterinerler',
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
                  hospitalCount: hospitalCount,
                  subtitle: pageSub,
                  note: heroNote,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _NearBar(loading: _locating, onTap: _findNearby),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: CategoryPills(
                    items: _tabChips,
                    selected: _tab,
                    onSelected: (v) {
                      setState(() => _tab = v);
                      _load();
                    },
                  ),
                ),
                if (_tab == 'yakin')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Text(
                      usedFallback
                          ? 'Konum alınamadı — Osmangazi merkez varsayıldı.'
                          : _lat != null
                              ? 'Konumuna göre sıralı · ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                              : 'Yakın veterinerler için konumunu paylaş.',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (_tab == 'hepsi') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: CategoryPills(
                      items: _subChips(),
                      selected: _sub,
                      onSelected: (v) {
                        setState(() => _sub = v);
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
                            '$total klinik · $groupCount bölge',
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
                ] else if (total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Text(
                      '$total veteriner · en yakından uzağa',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_loading && groups.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Center(child: Text('Bu filtrede veteriner yok.', style: TextStyle(color: AppColors.muted))),
                  )
                else
                  ...groups.expand((g) {
                    final label = g['label']?.toString() ?? '';
                    final places = _asPlaces(g['places']);
                    return [
                      _GroupHeader(label: label, count: places.length),
                      ...places.map((p) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _VetRow(place: p),
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
    required this.hospitalCount,
    required this.subtitle,
    required this.note,
  });

  final String imgUrl;
  final int total;
  final int groupCount;
  final int hospitalCount;
  final String subtitle;
  final String note;

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
                gradient: LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF1B4332)]),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  const Color(0xFF1B4332).withValues(alpha: 0.94),
                  const Color(0xFF40916C).withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🐾', style: TextStyle(fontSize: 28)),
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
                    _StatChip(label: '$total klinik'),
                    _StatChip(label: '$groupCount bölge'),
                    if (hospitalCount > 0) _StatChip(label: '$hospitalCount hastane'),
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

class _NearBar extends StatelessWidget {
  const _NearBar({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Yakınındaki klinikleri bul', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                SizedBox(height: 4),
                Text(
                  'Konumuna göre en yakından uzağa sıralar.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: loading ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF40916C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Bul', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
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
          Text('$count klinik', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
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

class _VetRow extends StatelessWidget {
  const _VetRow({required this.place});
  final Map<String, dynamic> place;

  @override
  Widget build(BuildContext context) {
    final slug = _placeSlug(place);
    final title = place['title']?.toString() ?? 'Veteriner';
    final initial = (place['initial']?.toString() ?? '').trim();
    final initialChar = initial.isNotEmpty
        ? initial
        : (title.isNotEmpty ? title[0].toUpperCase() : '?');
    final address = place['address']?.toString() ?? '';
    final ilce = place['ilce']?.toString() ?? '';
    final subLabel = place['subcategory_label']?.toString() ?? place['price_band']?.toString() ?? '';
    final distance = place['distance_label']?.toString() ?? '';
    final hours = place['hours_short']?.toString() ?? '';
    final rating = place['rating_label']?.toString() ?? '';
    final phone = place['phone']?.toString() ?? '';
    final maps = place['maps']?.toString() ?? '';
    final img = place['img_url']?.toString() ?? '';
    final imgUrl = img.isNotEmpty ? (img.startsWith('http') ? img : '${AppConfig.siteBase}$img') : '';

    final metaParts = <String>[
      if (distance.isNotEmpty) distance,
      if (subLabel.isNotEmpty) subLabel,
      if (address.isNotEmpty) address else if (ilce.isNotEmpty) ilce,
    ];

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      elevation: 0,
      shadowColor: AppColors.ink.withValues(alpha: 0.06),
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
                    if (metaParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          metaParts.join(' · '),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
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

  static const _tones = [Color(0xFF40916C), Color(0xFF52B788), Color(0xFF2D6A4F), Color(0xFF74C69D)];

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
                color: tone.withValues(alpha: 0.18),
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
      color: ghost ? AppColors.bgSoft : const Color(0xFF40916C).withValues(alpha: 0.12),
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
              color: ghost ? AppColors.ink : const Color(0xFF1B4332),
            ),
          ),
        ),
      ),
    );
  }
}
