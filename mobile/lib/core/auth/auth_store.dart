import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/bursa_api.dart';
import '../api/models.dart';

class AuthStore extends ChangeNotifier {
  AuthStore();

  static const _tokenKey = 'bursaapp_token';
  static const _emailKey = 'bursaapp_email';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  BursaApi? _api;
  AuthUser? user;
  String? token;
  String? savedEmail;
  bool loading = false;

  BursaApi get api {
    _api ??= BursaApi(token: token);
    return _api!;
  }

  bool get isLoggedIn => user != null && token != null && token!.isNotEmpty;

  void _bindApi() {
    _api = BursaApi(token: token);
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      token = await _storage.read(key: _tokenKey);
      savedEmail = await _storage.read(key: _emailKey);
      if (token != null && token!.isNotEmpty) {
        _bindApi();
        try {
          user = await api.me();
        } on ApiException catch (e) {
          if (e.statusCode == 401 || e.statusCode == 403) {
            await _clearSession();
          }
        } catch (_) {
          // Ağ hatası — token saklı kalsın, bir sonraki yenilemede dene.
        }
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (token == null || token!.isEmpty) return;
    _bindApi();
    try {
      user = await api.me();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _clearSession();
      }
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final trimmed = email.trim();
      _bindApi();
      final client = _api!;
      final u = await client.login(trimmed, password);
      token = client.token;
      if (token == null || token!.isEmpty) {
        throw ApiException('Oturum oluşturulamadı', 500);
      }
      user = u;
      savedEmail = trimmed;
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _emailKey, value: trimmed);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final trimmed = email.trim();
      _bindApi();
      final client = _api!;
      final u = await client.register(name.trim(), trimmed, password);
      token = client.token;
      if (token == null || token!.isEmpty) {
        throw ApiException('Hesap oluşturuldu ama oturum açılamadı', 500);
      }
      user = u;
      savedEmail = trimmed;
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _emailKey, value: trimmed);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<AuthUser> updateProfile({String? name, bool? showFullName}) async {
    final u = await api.updateMe(
      action: 'profile',
      name: name,
      showFullName: showFullName,
    );
    user = u;
    notifyListeners();
    return u;
  }

  Future<void> updatePassword({
    required String current,
    required String newPassword,
    required String newPassword2,
  }) async {
    user = await api.updateMe(
      action: 'password',
      currentPassword: current,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
    notifyListeners();
  }

  Future<AuthUser> uploadAvatar(List<int> bytes, String filename) async {
    final u = await api.uploadAvatar(bytes, filename);
    user = u;
    notifyListeners();
    return u;
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    token = null;
    user = null;
    _api = null;
    await _storage.delete(key: _tokenKey);
  }
}
