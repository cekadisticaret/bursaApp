import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../navigation/app_menu.dart';
import '../navigation/app_routes.dart';
import '../widgets/app_refresh.dart';
import '../widgets/login_sheet.dart';
import 'create_event_screen.dart';
import 'leaders_screen.dart';
import 'activity_buddy_screen.dart';
import 'profile_settings_screen.dart';
import 'visit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<MenuGroup> _menu = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthStore>().addListener(_onAuthChanged);
    _loadMenu();
  }

  @override
  void dispose() {
    context.read<AuthStore>().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await context.read<AuthStore>().refreshUser();
    await _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final auth = context.read<AuthStore>();
      final groups = await auth.api.mobileMenu();
      if (mounted) setState(() => _menu = groups);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLogin() async {
    final ok = await openAuthFlow(context, onSuccess: _refresh);
    if (ok && mounted) await _refresh();
  }

  void _openSettings() {
    Navigator.of(context).push(appRoute(const ProfileSettingsScreen()));
  }

  Future<void> _logout() async {
    await context.read<AuthStore>().logout();
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;
    final loggedIn = auth.isLoggedIn;

    return appRefreshList(
      onRefresh: _refresh,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: loggedIn ? _openSettings : _openLogin,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.accentDeep,
                backgroundImage: loggedIn && user?.avatarUrl != null && user!.avatarUrl.isNotEmpty
                    ? NetworkImage(user.avatarUrl.startsWith('http') ? user.avatarUrl : '${AppConfig.siteBase}${user.avatarUrl}')
                    : null,
                child: !loggedIn || user?.avatarUrl.isEmpty != false
                    ? Text(
                        loggedIn ? (user?.name ?? 'B').substring(0, 1) : '👋',
                        style: TextStyle(
                          fontSize: loggedIn ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loggedIn ? (user?.name ?? 'Üye') : 'Giriş',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              loggedIn ? '${user?.points ?? 0} puan · Bursa rehberi' : 'Hesabınla devam et',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (loggedIn) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(onPressed: _openSettings, child: const Text('Profili düzenle')),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    side: const BorderSide(color: AppColors.coral),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Çıkış yap'),
                ),
              ),
            ] else
              FilledButton(
                onPressed: auth.loading ? null : _openLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.nav,
                  foregroundColor: AppColors.lime,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(auth.loading ? 'Yükleniyor…' : 'Giriş'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _QuickTile(icon: Icons.landscape_rounded, label: 'Gez', color: AppColors.accentDeep, onTap: () => Navigator.push(context, appRoute(const VisitScreen())))),
            const SizedBox(width: 10),
            Expanded(child: _QuickTile(icon: Icons.add_circle, label: 'Etkinlik', color: AppColors.pink, onTap: () => requireAuth(context, () => Navigator.push(context, appRoute(const CreateEventScreen()))))),
            const SizedBox(width: 10),
            Expanded(child: _QuickTile(icon: Icons.emoji_events, label: 'Liderler', color: AppColors.sky, onTap: () => Navigator.push(context, appRoute(const LeadersScreen())))),
            const SizedBox(width: 10),
            Expanded(child: _QuickTile(icon: Icons.groups_rounded, label: 'Partner', color: AppColors.amber, onTap: () => Navigator.push(context, appRoute(const ActivityBuddyScreen())))),
          ],
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          ..._menu.map((g) => _MenuBlock(group: g)),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MenuBlock extends StatelessWidget {
  const _MenuBlock({required this.group});
  final MenuGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(group.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          ...group.items.map(
            (item) => ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.bgSoft, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ),
              onTap: () => openMenuLink(context, item),
            ),
          ),
        ],
      ),
    );
  }
}
