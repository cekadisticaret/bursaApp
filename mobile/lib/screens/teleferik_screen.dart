import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import 'place_detail_screen.dart';
import 'route_planner_screen.dart';

class TeleferikScreen extends StatefulWidget {
  const TeleferikScreen({super.key});

  @override
  State<TeleferikScreen> createState() => _TeleferikScreenState();
}

class _TeleferikScreenState extends State<TeleferikScreen> {
  Map<String, dynamic> _data = {};
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
      final data = await auth.api.teleferikInfo();
      if (mounted) {
        setState(() {
          _data = data;
        });
      }
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
    final stations = (_data['stations'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final prices = (_data['prices'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final discounts = (_data['discounts'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final buses = (_data['buses'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final tips = (_data['tips'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final sources = (_data['sources'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final phones = (_data['phones'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final hours = (_data['hours'] as Map?)?.cast<String, dynamic>() ?? {};
    final tam = prices.isNotEmpty ? prices.first['amount_tl'] : null;
    final ogr = prices.length > 1 ? prices[1]['amount_tl'] : null;

    return AppPage(
      title: 'Uludağ teleferik',
      body: _loading && _data.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _HeroBlock(data: _data, tamPrice: tam, ogrPrice: ogr),
                const SizedBox(height: 12),
                _HoursStrip(hours: hours),
                if (prices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Bilet fiyatları',
                    subtitle: 'Gidiş-dönüş · gişe ve online tarife',
                    child: Column(
                      children: prices.map((p) => _PriceCard(price: p)).toList(),
                    ),
                  ),
                ],
                if (discounts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    title: 'İndirimli günler',
                    subtitle: 'Kimlik veya belge gişede sorulur',
                    child: Column(
                      children: discounts.map((d) => _DiscountCard(item: d)).toList(),
                    ),
                  ),
                ],
                if (hours.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Açılış · kapanış',
                    subtitle: 'Hava muhalefetinde seferler durabilir',
                    child: _HoursPanel(hours: hours),
                  ),
                ],
                if (buses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Teleferiğe nasıl gidilir?',
                    subtitle: 'Teferrüç alt istasyonu — Bursaray en pratik seçenek',
                    child: Column(
                      children: buses.map((b) => _BusCard(item: b)).toList(),
                    ),
                  ),
                ],
                if (stations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    title: 'İstasyon hattı',
                    subtitle: "Teferrüç'ten oteller bölgesine",
                    child: Column(
                      children: stations.asMap().entries.map((e) => _StationRow(station: e.value, isLast: e.key == stations.length - 1)).toList(),
                    ),
                  ),
                ],
                if (tips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Section(
                    title: 'Pratik ipuçları',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tips.map((t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• ${_stripHtml(t)}', style: const TextStyle(height: 1.4, color: AppColors.muted)))).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _Section(
                  title: 'Uludağ gününü planla',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Rota planla'),
                        onPressed: () => Navigator.of(context).push(appRoute(const RoutePlannerScreen())),
                      ),
                      ActionChip(
                        label: const Text('Gezilecek kaydı'),
                        onPressed: () => openPlaceDetail(context, 'teleferik'),
                      ),
                    ],
                  ),
                ),
                if (phones.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: phones.map((p) => ActionChip(avatar: const Icon(Icons.phone, size: 16), label: Text(p), onPressed: () => _callPhone(p))).toList(),
                  ),
                ],
                if (sources.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sources.map((s) {
                      final label = s['label']?.toString() ?? 'Kaynak';
                      final url = s['url']?.toString() ?? '';
                      return ActionChip(label: Text(label, style: const TextStyle(fontSize: 12)), onPressed: url.isEmpty ? null : () => _openUrl(url));
                    }).toList(),
                  ),
                ],
                if ((_data['disclaimer']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_data['disclaimer'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4)),
                ],
              ],
            ),
    );
  }
}

class _HeroBlock extends StatelessWidget {
  const _HeroBlock({required this.data, this.tamPrice, this.ogrPrice});
  final Map<String, dynamic> data;
  final dynamic tamPrice;
  final dynamic ogrPrice;

  @override
  Widget build(BuildContext context) {
    final updated = data['generated_label']?.toString() ?? '';
    final web = data['web']?.toString() ?? '';
    final heroUrl = '${AppConfig.siteBase}/static/visit/teleferik.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Stack(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CachedNetworkImage(imageUrl: heroUrl, fit: BoxFit.cover),
          ),
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, AppColors.nav.withValues(alpha: 0.92)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Türkiye'nin ilk teleferiği · 1963", style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800, fontSize: 11)),
                const SizedBox(height: 6),
                const Text('Uludağ\'a\nkuşbakışı çıkış', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, height: 1.05)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (tamPrice != null) _HeroPill(text: '$tamPrice TL tam bilet'),
                    if (ogrPrice != null) _HeroPill(text: '$ogrPrice TL öğrenci'),
                    const _HeroPill(text: 'Cuma %50 halk günü'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (web.isNotEmpty)
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _openUrl(web),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.nav),
                          child: const Text('Online bilet', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
                if (updated.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Güncelleme: $updated', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

class _HoursStrip extends StatelessWidget {
  const _HoursStrip({required this.hours});
  final Map<String, dynamic> hours;

  @override
  Widget build(BuildContext context) {
    final summer = (hours['summer'] as Map?)?.cast<String, dynamic>();
    final winter = (hours['winter'] as Map?)?.cast<String, dynamic>();
    return Row(
      children: [
        Expanded(child: _StripTile(icon: '🕐', title: summer?['weekday']?.toString() ?? '—', subtitle: 'Yaz sezonu')),
        const SizedBox(width: 8),
        Expanded(child: _StripTile(icon: '❄️', title: winter?['weekday']?.toString() ?? '—', subtitle: 'Kış sezonu')),
        const SizedBox(width: 8),
        const Expanded(child: _StripTile(icon: '🚡', title: '4 istasyon', subtitle: '9 km hat')),
      ],
    );
  }
}

class _StripTile extends StatelessWidget {
  const _StripTile({required this.icon, required this.title, required this.subtitle});
  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadii.sm), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadii.lg), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});
  final Map<String, dynamic> price;

  @override
  Widget build(BuildContext context) {
    final cat = price['category']?.toString() ?? '';
    final icon = cat.contains('halk') ? '🏷️' : (cat.contains('ogrenci') ? '🎓' : '🎫');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${price['amount_tl'] ?? '—'} TL', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.accentDeep)),
                Text(price['label']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                if ((price['note']?.toString() ?? '').isNotEmpty)
                  Text(price['note'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['rate']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.amber)),
          Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
          if ((item['schedule']?.toString() ?? '').isNotEmpty)
            Text(item['schedule'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if ((item['who']?.toString() ?? '').isNotEmpty)
            Text(item['who'].toString(), style: const TextStyle(fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }
}

class _HoursPanel extends StatelessWidget {
  const _HoursPanel({required this.hours});
  final Map<String, dynamic> hours;

  Widget _seasonCard(String key, String emoji) {
    final s = (hours[key] as Map?)?.cast<String, dynamic>() ?? {};
    if (s.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji ${s['label'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(s['weekday']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Hafta sonu: ${s['weekend'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          if ((s['note']?.toString() ?? '').isNotEmpty)
            Text(s['note'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closed = (hours['closed_when'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seasonCard('summer', '☀️'),
        _seasonCard('winter', '❄️'),
        if (closed.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadii.sm)),
            child: Text('⚠️ Kapalı olabilecek durumlar: ${closed.join(' · ')}', style: const TextStyle(fontSize: 12, height: 1.35)),
          ),
      ],
    );
  }
}

class _BusCard extends StatelessWidget {
  const _BusCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final lines = item['lines']?.toString() ?? '';
    final icon = lines.contains('Bursaray') ? '🚇' : (lines.toLowerCase().contains('dolmuş') ? '🚐' : (lines.contains('Özel') ? '🚗' : '🚌'));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lines, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${item['from'] ?? ''} → ${item['to'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                if ((item['note']?.toString() ?? '').isNotEmpty)
                  Text(item['note'].toString(), style: const TextStyle(fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({required this.station, required this.isLast});
  final Map<String, dynamic> station;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: AppColors.accentDeep, shape: BoxShape.circle),
            ),
            if (!isLast) Container(width: 2, height: 48, color: AppColors.accentDeep.withValues(alpha: 0.35)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(station['ilce']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                if ((station['note']?.toString() ?? '').isNotEmpty)
                  Text(station['note'].toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _stripHtml(String raw) {
  return raw.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _callPhone(String raw) async {
  final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: digits);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
