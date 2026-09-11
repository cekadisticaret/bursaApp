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

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (place.when.isNotEmpty) place.when,
      if (place.venueName.isNotEmpty) place.venueName else if (place.ilce.isNotEmpty) place.ilce,
    ].join(' · ');

    return Semantics(
      button: true,
      label: place.title,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: place.slug.isEmpty ? null : () => openPlaceDetail(context, place.slug),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Ink(
            height: 112,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.muted.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadii.lg)),
                  child: SizedBox(
                    width: 96,
                    child: place.imgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: place.imgUrl.startsWith('http') ? place.imgUrl : '${AppConfig.siteBase}${place.imgUrl}',
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: AppColors.bgSoft,
                            child: Icon(_fallbackIcon, color: AppColors.muted.withValues(alpha: 0.45), size: 32),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (place.categoryLabel.isNotEmpty)
                          Text(
                            place.categoryLabel,
                            style: const TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        Text(
                          place.title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(meta, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
                        ] else if (place.blurb.isNotEmpty) ...[
                          const SizedBox(height: 6),
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
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
