import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Alt menü sekmeleri — 4 ikon + ortada FAB.
abstract final class ShellTabs {
  static const feed = 0;
  static const explore = 1;
  static const food = 2;
  static const profile = 3;
}

class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onCreateTap,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onCreateTap;

  static const _tabs = [
    _TabItem(Icons.home_rounded, 'Akış'),
    _TabItem(Icons.map_rounded, 'Yakınım'),
    _TabItem(Icons.restaurant_rounded, 'Lezzet'),
    _TabItem(Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 8 + bottom),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            decoration: BoxDecoration(
              color: AppColors.nav,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              children: [
                Expanded(child: _navItem(ShellTabs.feed, index, onChanged)),
                Expanded(child: _navItem(ShellTabs.explore, index, onChanged)),
                const SizedBox(width: 58),
                Expanded(child: _navItem(ShellTabs.food, index, onChanged)),
                Expanded(child: _navItem(ShellTabs.profile, index, onChanged)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onCreateTap,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.lime, Color(0xFF9AD86A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.fab,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.ink, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int tabIndex, int activeIndex, ValueChanged<int> tap) {
    final item = _tabs[tabIndex];
    final on = tabIndex == activeIndex;
    return GestureDetector(
      onTap: () => tap(tabIndex),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 22, color: on ? AppColors.lime : Colors.white.withValues(alpha: 0.55)),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: on ? AppColors.lime : Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
