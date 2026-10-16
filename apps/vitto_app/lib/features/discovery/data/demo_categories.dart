import 'package:flutter/material.dart';

/// Offline stand-in for the `categories` table (mirrors supabase/seed.sql)
/// so the home screen has content in demo mode. Replaced by the real
/// CategoryRepository in VT-012.
class DemoCategory {
  const DemoCategory(this.slug, this.nameEn, this.nameFr, this.icon);

  final String slug;
  final String nameEn;
  final String nameFr;
  final IconData icon;

  String name(Locale locale) => locale.languageCode == 'fr' ? nameFr : nameEn;
}

const demoCategories = <DemoCategory>[
  DemoCategory(
    'phones-tablets',
    'Phones & Tablets',
    'Téléphones et tablettes',
    Icons.smartphone,
  ),
  DemoCategory('electronics', 'Electronics', 'Électronique', Icons.tv),
  DemoCategory('computers', 'Computers', 'Ordinateurs', Icons.laptop_mac),
  DemoCategory('fashion', 'Fashion', 'Mode', Icons.checkroom),
  DemoCategory(
    'home-furniture',
    'Home & Furniture',
    'Maison et meubles',
    Icons.chair_outlined,
  ),
  DemoCategory(
    'appliances',
    'Appliances',
    'Électroménager',
    Icons.kitchen_outlined,
  ),
  DemoCategory(
    'vehicles-parts',
    'Vehicle Parts',
    'Pièces automobiles',
    Icons.directions_car_outlined,
  ),
  DemoCategory(
    'beauty-health',
    'Beauty & Personal Care',
    'Beauté et soins',
    Icons.spa_outlined,
  ),
  DemoCategory(
    'baby-kids',
    'Baby & Kids',
    'Bébé et enfants',
    Icons.child_friendly_outlined,
  ),
  DemoCategory(
    'sports-outdoors',
    'Sports & Outdoors',
    'Sports et plein air',
    Icons.sports_soccer,
  ),
  DemoCategory(
    'books-media',
    'Books & Media',
    'Livres et médias',
    Icons.menu_book_outlined,
  ),
  DemoCategory('other', 'Other', 'Autres', Icons.more_horiz),
];
