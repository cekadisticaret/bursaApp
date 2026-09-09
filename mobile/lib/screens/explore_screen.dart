import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_refresh.dart';
import '../widgets/category_pills.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Web MAP_CATEGORIES ile aynı sıra
  static const _filters = [
    ('', 'Tümü'),
    ('food', 'Restoran'),
    ('cafe', 'Cafe'),
    ('visit', 'Gezilecek'),
    ('hotel', 'Otel'),
    ('camp', 'Kamp'),
    ('event', 'Etkinlik'),
    ('concert', 'Konser'),
    ('market', 'Market'),
    ('shop', 'Alışveriş'),
    ('vet', 'Veteriner'),
    ('hospital', 'Hastane'),
    ('school', 'Okul'),
    ('wedding', 'Düğün salonu'),
    ('nightlife', 'Gece hayatı'),
  ];

  String _filter = '';
  List<PlaceItem> _allNearby = [];
  List<PlaceItem> _places = [];
  PlaceItem? _selected;
  LatLng _center = const LatLng(40.1885, 29.0610);
  bool _loading = true;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _locate();
    await _loadPlaces();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _center = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_center, 14);
    } catch (_) {}
  }

  bool _matchesFilter(PlaceItem p) {
    if (_filter.isEmpty) return true;
    if (_filter == 'cafe') return p.category == 'food' && p.subcategory == 'cafe';
    return p.category == _filter;
  }

  void _applyFilter() {
    final filtered = _allNearby.where(_matchesFilter).toList();
    setState(() {
      _places = filtered;
      _selected = filtered.isNotEmpty ? filtered.first : null;
    });
  }

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final nearby = await auth.api.nearby(lat: _center.latitude, lng: _center.longitude, r: 2500);
      setState(() => _allNearby = nearby);
      _applyFilter();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return appRefreshBox(
      onRefresh: _bootstrap,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _ExploreBody(
        mapController: _mapController,
        center: _center,
        filter: _filter,
        filters: _filters,
        places: _places,
        selected: _selected,
        loading: _loading,
        onFilter: (v) {
          setState(() => _filter = v);
          _applyFilter();
        },
        onTapMap: (point) {
          const dist = Distance();
          PlaceItem? hit;
          var best = double.infinity;
          for (final p in _places) {
            if (p.lat == null || p.lng == null) continue;
            final d = dist.as(LengthUnit.Meter, point, LatLng(p.lat!, p.lng!));
            if (d < best) {
              best = d;
              hit = p;
            }
          }
          setState(() {
            if (hit != null && best < 120) {
              _selected = hit;
            } else {
              _selected = null;
            }
          });
        },
        onRoute: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rota oluşturuluyor…')),
          );
        },
      ),
    );
  }
}

class _ExploreBody extends StatelessWidget {
  const _ExploreBody({
    required this.mapController,
    required this.center,
    required this.filter,
    required this.filters,
    required this.places,
    required this.selected,
    required this.loading,
    required this.onFilter,
    required this.onTapMap,
    required this.onRoute,
  });

  final MapController mapController;
  final LatLng center;
  final String filter;
  final List<(String, String)> filters;
  final List<PlaceItem> places;
  final PlaceItem? selected;
  final bool loading;
  final ValueChanged<String> onFilter;
  final void Function(LatLng point) onTapMap;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 160,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                onTap: (event, point) => onTapMap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bursaapp.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: AppShadows.fab,
                        ),
                        child: const Icon(Icons.person_pin_circle, color: AppColors.ink, size: 20),
                      ),
                    ),
                    ...places.where((p) => p.lat != null && p.lng != null).map((p) {
                      final sel = selected?.slug == p.slug;
                      final size = sel ? 44.0 : 36.0;
                      return Marker(
                        point: LatLng(p.lat!, p.lng!),
                        width: size,
                        height: size,
                        alignment: Alignment.center,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: sel ? AppColors.coral : AppColors.nav,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.place, color: Colors.white, size: sel ? 22 : 18),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: AppShadows.card,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.coral, size: 18),
                    SizedBox(width: 6),
                    Text('Çevremde ne var?', style: TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CategoryPills(
                items: filters,
                selected: filter,
                onSelected: onFilter,
              ),
            ],
          ),
        ),
        if (loading)
          const Center(child: CircularProgressIndicator()),
        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: _PlaceSheet(
              place: selected!,
              onRoute: onRoute,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({required this.place, required this.onRoute});
  final PlaceItem place;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    final img = place.imgUrl;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              height: 72,
              child: img.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: img.startsWith('http') ? img : '${AppConfig.siteBase}$img',
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(color: AppColors.bgSoft, child: Icon(Icons.store, color: AppColors.muted.withValues(alpha: 0.4))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text(place.ilce, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onRoute,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.nav,
              foregroundColor: AppColors.lime,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Icon(Icons.route_rounded),
          ),
        ],
      ),
    );
  }
}
