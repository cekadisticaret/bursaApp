import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api/models.dart';
import '../core/auth/auth_store.dart';
import '../core/config.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_page.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _name = TextEditingController();
  final _curPass = TextEditingController();
  final _newPass = TextEditingController();
  final _newPass2 = TextEditingController();
  bool _showFullName = false;
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  String? _ok;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthStore>().user;
    _name.text = u?.name ?? '';
    _showFullName = u?.showFullName ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _curPass.dispose();
    _newPass.dispose();
    _newPass2.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() {
      _error = null;
      _ok = null;
    });
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      await context.read<AuthStore>().uploadAvatar(bytes, picked.name);
      if (mounted) setState(() => _ok = 'Profil fotoğrafı güncellendi.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
      _ok = null;
    });
    try {
      await context.read<AuthStore>().updateProfile(
            name: _name.text.trim(),
            showFullName: _showFullName,
          );
      if (mounted) setState(() => _ok = 'Profil kaydedildi.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _saving = true;
      _error = null;
      _ok = null;
    });
    try {
      await context.read<AuthStore>().updatePassword(
            current: _curPass.text,
            newPassword: _newPass.text,
            newPassword2: _newPass2.text,
          );
      _curPass.clear();
      _newPass.clear();
      _newPass2.clear();
      if (mounted) setState(() => _ok = 'Şifre güncellendi.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refresh() async {
    await context.read<AuthStore>().refreshUser();
    final u = context.read<AuthStore>().user;
    if (u != null && mounted) {
      setState(() {
        _name.text = u.name;
        _showFullName = u.showFullName;
      });
    }
  }

  String _avatarUrl(AuthUser? u) {
    if (u == null || u.avatarUrl.isEmpty) return '';
    return u.avatarUrl.startsWith('http') ? u.avatarUrl : '${AppConfig.siteBase}${u.avatarUrl}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.user;
    final avatar = _avatarUrl(user);

    return AppPage(
      title: 'Profil ayarları',
      onRefresh: _refresh,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ),
          if (_ok != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_ok!, style: const TextStyle(color: AppColors.accentDeep, fontWeight: FontWeight.w700)),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.accentDeep,
                      backgroundImage: avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                      child: avatar.isEmpty
                          ? Text(
                              (user?.name ?? 'B').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                            )
                          : null,
                    ),
                    if (_uploading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x88000000),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 6),
                      if (user?.emailVerified == true)
                        const Text('✓ E-posta onaylı', style: TextStyle(color: AppColors.accentDeep, fontSize: 12, fontWeight: FontWeight.w700))
                      else
                        const Text('E-posta onayı bekliyor', style: TextStyle(color: AppColors.coral, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Profil fotoğrafı',
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAvatar,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(avatar.isEmpty ? 'Fotoğraf seç' : 'Fotoğrafı değiştir'),
            ),
          ),
          _Section(
            title: 'Ad & görünüm',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Yorumlarda tam adım görünsün'),
                  subtitle: const Text('Kapalıysa C.. K.. gibi kısaltılır'),
                  value: _showFullName,
                  onChanged: (v) => setState(() => _showFullName = v),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.nav, foregroundColor: AppColors.lime),
                  child: Text(_saving ? 'Kaydediliyor…' : 'Profili kaydet'),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Şifre',
            child: Column(
              children: [
                TextField(controller: _curPass, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut şifre')),
                TextField(controller: _newPass, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre (min 8)')),
                TextField(controller: _newPass2, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni şifre tekrar')),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving ? null : _savePassword,
                  child: const Text('Şifreyi güncelle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}