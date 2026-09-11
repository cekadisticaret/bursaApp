import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/place_nav.dart';
import 'login_sheet.dart';

class DestinationCard extends StatefulWidget {
  const DestinationCard({super.key, required this.place, this.onTap});

  final PlaceItem place;
  final VoidCallback? onTap;

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  late bool _isFav;
  bool _favBusy = false;

  @override
  void initState() {
    super.initState();
    _isFav = widget.place.isFav;
  }

  @override
  void didUpdateWidget(covariant DestinationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.slug != widget.place.slug) {
      _isFav = widget.place.isFav;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favBusy || widget.place.slug.isEmpty) return;
    await requireAuth(context, () async {
      setState(() => _favBusy = true);
      try {
        final auth = context.read<AuthStore>();
        final r = await auth.api.togglePlaceFavorite(widget.place.slug);
        if (!mounted) return;
        setState(() {
          _isFav = r.isFav;
          widget.place.isFav = r.isFav;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.isFav ? 'Favorilere eklendi' : 'Favoriden çıkarıldı')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      } finally {
        if (mounted) setState(() => _favBusy = false);
      }
    });
  }

  void _openDetail() {
    final tap = widget.onTap;
    if (tap != null) {
      tap();
      return;
    }
    if (widget.place.slug.isNotEmpty) {
      openPlaceDetail(context, widget.place.slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.place.imgUrl;
    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (img.isNotEmpty)
              CachedNetworkImage(
                imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img',
                fit: BoxFit.cover,
              )
            else
              Container(color: AppColors.bgSoft),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.ink.withValues(alpha: 0.8)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _favBusy ? null : _toggleFavorite,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: _favBusy
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: _isFav ? AppColors.coral : AppColors.ink,
                        ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.place.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  Row(
                    children: [
                      const Icon(Icons.place, color: AppColors.lime, size: 14),
                      const SizedBox(width: 4),
                      Text(widget.place.ilce, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceListTile extends StatelessWidget {
  const PlaceListTile({super.key, required this.place});
  final PlaceItem place;

  @override
  Widget build(BuildContext context) => DestinationCard(place: place);
}
