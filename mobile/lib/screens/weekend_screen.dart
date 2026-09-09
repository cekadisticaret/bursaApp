import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/destination_card.dart';

class WeekendScreen extends StatefulWidget {
  const WeekendScreen({super.key});

  @override
  State<WeekendScreen> createState() => _WeekendScreenState();
}

class _WeekendScreenState extends State<WeekendScreen> {
  List<PlaceItem> _places = [];
  String _label = '';
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
      final data = await auth.api.weekend();
      final all = <PlaceItem>[];
      for (final dayKey in ['saturday', 'sunday']) {
        final day = data[dayKey];
        if (day is! List) continue;
        for (final block in day) {
          if (block is! Map) continue;
          for (final p in (block['places'] as List? ?? [])) {
            if (p is Map) all.add(PlaceItem.fromJson(p.cast<String, dynamic>()));
          }
        }
      }
      if (mounted) {
        final label = [
          data['saturday_label']?.toString(),
          data['sunday_label']?.toString(),
        ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
        setState(() {
          _places = all.take(16).toList();
          _label = label.isEmpty ? 'Hafta sonu önerileri' : label;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Hafta sonu planı',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(_label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  ..._places.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DestinationCard(place: p),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
