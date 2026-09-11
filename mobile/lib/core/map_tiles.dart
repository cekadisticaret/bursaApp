/// Web `map_tiles.py` ile aynı döşeme — Carto light veya Esri açık gri.
class MapTileLayerSpec {
  const MapTileLayerSpec({
    required this.urlTemplate,
    this.attribution = '',
    this.opacity = 1,
    this.maxZoom = 19,
    this.subdomains = const [],
  });

  final String urlTemplate;
  final String attribution;
  final double opacity;
  final int maxZoom;
  final List<String> subdomains;
}

List<MapTileLayerSpec> appMapTileLayers() {
  const cartoKey = String.fromEnvironment('CARTO_API_KEY', defaultValue: '');
  if (cartoKey.isNotEmpty) {
    return [
      MapTileLayerSpec(
        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=$cartoKey',
        attribution: '© OpenStreetMap © CARTO',
        subdomains: const ['a', 'b', 'c', 'd'],
        maxZoom: 19,
      ),
    ];
  }
  return const [
    MapTileLayerSpec(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap',
      maxZoom: 19,
    ),
  ];
}
