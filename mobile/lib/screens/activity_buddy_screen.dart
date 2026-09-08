import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/login_sheet.dart';

class ActivityBuddyScreen extends StatefulWidget {
  const ActivityBuddyScreen({super.key, this.initialType});

  final String? initialType;

  @override
  State<ActivityBuddyScreen> createState() => _ActivityBuddyScreenState();
}

class _ActivityBuddyScreenState extends State<ActivityBuddyScreen> {
  List<ActivitySeek> _rows = [];
  List<ActivityType> _types = [];
  String _filter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialType ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final types = await auth.api.activityTypes();
      final rows = await auth.api.activitySeeking(type: _filter.isEmpty ? null : _filter);
      if (mounted) {
        setState(() {
          _types = types;
          _rows = rows;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSeek() async {
    final auth = context.read<AuthStore>();
    if (!auth.isLoggedIn) {
      await showLoginSheet(context);
      return;
    }
    if (_types.isEmpty) return;

    String activityType = _filter.isNotEmpty ? _filter : _types.first.key;
    final titleCtrl = TextEditingController();
    final whenCtrl = TextEditingController(text: 'Esnek');
    final noteCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    var slots = 1;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('İlan ver', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: activityType,
                      decoration: const InputDecoration(labelText: 'Aktivite'),
                      items: _types
                          .map((t) => DropdownMenuItem(value: t.key, child: Text('${t.emoji} ${t.label}')))
                          .toList(),
                      onChanged: (v) => setModal(() => activityType = v ?? activityType),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Başlık (isteğe bağlı)')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: slots,
                            decoration: const InputDecoration(labelText: 'Kaç kişi'),
                            items: List.generate(10, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                            onChanged: (v) => setModal(() => slots = v ?? 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: whenCtrl, decoration: const InputDecoration(labelText: 'Ne zaman?')),
                    const SizedBox(height: 8),
                    TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Bulışma yeri')),
                    const SizedBox(height: 8),
                    TextField(controller: noteCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Not')),
                    const SizedBox(height: 8),
                    TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'İletişim (katılanlar görür)')),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.nav, foregroundColor: AppColors.lime),
                      child: const Text('Yayınla'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (ok != true || !mounted) return;

    try {
      await auth.api.createActivitySeek({
        'activity_type': activityType,
        if (titleCtrl.text.trim().isNotEmpty) 'title': titleCtrl.text.trim(),
        'slots_needed': slots,
        'when_label': whenCtrl.text.trim(),
        'venue': venueCtrl.text.trim(),
        'note': noteCtrl.text.trim(),
        'contact_hint': contactCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan yayında')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _join(ActivitySeek row) async {
    final auth = context.read<AuthStore>();
    if (!auth.isLoggedIn) {
      await showLoginSheet(context);
      return;
    }
    try {
      await auth.api.joinActivitySeek(row.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Katıldın')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _leave(ActivitySeek row) async {
    try {
      await context.read<AuthStore>().api.leaveActivitySeek(row.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaş / partner ara')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSeek,
        label: const Text('İlan ver'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _FilterChip(label: 'Tümü', selected: _filter.isEmpty, onTap: () { setState(() => _filter = ''); _load(); }),
                ..._types.map(
                  (t) => _FilterChip(
                    label: '${t.emoji} ${t.label}',
                    selected: _filter == t.key,
                    onTap: () { setState(() => _filter = t.key); _load(); },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('Açık ilan yok — ilk ilanı sen ver', style: TextStyle(color: AppColors.muted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _rows.length,
                        itemBuilder: (context, i) => _SeekCard(
                          row: _rows[i],
                          onJoin: () => _join(_rows[i]),
                          onLeave: () => _leave(_rows[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.nav.withValues(alpha: 0.2),
      ),
    );
  }
}

class _SeekCard extends StatelessWidget {
  const _SeekCard({required this.row, required this.onJoin, required this.onLeave});
  final ActivitySeek row;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    Text('${row.host} · ${row.ilce.isEmpty ? "Bursa" : row.ilce} · ${row.timeLabel}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Chip(label: Text('${row.spotsLeft} kontenjan'), backgroundColor: AppColors.bgSoft),
            ],
          ),
          if (row.note.isNotEmpty) ...[const SizedBox(height: 8), Text(row.note)],
          if (row.venue.isNotEmpty) Text('📍 ${row.venue}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          if (row.contactHint.isNotEmpty && (row.joined || row.isMine))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('💬 ${row.contactHint}', style: const TextStyle(color: AppColors.nav, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: row.isMine
                ? const Text('Senin ilanın', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))
                : row.joined
                    ? OutlinedButton(onPressed: onLeave, child: const Text('Ayrıl'))
                    : row.spotsLeft > 0
                        ? FilledButton(onPressed: onJoin, child: const Text('Katıl'))
                        : const Text('Dolu', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
