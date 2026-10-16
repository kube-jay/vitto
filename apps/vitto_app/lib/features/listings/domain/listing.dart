import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../profile/domain/profile.dart';
import 'listing_status.dart';

/// The core marketplace item (Part I §6). Always called "Listing".
class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.priceMinor,
    required this.currency,
    required this.negotiable,
    required this.condition,
    required this.countryCode,
    this.regionCode,
    required this.city,
    required this.status,
    required this.createdAt,
    this.publishedAt,
    this.imagePaths = const [],
    this.seller,
    this.category,
  });

  final String id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final int priceMinor;
  final String currency;
  final bool negotiable;
  final String condition; // 'new' | 'used'
  final String countryCode;
  final String? regionCode;
  final String city;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final List<String> imagePaths;
  final Profile? seller;
  final Category? category;

  Money get price => Money(priceMinor, currency);
  String? get coverPath => imagePaths.isEmpty ? null : imagePaths.first;

  static const columns =
      'id,seller_id,category_id,title,description,price_minor,currency,'
      'negotiable,condition,country_code,region_code,city,status,created_at,'
      'published_at,listing_images(storage_path,sort_order)';

  static const detailColumns =
      '$columns,'
      'seller:profiles!listings_seller_id_fkey(${Profile.columns}),'
      'category:categories(${Category.columns})';

  factory Listing.fromJson(Map<String, dynamic> j) {
    final images =
        ((j['listing_images'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) =>
                (a['sort_order'] as int).compareTo(b['sort_order'] as int),
          );
    return Listing(
      id: j['id'] as String,
      sellerId: j['seller_id'] as String,
      categoryId: j['category_id'] as String,
      title: j['title'] as String,
      description: (j['description'] as String?) ?? '',
      priceMinor: (j['price_minor'] as num).toInt(),
      currency: j['currency'] as String,
      negotiable: j['negotiable'] as bool,
      condition: j['condition'] as String,
      countryCode: j['country_code'] as String,
      regionCode: j['region_code'] as String?,
      city: j['city'] as String,
      status: ListingStatus.fromWire(j['status'] as String),
      createdAt: DateTime.parse(j['created_at'] as String),
      publishedAt: j['published_at'] == null
          ? null
          : DateTime.parse(j['published_at'] as String),
      imagePaths: [for (final i in images) i['storage_path'] as String],
      seller: j['seller'] is Map<String, dynamic>
          ? Profile.fromJson(j['seller'] as Map<String, dynamic>)
          : null,
      category: j['category'] is Map<String, dynamic>
          ? Category.fromJson(j['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameFr,
    this.parentId,
    this.active = true,
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String nameEn;
  final String nameFr;
  final String? parentId;
  final bool active;
  final int sortOrder;

  static const columns = 'id,slug,name_en,name_fr,parent_id,active,sort_order';

  String name(Locale locale) => locale.languageCode == 'fr' ? nameFr : nameEn;

  IconData get icon => _icons[slug] ?? Icons.category_outlined;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    slug: j['slug'] as String,
    nameEn: j['name_en'] as String,
    nameFr: j['name_fr'] as String,
    parentId: j['parent_id'] as String?,
    active: (j['active'] as bool?) ?? true,
    sortOrder: (j['sort_order'] as int?) ?? 0,
  );

  static const _icons = <String, IconData>{
    'phones-tablets': Icons.smartphone,
    'electronics': Icons.tv,
    'computers': Icons.laptop_mac,
    'fashion': Icons.checkroom,
    'home-furniture': Icons.chair_outlined,
    'appliances': Icons.kitchen_outlined,
    'vehicles-parts': Icons.directions_car_outlined,
    'beauty-health': Icons.spa_outlined,
    'baby-kids': Icons.child_friendly_outlined,
    'sports-outdoors': Icons.sports_soccer,
    'books-media': Icons.menu_book_outlined,
    'other': Icons.more_horiz,
  };
}
