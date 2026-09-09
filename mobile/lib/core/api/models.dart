int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.displayName,
    required this.avatarUrl,
    required this.points,
    this.email = '',
    this.showFullName = false,
    this.emailVerified = false,
  });

  final int id;
  final String name;
  final String displayName;
  final String avatarUrl;
  final int points;
  final String email;
  final bool showFullName;
  final bool emailVerified;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: _asInt(j['id']),
        name: j['name']?.toString() ?? 'Üye',
        displayName: j['display_name']?.toString() ?? j['name']?.toString() ?? 'Üye',
        avatarUrl: j['avatar_url']?.toString() ?? '',
        points: _asInt(j['loyalty_points']),
        email: j['email']?.toString() ?? '',
        showFullName: j['show_full_name'] == true,
        emailVerified: j['email_verified'] == true,
      );
}

class FeedUser {
  FeedUser({required this.name, required this.avatarUrl, required this.handle});
  final String name;
  final String avatarUrl;
  final String handle;

  factory FeedUser.fromJson(Map<String, dynamic>? j) => FeedUser(
        name: j?['name']?.toString() ?? 'Üye',
        avatarUrl: j?['avatar_url']?.toString() ?? '',
        handle: j?['handle']?.toString() ?? '@uye',
      );
}

class FeedItem {
  FeedItem({
    required this.kind,
    required this.id,
    required this.ago,
    required this.user,
    required this.body,
    required this.images,
    required this.likes,
    required this.liked,
    required this.comments,
    this.placeTitle,
    this.placeSlug,
  });

  final String kind;
  final int id;
  final String ago;
  final FeedUser user;
  final String body;
  final List<String> images;
  int likes;
  bool liked;
  final int comments;
  final String? placeTitle;
  final String? placeSlug;

  factory FeedItem.fromJson(Map<String, dynamic> j) {
    final place = j['place'] as Map<String, dynamic>?;
    return FeedItem(
      kind: j['kind']?.toString() ?? 'post',
      id: _asInt(j['id']),
      ago: j['ago']?.toString() ?? '',
      user: FeedUser.fromJson(j['user'] as Map<String, dynamic>?),
      body: j['body']?.toString() ?? '',
      images: (j['images'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList(),
      likes: _asInt(j['likes']),
      liked: j['liked'] == true,
      comments: _asInt(j['comments']),
      placeTitle: place?['title']?.toString(),
      placeSlug: place?['slug']?.toString(),
    );
  }
}

class EventItem {
  EventItem({
    required this.title,
    required this.slug,
    required this.whenLabel,
    required this.startsAtLabel,
    required this.imgUrl,
    required this.ilce,
    required this.going,
  });

  final String title;
  final String slug;
  final String whenLabel;
  final String startsAtLabel;
  final String imgUrl;
  final String ilce;
  final int going;

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
        title: j['title']?.toString() ?? 'Etkinlik',
        slug: j['slug']?.toString() ?? '',
        whenLabel: j['when_label']?.toString() ?? '',
        startsAtLabel: j['starts_at_label']?.toString() ?? '',
        imgUrl: j['img_url']?.toString() ?? '',
        ilce: j['ilce']?.toString() ?? '',
        going: _asInt(j['going']),
      );
}

class FeedResponse {
  FeedResponse({required this.feed, required this.events, required this.hasMore});
  final List<FeedItem> feed;
  final List<EventItem> events;
  final bool hasMore;

  factory FeedResponse.fromJson(Map<String, dynamic> j) => FeedResponse(
        feed: (j['feed'] as List? ?? [])
            .where((e) => e is Map && e['kind'] != 'buddy_promo')
            .map((e) => FeedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        events: (j['events'] as List? ?? [])
            .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: j['has_more'] == true,
      );
}

class PlaceItem {
  PlaceItem({
    required this.title,
    required this.slug,
    required this.category,
    required this.ilce,
    required this.blurb,
    required this.imgUrl,
    required this.lat,
    required this.lng,
    required this.subcategory,
  });

  final String title;
  final String slug;
  final String category;
  final String ilce;
  final String blurb;
  final String imgUrl;
  final double? lat;
  final double? lng;
  final String subcategory;

  factory PlaceItem.fromJson(Map<String, dynamic> j) => PlaceItem(
        title: j['title']?.toString() ?? '',
        slug: j['slug']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        ilce: j['ilce']?.toString() ?? '',
        blurb: j['blurb']?.toString() ?? '',
        imgUrl: j['img_url']?.toString() ?? '',
        lat: _asDouble(j['lat']),
        lng: _asDouble(j['lng']),
        subcategory: j['subcategory']?.toString() ?? j['subcategory_label']?.toString() ?? '',
      );
}

class MenuGroup {
  MenuGroup({required this.title, required this.icon, required this.items});
  final String title;
  final String icon;
  final List<MenuLink> items;

  factory MenuGroup.fromJson(Map<String, dynamic> j) => MenuGroup(
        title: j['title']?.toString() ?? '',
        icon: j['icon']?.toString() ?? '',
        items: (j['items'] as List? ?? [])
            .map((e) => MenuLink.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MenuLink {
  MenuLink({required this.label, required this.path, this.category});
  final String label;
  final String path;
  final String? category;

  factory MenuLink.fromJson(Map<String, dynamic> j) => MenuLink(
        label: j['label']?.toString() ?? '',
        path: j['path']?.toString() ?? '',
        category: j['category']?.toString(),
      );
}

class LeaderRow {
  LeaderRow({required this.rank, required this.name, required this.avatarUrl, required this.points});
  final int rank;
  final String name;
  final String avatarUrl;
  final int points;

  factory LeaderRow.fromJson(Map<String, dynamic> j) {
    final u = j['user'] as Map<String, dynamic>? ?? {};
    return LeaderRow(
      rank: _asInt(j['rank']),
      name: u['name']?.toString() ?? 'Üye',
      avatarUrl: u['avatar_url']?.toString() ?? '',
      points: _asInt(u['points']),
    );
  }
}

class ActivityType {
  ActivityType({required this.key, required this.label, required this.emoji, required this.defaultTitle});
  final String key;
  final String label;
  final String emoji;
  final String defaultTitle;

  factory ActivityType.fromJson(Map<String, dynamic> j) => ActivityType(
        key: j['key']?.toString() ?? 'other',
        label: j['label']?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '✨',
        defaultTitle: j['default_title']?.toString() ?? '',
      );
}

class ActivitySeek {
  ActivitySeek({
    required this.id,
    required this.activityType,
    required this.activityLabel,
    required this.emoji,
    required this.title,
    required this.host,
    required this.ilce,
    required this.venue,
    required this.timeLabel,
    required this.note,
    required this.pointsMin,
    required this.slotsNeeded,
    required this.spotsLeft,
    required this.joined,
    required this.pending,
    required this.isMine,
    this.contactHint = '',
    this.hostPoints = 0,
  });

  final int id;
  final String activityType;
  final String activityLabel;
  final String emoji;
  final String title;
  final String host;
  final String ilce;
  final String venue;
  final String timeLabel;
  final String note;
  final int pointsMin;
  final int slotsNeeded;
  final int spotsLeft;
  final bool joined;
  final bool pending;
  final bool isMine;
  final String contactHint;
  final int hostPoints;

  factory ActivitySeek.fromJson(Map<String, dynamic> j) => ActivitySeek(
        id: _asInt(j['id']),
        activityType: j['activity_type']?.toString() ?? j['type']?.toString() ?? 'other',
        activityLabel: j['activity_label']?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '✨',
        title: j['title']?.toString() ?? j['host']?.toString() ?? '',
        host: j['host']?.toString() ?? '',
        ilce: j['ilce']?.toString() ?? '',
        venue: j['venue']?.toString() ?? '',
        timeLabel: j['time_label']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        pointsMin: _asInt(j['points_min']),
        slotsNeeded: _asInt(j['slots_needed'], 1),
        spotsLeft: _asInt(j['spots_left'], 1),
        joined: j['joined'] == true,
        pending: j['pending'] == true,
        isMine: j['is_mine'] == true,
        contactHint: j['contact_hint']?.toString() ?? '',
        hostPoints: _asInt(j['host_points']),
      );
}

@Deprecated('Use ActivitySeek')
typedef OkeySeek = ActivitySeek;
