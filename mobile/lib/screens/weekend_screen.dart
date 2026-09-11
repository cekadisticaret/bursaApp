import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/app_refresh.dart';
import '../widgets/event_place_card.dart';

class WeekendScreen extends StatefulWidget {
  const WeekendScreen({super.key});

  @override
  State<WeekendScreen> createState() => _WeekendScreenState();
}

class _WeekendDaySection {
  _WeekendDaySection({required this.title, required this.places});

  final String title;
  final List<PlaceItem> places;
}

class _WeekendScreenState extends State<WeekendScreen> {
  List<_WeekendDaySection> _sections = [];
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
      final sections = <_WeekendDaySection>[];
      for (final dayKey in ['saturday', 'sunday']) {
        final day = data[dayKey];
        if (day is! List) continue;
        final places = <PlaceItem>[];
        for (final block in day) {
          if (block is! Map) continue;
          for (final p in (block['places'] as List? ?? [])) {
            if (p is Map) places.add(PlaceItem.fromJson(p.cast<String, dynamic>()));
          }
        }
        if (places.isEmpty) continue;
        final labelKey = '${dayKey}_label';
        final title = data[labelKey]?.toString().trim();
        sections.add(
          _WeekendDaySection(
            title: (title != null && title.isNotEmpty) ? title : (dayKey == 'saturday' ? 'Cumartesi' : 'Pazar'),
            places: places,
          ),
        );
      }
      if (mounted) {
        final label = [
          data['saturday_label']?.toString(),
          data['sunday_label']?.toString(),
        ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
        setState(() {
          _sections = sections;
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
      body: _loading && _sections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : appRefreshList(
              onRefresh: _load,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(_label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
                const SizedBox(height: 12),
                if (_sections.isEmpty && !_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Bu hafta sonu için öneri yok.', style: TextStyle(color: AppColors.muted))),
                  )
                else
                  ..._sections.expand(
                    (section) => [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 10),
                        child: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      ),
                      ...section.places.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventPlaceCard(place: p),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
