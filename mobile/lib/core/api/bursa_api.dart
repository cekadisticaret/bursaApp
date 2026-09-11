import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'models.dart';

class BursaApi {
  BursaApi({this.token});

  String? token;
  final _client = http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw ApiException('Geçersiz yanıt', res.statusCode);
    }
    if (res.statusCode >= 400 || body['ok'] == false) {
      throw ApiException(body['error']?.toString() ?? 'Hata', res.statusCode);
    }
    return body;
  }

  Future<FeedResponse> feed({String tab = 'recents', int offset = 0}) async {
    final uri = Uri.parse('${AppConfig.apiBase}/feed').replace(
      queryParameters: {'tab': tab, 'offset': '$offset', 'limit': '12'},
    );
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return FeedResponse.fromJson(data);
  }

  Future<List<EventItem>> upcomingEvents() async {
    final uri = Uri.parse('${AppConfig.apiBase}/events/upcoming');
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['events'] as List? ?? [])
        .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlaceItem>> places({
    String? category,
    String? sub,
    String? spec,
    String? q,
    int limit = 24,
    int offset = 0,
  }) async {
    final qp = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (category != null) 'category': category,
      if (sub != null) 'sub': sub,
      if (spec != null && spec.isNotEmpty) 'spec': spec,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final uri = Uri.parse('${AppConfig.apiBase}/places').replace(queryParameters: qp);
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['places'] as List? ?? [])
        .map((e) => PlaceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PlaceItem>> nearby({required double lat, required double lng, double r = 1200}) async {
    final uri = Uri.parse('${AppConfig.apiBase}/discover/nearby').replace(
      queryParameters: {'lat': '$lat', 'lng': '$lng', 'r': '${r.toInt()}'},
    );
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['places'] as List? ?? [])
        .map((e) => PlaceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> suggestPlace(String prompt) async {
    final uri = Uri.parse('${AppConfig.apiBase}/ai');
    final res = await _client.post(uri, headers: _headers, body: jsonEncode({'prompt': prompt}));
    return await _decode(res);
  }

  /// Yürüyüş/araç rotası — web /api/route (OSRM) ile aynı.
  Future<MapRouteResult> mapRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'foot',
  }) async {
    final uri = Uri.parse('${AppConfig.siteBase}/api/route').replace(
      queryParameters: {
        'from_lat': '$fromLat',
        'from_lng': '$fromLng',
        'to_lat': '$toLat',
        'to_lng': '$toLng',
        'profile': profile,
      },
    );
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw ApiException('Geçersiz rota yanıtı', res.statusCode);
    }
    if (res.statusCode >= 400 || body['ok'] != true) {
      throw ApiException(body['error']?.toString() ?? 'Rota bulunamadı', res.statusCode);
    }
    final raw = body['coordinates'] as List? ?? [];
    final points = <List<double>>[];
    for (final item in raw) {
      if (item is! List || item.length < 2) continue;
      final lat = (item[0] as num).toDouble();
      final lng = (item[1] as num).toDouble();
      points.add([lat, lng]);
    }
    if (points.length < 2) {
      throw ApiException('Rota koordinatı yok', 404);
    }
    return MapRouteResult(
      points: points,
      distanceM: (body['distance_m'] as num?)?.toDouble(),
      durationS: (body['duration_s'] as num?)?.toDouble(),
    );
  }

  Future<AuthUser> login(String email, String password) async {
    final uri = Uri.parse('${AppConfig.apiBase}/auth/login');
    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = await _decode(res);
    token = data['token']?.toString();
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<String> forgotPassword(String email) async {
    final uri = Uri.parse('${AppConfig.apiBase}/auth/forgot-password');
    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email.trim()}),
    );
    final data = await _decode(res);
    return data['message']?.toString() ?? 'E-posta gönderildi.';
  }

  Future<AuthUser> register(String name, String email, String password) async {
    final uri = Uri.parse('${AppConfig.apiBase}/auth/register');
    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = await _decode(res);
    token = data['token']?.toString();
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> me() async {
    final uri = Uri.parse('${AppConfig.apiBase}/me');
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateMe({
    required String action,
    String? name,
    bool? showFullName,
    String? currentPassword,
    String? newPassword,
    String? newPassword2,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBase}/me');
    final body = <String, dynamic>{'action': action};
    if (name != null) body['name'] = name;
    if (showFullName != null) body['show_full_name'] = showFullName;
    if (currentPassword != null) body['current_password'] = currentPassword;
    if (newPassword != null) body['new_password'] = newPassword;
    if (newPassword2 != null) body['new_password2'] = newPassword2;
    final res = await _client.patch(uri, headers: _headers, body: jsonEncode(body));
    final data = await _decode(res);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> uploadAvatar(List<int> bytes, String filename) async {
    final uri = Uri.parse('${AppConfig.apiBase}/me/avatar');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Accept'] = 'application/json';
    if (token != null && token!.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: filename));
    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    final data = await _decode(res);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<LikeResult> toggleLike(int postId) async {
    final uri = Uri.parse('${AppConfig.apiBase}/posts/$postId/like');
    final res = await _client.post(uri, headers: _headers);
    final data = await _decode(res);
    return LikeResult(liked: data['liked'] == true, likes: _parseInt(data['likes']));
  }

  Future<void> createEvent(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConfig.apiBase}/places');
    final res = await _client.post(uri, headers: _headers, body: jsonEncode(payload));
    await _decode(res);
  }

  Future<List<MenuGroup>> mobileMenu() async {
    final uri = Uri.parse('${AppConfig.apiBase}/mobile/menu');
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['groups'] as List? ?? [])
        .map((e) => MenuGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderRow>> weeklyLeaders() async {
    final uri = Uri.parse('${AppConfig.apiBase}/leaders/weekly');
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['leaders'] as List? ?? [])
        .map((e) => LeaderRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityType>> activityTypes() async {
    final uri = Uri.parse('${AppConfig.apiBase}/activities/types');
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['types'] as List? ?? [])
        .map((e) => ActivityType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivitySeek>> activitySeeking({String? type}) async {
    final qp = <String, String>{};
    if (type != null && type.isNotEmpty) qp['type'] = type;
    final uri = Uri.parse('${AppConfig.apiBase}/activities/seeking').replace(queryParameters: qp.isEmpty ? null : qp);
    final res = await _client.get(uri, headers: _headers);
    final data = await _decode(res);
    return (data['seeking'] as List? ?? [])
        .map((e) => ActivitySeek.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createActivitySeek(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConfig.apiBase}/activities/seeking');
    final res = await _client.post(uri, headers: _headers, body: jsonEncode(payload));
    await _decode(res);
  }

  Future<void> joinActivitySeek(int id) async {
    final uri = Uri.parse('${AppConfig.apiBase}/activities/seeking/$id/join');
    final res = await _client.post(uri, headers: _headers);
    await _decode(res);
  }

  Future<void> leaveActivitySeek(int id) async {
    final uri = Uri.parse('${AppConfig.apiBase}/activities/seeking/$id/join');
    final res = await _client.delete(uri, headers: _headers);
    await _decode(res);
  }

  Future<Map<String, dynamic>> nobetciEczaneler() async {
    final uri = Uri.parse('${AppConfig.apiBase}/mobile/nobetci-eczaneler');
    final res = await _client.get(uri, headers: _headers);
    return await _decode(res);
  }

  Future<Map<String, dynamic>> bursaNews() async {
    final uri = Uri.parse('${AppConfig.apiBase}/mobile/news');
    final res = await _client.get(uri, headers: _headers);
    return await _decode(res);
  }

  Future<Map<String, dynamic>> bursasporFeed() async {
    final uri = Uri.parse('${AppConfig.apiBase}/mobile/bursaspor');
    final res = await _client.get(uri, headers: _headers);
    return await _decode(res);
  }

  Future<Map<String, dynamic>> teleferikInfo() async {
    final uri = Uri.parse('${AppConfig.apiBase}/mobile/teleferik');
    final res = await _client.get(uri, headers: _headers);
    return await _decode(res);
  }

  Future<Map<String, dynamic>> utilitiesInfo() async {
    final uri = Uri.parse('${AppConfig.apiBase}/mobile/utilities');
    final res = await _client.get(uri, headers: _headers);
    return await _decode(res);
  }

  Future<Map<String, dynamic>> weekend() async {
    final uri = Uri.parse('${AppConfig.apiBase}/discover/weekend');
    final res = await _client.get(uri, headers: _headers);
    return await _decode(res);
  }

  Future<List<ActivitySeek>> okeySeeking() => activitySeeking(type: 'okey');

  void dispose() => _client.close();
}

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}

class MapRouteResult {
  MapRouteResult({required this.points, this.distanceM, this.durationS});

  final List<List<double>> points;
  final double? distanceM;
  final double? durationS;
}

class LikeResult {
  LikeResult({required this.liked, required this.likes});
  final bool liked;
  final int likes;
}
