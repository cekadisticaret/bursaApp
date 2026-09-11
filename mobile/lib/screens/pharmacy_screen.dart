import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import 'pharmacy_detail_screen.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  bool _locating = false;

  String _ilce = '';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final data = await auth.api.nobetciEczaneler(
        ilce: _ilce,
        lat: _lat,
        lng: _lng,
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

  Future<void> _sortByLocation() async {
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
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
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

  void _clearGeo() {
    setState(() {
      _lat = null;
      _lng = null;
    });
    _load();
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
    final count = _data['count'] is int ? _data['count'] as int : 0;
    final total = _data['total'] is int ? _data['total'] as int : count;
    final groupCount = _data['group_count'] is int ? _data['group_count'] as int : groups.length;
    final dutyLabel = _data['duty_label']?.toString() ?? _data['duty_date']?.toString() ?? '';
    final pageSub = _data['page_sub']?.toString() ?? '';
    final heroNote = _data['hero_note']?.toString() ?? '';
    final hasGeo = _data['has_geo'] == true;
    final districts = (_data['districts'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();

    return AppPage(
      title: 'Nöbetçi eczaneler',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              children: [
                _HeroBlock(
                  dutyLabel: dutyLabel,
                  total: total,
                  groupCount: groupCount,
                  hasGeo: hasGeo,
                  subtitle: pageSub,
                  note: heroNote,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$count eczane${_ilce.isNotEmpty ? ' · $_ilce' : ''}${hasGeo ? ' · yakından uzağa' : ''}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (hasGeo)
                        TextButton(onPressed: _clearGeo, child: const Text('İlçe sırası'))
                      else
                        FilledButton(
                          onPressed: _locating ? null : _sortByLocation,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: _locating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('📍 Konuma göre', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                if (hasGeo)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: _locating ? null : _sortByLocation, child: const Text('Konumu yenile')),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _IlcePicker(
                    ilce: _ilce,
                    districts: districts,
                    onChanged: (v) {
                      setState(() => _ilce = v ?? '');
                      _load();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading && groups.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Center(
                      child: Text(
                        'Liste henüz yok veya bu ilçede nöbetçi bulunamadı.',
                        style: TextStyle(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...groups.expand((g) {
                    final label = g['label']?.toString() ?? '';
                    final places = _asPlaces(g['places']);
                    return [
                      _GroupHeader(label: label, count: places.length),
                      ...places.map((p) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: _PharmacyRow(place: p),
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
    required this.dutyLabel,
    required this.total,
    required this.groupCount,
    required this.hasGeo,
    required this.subtitle,
    required this.note,
  });

  final String dutyLabel;
  final int total;
  final int groupCount;
  final bool hasGeo;
  final String subtitle;
  final String note;

  static const _green = Color(0xFF43A047);
  static const _greenDeep = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_greenDeep, _green]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💊', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text('Bugün nöbetçi', style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            dutyLabel.isNotEmpty ? dutyLabel : 'Bursa',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.35)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(label: '$total nöbetçi'),
              _StatChip(label: hasGeo ? 'liste' : '$groupCount ilçe'),
              const _StatChip(label: '18:30 başlangıç'),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
          ],
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bölge', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: ilce.isEmpty ? '' : ilce,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tümü')),
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
          Text('$count eczane', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PharmacyRow extends StatelessWidget {
  const _PharmacyRow({required this.place});
  final Map<String, dynamic> place;

  static const _green = Color(0xFF43A047);
  static const _greenDeep = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final slug = place['slug']?.toString() ?? '';
    final name = place['name']?.toString() ?? 'Eczane';
    final initial = place['initial']?.toString() ?? (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final address = place['address']?.toString() ?? '';
    final district = place['district']?.toString() ?? '';
    final phone = place['phone']?.toString() ?? '';
    final maps = place['maps']?.toString() ?? '';
    final hours = place['hours_short']?.toString() ?? '';
    final distance = place['distance_label']?.toString() ?? '';
    final walkMin = place['walk_min'];

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: slug.isEmpty ? null : () => openPharmacyDetail(context, slug),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(initial: initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (distance.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          walkMin is int ? '$distance · ~$walkMin dk yürüme' : distance,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        address.isNotEmpty ? address : district,
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
                            onTap: () => openPharmacyDetail(context, slug),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hours.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    hours,
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
  const _Thumb({required this.initial});
  final String initial;

  static const _tones = [Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF2E7D32), Color(0xFF81C784)];

  @override
  Widget build(BuildContext context) {
    final tone = _tones[initial.hashCode.abs() % _tones.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        color: tone.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Text('💊', style: TextStyle(fontSize: 22, color: tone)),
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
      color: ghost ? AppColors.bgSoft : _PharmacyRow._green.withValues(alpha: 0.12),
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
              color: ghost ? AppColors.ink : _PharmacyRow._greenDeep,
            ),
          ),
        ),
      ),
    );
  }
}
