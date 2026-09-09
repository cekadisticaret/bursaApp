import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../widgets/app_refresh.dart';
import '../widgets/category_pills.dart';
import '../widgets/destination_card.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  String _filterKey = 'food';
  bool _loading = true;
  List<PlaceItem> _places = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthStore>();
      List<PlaceItem> rows;
      switch (_filterKey) {
        case 'live':
          // Web /eglence?spec=Canlı müzik — geçersiz "live" kategorisi sinema vb. karıştırıyordu
          final funRows = await auth.api.places(category: 'fun', spec: 'Canlı müzik', limit: 40);
          final barRows = await auth.api.places(category: 'nightlife', sub: 'canli-muzik', limit: 40);
          final seen = <String>{};
          rows = [...funRows, ...barRows].where((p) {
            if (p.slug.isEmpty || seen.contains(p.slug)) return false;
            seen.add(p.slug);
            return true;
          }).toList();
        case 'fun2':
          rows = await auth.api.places(category: 'fun', limit: 24);
        default:
          rows = await auth.api.places(category: 'food', limit: 24);
      }
      setState(() => _places = rows);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return appRefreshList(
      onRefresh: _load,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        const Text('Yeme & içme', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        CategoryPills(
          items: const [
            ('food', 'Restoran & kafe'),
            ('live', 'Canlı müzik'),
            ('fun2', 'Eğlence'),
          ],
          selected: _filterKey,
          onSelected: (v) {
            setState(() => _filterKey = v);
            _load();
          },
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else
          ..._places.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DestinationCard(place: p),
            ),
          ),
      ],
    );
  }
}
