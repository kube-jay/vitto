/// A User profile (Part I §5). The same profile is buyer and seller.
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    required this.countryCode,
    this.regionCode,
    this.city,
    this.preferredLocale = 'en',
    this.joinedAt,
    this.suspendedAt,
    this.completedDealsCount = 0,
    this.ratingCount = 0,
    this.ratingSum = 0,
  });

  final String id;
  final String displayName;
  final String? avatarPath;
  final String countryCode;
  final String? regionCode;
  final String? city;
  final String preferredLocale;
  final DateTime? joinedAt;
  final DateTime? suspendedAt;
  final int completedDealsCount;
  final int ratingCount;
  final int ratingSum;

  /// Columns safe to request for any profile.
  static const columns =
      'id,display_name,avatar_path,country_code,region_code,city,'
      'preferred_locale,joined_at,suspended_at,completed_deals_count,'
      'rating_count,rating_sum';

  double get averageRating => ratingCount == 0 ? 0 : ratingSum / ratingCount;
  bool get isSuspended => suspendedAt != null;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'] as String,
    displayName: (j['display_name'] as String?) ?? '',
    avatarPath: j['avatar_path'] as String?,
    countryCode: (j['country_code'] as String?) ?? 'NG',
    regionCode: j['region_code'] as String?,
    city: j['city'] as String?,
    preferredLocale: (j['preferred_locale'] as String?) ?? 'en',
    joinedAt: _date(j['joined_at']),
    suspendedAt: _date(j['suspended_at']),
    completedDealsCount: (j['completed_deals_count'] as int?) ?? 0,
    ratingCount: (j['rating_count'] as int?) ?? 0,
    ratingSum: (j['rating_sum'] as int?) ?? 0,
  );
}

class Region {
  const Region(this.countryCode, this.code, this.name);

  final String countryCode;
  final String code;
  final String name;

  factory Region.fromJson(Map<String, dynamic> j) => Region(
    j['country_code'] as String,
    j['code'] as String,
    j['name'] as String,
  );
}

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
