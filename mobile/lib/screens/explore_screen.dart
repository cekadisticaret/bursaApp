import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/map_tiles.dart';
import '../core/theme/app_theme.dart';
import '../widgets/category_pills.dart';

import '../navigation/place_nav.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
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
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;
  String? _routeInfo;
  int _routeReqId = 0;
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
      _routePoints = [];
      _routeInfo = null;
    });
    if (_selected != null) {
      _buildRoute(_selected!);
    }
  }

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      final nearby = await auth.api.nearby(lat: _center.latitude, lng: _center.longitude, r: 2500);
      if (!mounted) return;
      setState(() => _allNearby = nearby);
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yakındaki mekanlar yüklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDist(double? m) {
    if (m == null) return '';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.round()} m';
  }

  String _fmtDur(double? s) {
    if (s == null) return '';
    final min = (s / 60).round();
    if (min < 60) return '$min dk';
    final h = min ~/ 60;
    final r = min % 60;
    return r > 0 ? '$h sa $r dk' : '$h sa';
  }

  void _fitRoute(List<LatLng> points) {
    if (points.length < 2) return;
    final bounds = LatLngBounds.fromPoints([_center, ...points]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 110),
      ),
    );
  }

  Future<void> _buildRoute(PlaceItem place) async {
    if (place.lat == null || place.lng == null) return;
    final reqId = ++_routeReqId;
    setState(() {
      _routeLoading = true;
      _routePoints = [];
      _routeInfo = null;
    });

    final dest = LatLng(place.lat!, place.lng!);
    final auth = context.read<AuthStore>();

    try {
      final route = await auth.api.mapRoute(
        fromLat: _center.latitude,
        fromLng: _center.longitude,
        toLat: dest.latitude,
        toLng: dest.longitude,
      );
      if (!mounted || reqId != _routeReqId) return;
      final points = route.points.map((p) => LatLng(p[0], p[1])).toList();
      final infoParts = [_fmtDist(route.distanceM), _fmtDur(route.durationS)].where((e) => e.isNotEmpty);
      setState(() {
        _routePoints = points;
        _routeLoading = false;
        _routeInfo = infoParts.join(' · ');
      });
      _fitRoute(points);
    } catch (_) {
      if (!mounted || reqId != _routeReqId) return;
      setState(() {
        _routePoints = [_center, dest];
        _routeLoading = false;
        _routeInfo = 'Kuş uçuşu';
      });
      _fitRoute([_center, dest]);
    }
  }

  void _selectPlace(PlaceItem? place) {
    setState(() {
      _selected = place;
      if (place == null) {
        _routePoints = [];
        _routeInfo = null;
        _routeReqId++;
      }
    });
    if (place != null) {
      _buildRoute(place);
    }
  }

  void _onRouteTap() {
    final place = _selected;
    if (place == null) return;
    if (_routePoints.length >= 2 && !_routeLoading) {
      _fitRoute(_routePoints);
      final msg = _routeInfo != null && _routeInfo!.isNotEmpty ? 'Rota · $_routeInfo' : 'Rota haritada';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    _buildRoute(place).then((_) {
      if (!mounted) return;
      final msg = _routeLoading
          ? 'Rota oluşturuluyor…'
          : (_routeInfo != null && _routeInfo!.isNotEmpty ? 'Rota · $_routeInfo' : 'Rota haritada');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // appRefreshBox içindeki ScrollView sonsuz yükseklik veriyordu — harita ve alt kart görünmüyordu.
        final height = constraints.maxHeight;
        return RefreshIndicator(
          onRefresh: _bootstrap,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: SizedBox(
                height: height,
                child: _ExploreBody(
                  mapController: _mapController,
                  center: _center,
                  filter: _filter,
                  filters: _filters,
                  places: _places,
                  allCount: _allNearby.length,
                  selected: _selected,
                  routePoints: _routePoints,
                  routeLoading: _routeLoading,
                  routeInfo: _routeInfo,
                  loading: _loading,
                  onFilter: (v) {
                    setState(() => _filter = v);
                    _applyFilter();
                  },
                  onSelect: _selectPlace,
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
                    if (hit != null && best < 120) {
                      _selectPlace(hit);
                    } else {
                      _selectPlace(null);
                    }
                  },
                  onRoute: _onRouteTap,
                ),
              ),
            ),
          ),
        );
      },
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
    required this.allCount,
    required this.selected,
    required this.routePoints,
    required this.routeLoading,
    required this.routeInfo,
    required this.loading,
    required this.onFilter,
    required this.onSelect,
    required this.onTapMap,
    required this.onRoute,
  });

  final MapController mapController;
  final LatLng center;
  final String filter;
  final List<(String, String)> filters;
  final List<PlaceItem> places;
  final int allCount;
  final PlaceItem? selected;
  final List<LatLng> routePoints;
  final bool routeLoading;
  final String? routeInfo;
  final bool loading;
  final ValueChanged<String> onFilter;
  final ValueChanged<PlaceItem?> onSelect;
  final void Function(LatLng point) onTapMap;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
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
                  ...appMapTileLayers().map(
                    (layer) {
                      final tileLayer = TileLayer(
                        urlTemplate: layer.urlTemplate,
                        subdomains: layer.subdomains,
                        maxZoom: layer.maxZoom.toDouble(),
                        userAgentPackageName: 'com.bursaapp.mobile',
                      );
                      if (layer.opacity >= 1) return tileLayer;
                      return Opacity(opacity: layer.opacity, child: tileLayer);
                    },
                  ),
                  if (routePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: AppColors.nav,
                          strokeWidth: 4.5,
                          borderColor: Colors.white,
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: AppShadows.fab,
                          ),
                          child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 20),
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
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.coral, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text('Çevremde ne var?', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      if (routeLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
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
          if (loading) const Center(child: CircularProgressIndicator()),
          if (!loading && places.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 72),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    allCount > 0
                        ? 'Bu filtrede yakında mekan yok. Başka kategori dene.'
                        : 'Yakında mekan bulunamadı. Konum izni verip yenile.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          if (!loading && places.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: selected != null ? 92 : 8,
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: places.length.clamp(0, 24),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = places[i];
                  final sel = selected?.slug == p.slug;
                  return GestureDetector(
                    onTap: () => onSelect(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.nav : AppColors.card.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppShadows.card,
                        border: Border.all(
                          color: sel ? AppColors.lime : AppColors.muted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        p.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: sel ? AppColors.lime : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PlaceSheet(
                place: selected!,
                routeInfo: routeInfo,
                routeLoading: routeLoading,
                onRoute: onRoute,
              ),
            ),
        ],
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({
    required this.place,
    required this.onRoute,
    this.routeInfo,
    this.routeLoading = false,
  });

  final PlaceItem place;
  final VoidCallback onRoute;
  final String? routeInfo;
  final bool routeLoading;

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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: place.slug.isNotEmpty ? () => openPlaceDetail(context, place.slug) : null,
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
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.46,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                        [
                          place.ilce,
                          if (routeInfo != null && routeInfo!.isNotEmpty) routeInfo!,
                        ].where((e) => e.isNotEmpty).join(' · '),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: routeLoading ? null : onRoute,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.nav,
              foregroundColor: AppColors.lime,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: routeLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.lime))
                : const Icon(Icons.route_rounded),
          ),
        ],
      ),
    );
  }
}
