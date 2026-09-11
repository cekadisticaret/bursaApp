import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/destination_card.dart';
import '../widgets/event_place_card.dart';

class CategoryPlacesScreen extends StatefulWidget {
  const CategoryPlacesScreen({super.key, required this.title, required this.category, this.subcategory});

  final String title;
  final String category;
  final String? subcategory;

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen> {
  List<PlaceItem> _places = [];
  bool _loading = true;
  String? _error;

  static const _eventCategories = {'event', 'concert', 'theater', 'cinema'};

  bool get _eventList => _eventCategories.contains(widget.category);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthStore>();
      final rows = await auth.api.places(
        category: widget.category,
        sub: widget.subcategory,
        limit: 60,
      );
      if (mounted) setState(() => _places = rows);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.title,
      onRefresh: _load,
      body: _loading && _places.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: const [SizedBox(height: 180), Center(child: CircularProgressIndicator())],
            )
          : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error!, textAlign: TextAlign.center)),
                    const SizedBox(height: 12),
                    Center(child: TextButton(onPressed: _load, child: const Text('Tekrar dene'))),
                  ],
                )
              : _places.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Bu kategoride kayıt yok.', style: TextStyle(color: AppColors.muted))),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _places.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _eventList
                            ? EventPlaceCard(place: _places[i])
                            : DestinationCard(place: _places[i]),
                      ),
                    ),
    );
  }
}
