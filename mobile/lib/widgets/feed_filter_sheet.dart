import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../navigation/app_routes.dart';
import '../navigation/feed_nav.dart';
import '../screens/category_places_screen.dart';

class FeedFilterOption {
  const FeedFilterOption({required this.label, required this.icon, required this.action});
  final String label;
  final IconData icon;
  final FeedFilterAction action;
}

enum FeedFilterAction { event, foodTab, visit, category }

class FeedFilterSheet extends StatelessWidget {
  const FeedFilterSheet({super.key});

  static const _options = [
    FeedFilterOption(label: 'Etkinlikler', icon: Icons.event_rounded, action: FeedFilterAction.event),
    FeedFilterOption(label: 'Yeme-içme', icon: Icons.restaurant_rounded, action: FeedFilterAction.foodTab),
    FeedFilterOption(label: 'Gezilecek', icon: Icons.landscape_rounded, action: FeedFilterAction.visit),
    FeedFilterOption(label: 'Konserler', icon: Icons.music_note_rounded, action: FeedFilterAction.category),
    FeedFilterOption(label: 'Tiyatro', icon: Icons.theater_comedy_rounded, action: FeedFilterAction.category),
    FeedFilterOption(label: 'Sinema', icon: Icons.movie_rounded, action: FeedFilterAction.category),
    FeedFilterOption(label: 'Oteller', icon: Icons.hotel_rounded, action: FeedFilterAction.category),
    FeedFilterOption(label: 'Eğlence', icon: Icons.celebration_rounded, action: FeedFilterAction.category),
    FeedFilterOption(label: 'Gece hayatı', icon: Icons.nightlife_rounded, action: FeedFilterAction.category),
  ];

  static const _categoryKeys = {
    'Konserler': 'concert',
    'Tiyatro': 'theater',
    'Sinema': 'cinema',
    'Oteller': 'hotel',
    'Eğlence': 'fun',
    'Gece hayatı': 'nightlife',
  };

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (_) => const FeedFilterSheet(),
    );
  }

  void _pick(BuildContext context, FeedFilterOption opt) {
    Navigator.pop(context);
    switch (opt.action) {
      case FeedFilterAction.event:
        openFeedChip(context, 'event');
      case FeedFilterAction.foodTab:
        openFeedChip(context, 'food');
      case FeedFilterAction.visit:
        openFeedChip(context, 'visit');
      case FeedFilterAction.category:
        final key = _categoryKeys[opt.label];
        if (key == null) return;
        Navigator.of(context).push(
          appRoute(CategoryPlacesScreen(title: opt.label, category: key)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Kategori filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'Mekan listesine git',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._options.map(
              (opt) => ListTile(
                leading: Icon(opt.icon, color: AppColors.accentDeep),
                title: Text(opt.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                onTap: () => _pick(context, opt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
