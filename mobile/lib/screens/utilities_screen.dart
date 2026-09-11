import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import 'teleferik_screen.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  State<UtilitiesScreen> createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  Map<String, dynamic> _utilities = {};
  bool _loading = true;

  static const _sections = [
    _UtilityKind(key: 'water', icon: '💧', title: 'BUSKİ su fiyatları'),
    _UtilityKind(key: 'electricity', icon: '⚡', title: 'Elektrik fiyatları'),
    _UtilityKind(key: 'gas', icon: '🔥', title: 'Doğalgaz fiyatları'),
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
      final data = await auth.api.utilitiesInfo();
      final raw = data['utilities'];
      if (mounted) {
        setState(() {
          _utilities = raw is Map ? Map<String, dynamic>.from(raw) : {};
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
    final disclaimer = _utilities['disclaimer']?.toString() ?? '';
    final updated = _utilities['generated_label']?.toString() ?? '';

    return AppPage(
      title: 'Faturalar & tarifeler',
      body: _loading && _utilities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const Text(
                  'BUSKİ · UEDAŞ · Bursagaz güncel tarife ve iletişim özeti.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                if (updated.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Son güncelleme: $updated', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                ..._sections.map((kind) {
                  final block = _utilities[kind.key];
                  if (block is! Map) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _UtilityBlock(kind: kind, data: Map<String, dynamic>.from(block)),
                  );
                }),
                _TeleferikShortcut(onTap: () => Navigator.of(context).push(appRoute(const TeleferikScreen()))),
                if (disclaimer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(disclaimer, style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12, height: 1.4)),
                ],
              ],
            ),
    );
  }
}

class _UtilityKind {
  const _UtilityKind({required this.key, required this.icon, required this.title});

  final String key;
  final String icon;
  final String title;
}

class _UtilityBlock extends StatefulWidget {
  const _UtilityBlock({required this.kind, required this.data});

  final _UtilityKind kind;
  final Map<String, dynamic> data;

  @override
  State<_UtilityBlock> createState() => _UtilityBlockState();
}

class _UtilityBlockState extends State<_UtilityBlock> {
  bool _branchesOpen = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final company = data['company']?.toString() ?? widget.kind.title;
    final phones = (data['phones'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final emergency = data['emergency']?.toString() ?? '';
    final tariffNote = data['tariff_note']?.toString() ?? '';
    final effective = data['effective_label']?.toString() ?? '';
    final tariffs = (data['tariffs'] as List? ?? []).whereType<Map>().toList();
    final branches = (data['branches'] as List? ?? []).whereType<Map>().toList();
    final sources = (data['sources'] as List? ?? []).whereType<Map>().toList();
    final extraFees = (data['extra_fees'] as List? ?? []).whereType<Map>().toList();
    final tonHint = data['ton_hint']?.toString() ?? '';
    final mergerNote = data['merger_note']?.toString() ?? '';

    final shownBranches = _branchesOpen ? branches : branches.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.kind.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.kind.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    if (company.isNotEmpty && company != widget.kind.title)
                      Text(company, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          if (phones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: phones.map((p) => _PhoneChip(phone: p)).toList(),
            ),
          ],
          if (emergency.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(emergency, style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
          if (effective.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(effective, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
          if (tariffNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(tariffNote, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
          ],
          if (mergerNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(mergerNote, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
          ],
          if (tariffs.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Tarife', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            ...tariffs.map((t) => _TariffRow(data: Map<String, dynamic>.from(t), kind: widget.kind.key)),
          ],
          if (tonHint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tonHint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
          if (extraFees.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...extraFees.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${f['label'] ?? ''}${f['note'] != null ? ' — ${f['note']}' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35),
                ),
              ),
            ),
          ],
          if (branches.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Abone merkezleri', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            ...shownBranches.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BranchTile(
                  title: b['name']?.toString() ?? b['ilce']?.toString() ?? 'Merkez',
                  subtitle: [
                    if ((b['ilce']?.toString() ?? '').isNotEmpty) b['ilce'].toString(),
                    b['address']?.toString() ?? '',
                    if ((b['phone']?.toString() ?? '').isNotEmpty) b['phone'].toString(),
                    b['hours']?.toString() ?? '',
                  ].where((e) => e.isNotEmpty).join('\n'),
                ),
              ),
            ),
            if (branches.length > 4)
              TextButton(
                onPressed: () => setState(() => _branchesOpen = !_branchesOpen),
                child: Text(_branchesOpen ? 'Daha az göster' : '${branches.length - 4} merkez daha'),
              ),
          ],
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sources.map((s) {
                final label = s['label']?.toString() ?? 'Kaynak';
                final url = s['url']?.toString() ?? '';
                return ActionChip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  onPressed: url.isEmpty ? null : () => _openUrl(url),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TariffRow extends StatelessWidget {
  const _TariffRow({required this.data, required this.kind});

  final Map<String, dynamic> data;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final band = data['band']?.toString() ?? '';
    final unit = data['unit']?.toString() ?? '';
    final note = data['note']?.toString() ?? '';
    String price = '';
    if (kind == 'water') {
      final water = data['water_tl'];
      final waste = data['wastewater_tl'];
      if (water != null) price = 'Su ${_fmtTl(water)}/${unit.isEmpty ? 'm³' : unit}';
      if (waste != null) price += ' · Atıksu ${_fmtTl(waste)}/${unit.isEmpty ? 'm³' : unit}';
    } else if (kind == 'electricity') {
      final energy = data['energy_tl'];
      if (energy != null) price = '${_fmtTl(energy, decimals: 3)}/${unit.isEmpty ? 'kWh' : unit}';
    } else if (kind == 'gas') {
      final gas = data['gas_tl'];
      if (gas != null) price = '${_fmtTl(gas)}/${unit.isEmpty ? 'sm³' : unit}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(band, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          if (price.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentDeep)),
          ],
          if (note.isNotEmpty)
            Text(note, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }
}

class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.phone_rounded, size: 16),
      label: Text(phone, style: const TextStyle(fontWeight: FontWeight.w700)),
      onPressed: () => _callPhone(phone),
    );
  }
}

class _TeleferikShortcut extends StatelessWidget {
  const _TeleferikShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🚡', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uludağ teleferik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('Bilet tarifesi · sefer saatleri', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtTl(dynamic val, {int decimals = 2}) {
  if (val == null) return '—';
  final n = val is num ? val.toDouble() : double.tryParse(val.toString());
  if (n == null) return '—';
  final s = n.toStringAsFixed(decimals).replaceAll('.', ',');
  return '$s TL';
}

Future<void> _callPhone(String raw) async {
  final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: digits);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}
