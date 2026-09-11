import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/place_nav.dart';

class EventPlaceCard extends StatelessWidget {
  const EventPlaceCard({super.key, required this.place, this.onTap});

  final PlaceItem place;
  final VoidCallback? onTap;

  IconData get _fallbackIcon {
    switch (place.category) {
      case 'cinema':
        return Icons.movie_rounded;
      case 'theater':
        return Icons.theater_comedy_rounded;
      case 'concert':
        return Icons.music_note_rounded;
      case 'camp':
        return Icons.park_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  void _openDetail(BuildContext context) {
    final tap = onTap;
    if (tap != null) {
      tap();
      return;
    }
    final slug = place.detailSlug;
    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detay bulunamadı')),
      );
      return;
    }
    openPlaceDetail(context, slug);
  }

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (place.when.isNotEmpty) place.when,
      if (place.venueName.isNotEmpty) place.venueName else if (place.ilce.isNotEmpty) place.ilce,
    ].join(' · ');

    Widget leading;
    if (place.imgUrl.isNotEmpty) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: SizedBox(
          width: 72,
          height: 72,
          child: CachedNetworkImage(
            imageUrl: place.imgUrl.startsWith('http') ? place.imgUrl : '${AppConfig.siteBase}${place.imgUrl}',
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      leading = Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(_fallbackIcon, color: AppColors.muted.withValues(alpha: 0.45), size: 28),
      );
    }

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.categoryLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.categoryLabel,
                        style: const TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
                    ] else if (place.blurb.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.blurb,
                        style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
