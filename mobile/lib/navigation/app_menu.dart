import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../screens/activity_buddy_screen.dart';
import '../screens/bursaspor_screen.dart';
import '../screens/category_places_screen.dart';
import '../screens/dentists_screen.dart';
import '../screens/doctors_screen.dart';
import '../screens/hospitals_screen.dart';
import '../screens/hotels_screen.dart';
import '../screens/news_screen.dart';
import '../screens/pharmacy_screen.dart';
import '../screens/route_planner_screen.dart';
import '../screens/teleferik_screen.dart';
import '../screens/utilities_screen.dart';
import '../screens/vets_screen.dart';
import '../screens/visit_screen.dart';
import '../screens/weekend_screen.dart';
import '../shell/shell_scope.dart';
import '../widgets/floating_tab_bar.dart';
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
      goTab(ShellTabs.food);
      return;
    case '/gezilecek':
      Navigator.of(context).push(appRoute(const VisitScreen()));
      return;
    case '/etrafimda':
    case '/harita':
      goTab(ShellTabs.explore);
      return;
    case '/rota':
      Navigator.of(context).push(appRoute(const RoutePlannerScreen()));
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
    case '/kamp':
      Navigator.of(context).push(appRoute(const CategoryPlacesScreen(title: 'Kamp alanları', category: 'camp')));
      return;
    case '/oteller':
      Navigator.of(context).push(appRoute(const HotelsScreen()));
      return;
    case '/veterinerler':
      Navigator.of(context).push(appRoute(const VetsScreen()));
      return;
    case '/dis-hekimleri':
      Navigator.of(context).push(appRoute(const DentistsScreen()));
      return;
    case '/doktorlar':
      Navigator.of(context).push(appRoute(const DoctorsScreen()));
      return;
    case '/hastaneler':
      Navigator.of(context).push(appRoute(const HospitalsScreen()));
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
