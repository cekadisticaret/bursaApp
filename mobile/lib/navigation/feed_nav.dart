import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../screens/category_places_screen.dart';
import '../screens/place_detail_screen.dart';
import '../screens/visit_screen.dart';
import '../shell/shell_scope.dart';
import '../widgets/floating_tab_bar.dart';

void openFeedChip(BuildContext context, String chip) {
  switch (chip) {
    case 'all':
      return;
    case 'event':
      Navigator.of(context).push(
        appRoute(const CategoryPlacesScreen(title: 'Etkinlikler', category: 'event')),
      );
    case 'food':
      ShellScope.maybeOf(context)?.goTab(ShellTabs.food);
    case 'visit':
      Navigator.of(context).push(appRoute(const VisitScreen()));
  }
}
