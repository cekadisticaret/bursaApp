import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../screens/activity_buddy_screen.dart';
import '../screens/bursaspor_screen.dart';
import '../screens/category_places_screen.dart';
import '../screens/news_screen.dart';
import '../screens/pharmacy_screen.dart';
import '../screens/teleferik_screen.dart';
import '../screens/utilities_screen.dart';
import '../screens/weekend_screen.dart';
import '../shell/shell_scope.dart';
import 'app_routes.dart';

void openMenuLink(BuildContext context, MenuLink item) {
  final path = item.path;

  void goTab(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ShellScope.maybeOf(context)?.goTab(index);
  }

  switch (path) {
    case '/feed':
      goTab(0);
      return;
    case '/yeme-icme':
      goTab(3);
      return;
    case '/gezilecek':
      goTab(2);
      return;
    case '/etrafimda':
    case '/harita':
    case '/rota':
      goTab(1);
      return;
    case '/arkadas-ara':
      Navigator.of(context).push(appRoute(const ActivityBuddyScreen()));
      return;
    case '/nobetci-eczaneler':
      Navigator.of(context).push(appRoute(const PharmacyScreen()));
      return;
    case '/haberler':
      Navigator.of(context).push(appRoute(const NewsScreen()));
      return;
    case '/bursaspor':
      Navigator.of(context).push(appRoute(const BursasporScreen()));
      return;
    case '/hafta-sonu':
      Navigator.of(context).push(appRoute(const WeekendScreen()));
      return;
    case '/uludag-teleferik':
      Navigator.of(context).push(appRoute(const TeleferikScreen()));
      return;
    case '/faturalar':
      Navigator.of(context).push(appRoute(const UtilitiesScreen()));
      return;
    case '/eglence':
      Navigator.of(context).push(appRoute(const CategoryPlacesScreen(title: 'Eğlence', category: 'fun')));
      return;
  }

  final cat = item.category;
  if (cat != null && cat.isNotEmpty) {
    Navigator.of(context).push(appRoute(CategoryPlacesScreen(title: item.label, category: cat)));
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.label} — mobil ekran hazırlanıyor')));
}
