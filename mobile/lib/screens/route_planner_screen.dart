import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';
import 'place_detail_screen.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final _budgetCtrl = TextEditingController(text: '2000');
  int _people = 2;
  String _transport = 'bus';
  bool _loading = false;
  Map<String, dynamic>? _route;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _buildRoute() async {
    setState(() {
      _loading = true;
      _route = null;
    });
    try {
      final budget = int.tryParse(_budgetCtrl.text.trim()) ?? 0;
      final auth = context.read<AuthStore>();
      final data = await auth.api.planDayRoute(
        people: _people,
        budgetTl: budget,
        transport: _transport,
      );
      if (mounted) setState(() => _route = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Rota planlayıcı',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Bütçene ve ulaşımına göre 1 günlük Bursa planı',
            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.35),
          ),
          const SizedBox(height: 16),
          _buildForm(),
          if (_loading) ...[
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_route != null && !_loading) ...[
            const SizedBox(height: 24),
            _buildResult(_route!),
          ],
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kişi sayısı', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PeopleBtn(
                          value: _people,
                          onChanged: (v) => setState(() => _people = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bütçe (TL)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'örn. 2000',
                        filled: true,
                        fillColor: AppColors.bgSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Ulaşım', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TransportChip(
                value: 'bus',
                group: _transport,
                icon: '🚌',
                label: 'Toplu taşıma',
                onPick: (v) => setState(() => _transport = v),
              ),
              _TransportChip(
                value: 'car',
                group: _transport,
                icon: '🚗',
                label: 'Araçlı',
                onPick: (v) => setState(() => _transport = v),
              ),
              _TransportChip(
                value: 'walk',
                group: _transport,
                icon: '🚶',
                label: 'Yürüyüş',
                onPick: (v) => setState(() => _transport = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _loading ? null : _buildRoute,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentDeep,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
            ),
            child: const Text('Rota oluştur', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> route) {
    final title = route['title']?.toString() ?? 'Günün planı';
    final estTotal = route['est_total_tl'];
    final budget = route['budget_tl'];
    final within = route['within_budget'] == true;
    final slots = route['slots'] as List? ?? [];
    final tips = route['tips'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Günün planı', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (estTotal != null)
                    _Badge(text: '~$estTotal TL', tone: _BadgeTone.neutral),
                  if (budget != null)
                    _Badge(
                      text: within ? 'Bütçe $budget TL ✓' : 'Bütçe $budget TL aşıldı',
                      tone: within ? _BadgeTone.ok : _BadgeTone.warn,
                    ),
                  _Badge(text: '${slots.length} durak', tone: _BadgeTone.soft),
                ],
              ),
              if (tips.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...tips.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${t.toString()}', style: const TextStyle(color: AppColors.muted, height: 1.35)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...slots.expand((slot) {
          if (slot is! Map) return <Widget>[];
          final map = slot.cast<String, dynamic>();
          final widgets = <Widget>[];
          final transit = map['transit_from_prev']?.toString();
          if (transit != null && transit.isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🚌 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(transit, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35)),
                    ),
                  ],
                ),
              ),
            );
          }
          widgets.add(_RouteStopCard(slot: map));
          return widgets;
        }),
      ],
    );
  }
}

enum _BadgeTone { neutral, ok, warn, soft }

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.tone});

  final String text;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (tone) {
      case _BadgeTone.ok:
        bg = AppColors.accentDeep.withValues(alpha: 0.15);
        fg = AppColors.accentDeep;
      case _BadgeTone.warn:
        bg = AppColors.coral.withValues(alpha: 0.15);
        fg = AppColors.coral;
      case _BadgeTone.soft:
        bg = AppColors.bgSoft;
        fg = AppColors.muted;
      case _BadgeTone.neutral:
        bg = AppColors.cream;
        fg = AppColors.ink;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _RouteStopCard extends StatelessWidget {
  const _RouteStopCard({required this.slot});

  final Map<String, dynamic> slot;

  @override
  Widget build(BuildContext context) {
    final time = slot['slot_time']?.toString() ?? '';
    final label = slot['slot_label']?.toString() ?? '';
    final title = slot['title']?.toString() ?? 'Durak';
    final slug = slot['slug']?.toString() ?? '';
    final ilce = slot['ilce']?.toString();
    final cost = slot['slot_cost_tl'];
    final icon = _slotIcon(label);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
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
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (time.isNotEmpty)
                            Text(time, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          if (time.isNotEmpty && label.isNotEmpty) const SizedBox(width: 8),
                          if (label.isNotEmpty)
                            Flexible(
                              child: Text(
                                label,
                                style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.25)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (ilce != null && ilce.isNotEmpty)
                            Text(ilce, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          Text(
                            cost == null || (cost is num && cost <= 0) ? 'Ücretsiz' : '~$cost TL',
                            style: TextStyle(
                              color: cost == null || (cost is num && cost <= 0) ? AppColors.accentDeep : AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (slug.isNotEmpty) Icon(Icons.chevron_right_rounded, color: AppColors.muted.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _slotIcon(String label) {
    final lab = label.toLowerCase();
    if (lab.contains('yemeği') || lab.contains('kahvaltı') || lab.contains('öğle')) return '🍽';
    if (lab == 'cafe') return '☕';
    if (lab == 'gezilecek') return '🗺';
    if (lab.contains('köy') || lab.contains('doğa') || lab.contains('tarihî')) return '🌿';
    if (lab == 'etkinlik') return '🎭';
    return '📍';
  }
}

class _PeopleBtn extends StatelessWidget {
  const _PeopleBtn({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          IconButton(
            onPressed: value < 8 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _TransportChip extends StatelessWidget {
  const _TransportChip({
    required this.value,
    required this.group,
    required this.icon,
    required this.label,
    required this.onPick,
  });

  final String value;
  final String group;
  final String icon;
  final String label;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return InkWell(
      onTap: () => onPick(value),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDeep.withValues(alpha: 0.12) : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: selected ? AppColors.accentDeep : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? AppColors.accentDeep : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
