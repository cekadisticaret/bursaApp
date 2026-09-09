import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/bursa_api.dart';
import '../api/models.dart';

class AuthStore extends ChangeNotifier {
  AuthStore();

  static const _tokenKey = 'bursaapp_token';
  final _storage = const FlutterSecureStorage();
  BursaApi? _api;
  AuthUser? user;
  String? token;
  bool loading = false;

  BursaApi get api {
    _api ??= BursaApi(token: token);
    _api!.token = token;
    return _api!;
  }

  bool get isLoggedIn => user != null && token != null && token!.isNotEmpty;

  Future<void> load() async {
    token = await _storage.read(key: _tokenKey);
    if (token != null && token!.isNotEmpty) {
      try {
        user = await api.me();
      } catch (_) {
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (!isLoggedIn) return;
    try {
      user = await api.me();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> login(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final u = await api.login(email.trim(), password);
      token = api.token;
      user = u;
      if (token != null && token!.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      final u = await api.register(name.trim(), email.trim(), password);
      token = api.token;
      user = u;
      if (token != null && token!.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
      }
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
    token = null;
    user = null;
    _api = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
