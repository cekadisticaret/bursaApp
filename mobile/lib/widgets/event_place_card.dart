import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/place_nav.dart';

class EventPlaceCard extends StatelessWidget {
  const EventPlaceCard({super.key, required this.place});

  final PlaceItem place;

  IconData get _fallbackIcon {
    switch (place.category) {
      case 'cinema':
        return Icons.movie_rounded;
      case 'theater':
        return Icons.theater_comedy_rounded;
      case 'concert':
        return Icons.music_note_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  void _openDetail(BuildContext context) {
    if (place.slug.isEmpty) return;
    openPlaceDetail(context, place.slug);
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
      child: ListTile(
        onTap: place.slug.isEmpty ? null : () => _openDetail(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: leading,
        title: Text(
          place.title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.categoryLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  place.categoryLabel,
                  style: const TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            if (meta.isNotEmpty)
              Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35))
            else if (place.blurb.isNotEmpty)
              Text(
                place.blurb,
                style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9), fontSize: 12, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: AppColors.muted.withValues(alpha: 0.12)),
        ),
      ),
    );
  }
}
