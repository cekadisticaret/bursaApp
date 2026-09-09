import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_store.dart';
import '../screens/create_event_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/food_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/floating_tab_bar.dart';
import '../widgets/login_sheet.dart';
import '../shell/shell_scope.dart';
import '../navigation/app_routes.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = ShellTabs.feed;

  late final _pages = [
    const FeedScreen(),
    const ExploreScreen(),
    const FoodScreen(),
    const ProfileScreen(),
  ];

  void _openCreate() {
    requireAuth(context, () {
      Navigator.of(context).push(
        appRoute(const CreateEventScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthStore>();
    return ShellScope(
      goTab: (i) => setState(() => _tab = i),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppHeader(
                  showGreeting: _tab == ShellTabs.feed,
                  onProfileTap: () => setState(() => _tab = ShellTabs.profile),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: FloatingTabBar(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
          onCreateTap: _openCreate,
        ),
      ),
    );
  }
}
