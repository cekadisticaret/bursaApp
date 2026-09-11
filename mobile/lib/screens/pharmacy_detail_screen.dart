import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_page.dart';

class PharmacyDetailScreen extends StatefulWidget {
  const PharmacyDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  Map<String, dynamic>? _data;
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
      final data = await auth.api.nobetciEczaneDetail(widget.slug);
      if (mounted) setState(() => _data = data);
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
    final place = (_data?['place'] as Map?)?.cast<String, dynamic>();
    final dutyLabel = _data?['duty_label']?.toString() ?? '';

    if (_loading) {
      return const AppPage(title: 'Nöbetçi eczane', body: Center(child: CircularProgressIndicator()));
    }

    if (place == null) {
      return AppPage(
        title: 'Nöbetçi eczane',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Eczane bulunamadı veya nöbet listesi yenilenmiş olabilir.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Listeye dön')),
              ],
            ),
          ),
        ),
      );
    }

    final name = place['name']?.toString() ?? 'Eczane';
    final district = place['district']?.toString() ?? '';
    final hours = place['hours_short']?.toString() ?? '';
    final address = place['address']?.toString() ?? '';
    final phone = place['phone']?.toString() ?? '';
    final maps = place['maps']?.toString() ?? '';
    final osm = _data?['osm_embed']?.toString() ?? '';

    return AppPage(
      title: name,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF43A047)]),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 32)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        dutyLabel.isNotEmpty ? 'Nöbetçi · $dutyLabel' : 'Nöbetçi',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (district.isNotEmpty)
                  Text(district, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(hours, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(address, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), height: 1.35)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (phone.isNotEmpty)
                      _ActionButton(
                        label: phone.isNotEmpty ? 'Ara · $phone' : 'Ara',
                        onTap: () => launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication),
                      ),
                    if (maps.isNotEmpty)
                      _ActionButton(
                        label: 'Google Maps',
                        ghost: true,
                        onTap: () => launchUrl(Uri.parse(maps), mode: LaunchMode.externalApplication),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (osm.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: SizedBox(
                height: 220,
                child: InkWell(
                  onTap: maps.isNotEmpty ? () => launchUrl(Uri.parse(maps), mode: LaunchMode.externalApplication) : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://staticmap.openstreetmap.de/staticmap.php?center=${place['lat']},${place['lng']}&zoom=15&size=600x300&markers=${place['lat']},${place['lng']},red',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.bgSoft,
                          alignment: Alignment.center,
                          child: const Text('Harita', style: TextStyle(color: AppColors.muted)),
                        ),
                      ),
                      if (maps.isNotEmpty)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FilledButton(
                            onPressed: () => launchUrl(Uri.parse(maps), mode: LaunchMode.externalApplication),
                            child: const Text('Yol tarifi'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap, this.ghost = false});
  final String label;
  final VoidCallback onTap;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ghost ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ),
    );
  }
}

void openPharmacyDetail(BuildContext context, String slug) {
  final s = slug.trim();
  if (s.isEmpty) return;
  Navigator.of(context).push(appRoute(PharmacyDetailScreen(slug: s)));
}
