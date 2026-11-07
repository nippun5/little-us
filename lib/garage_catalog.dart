import 'package:flutter/material.dart';

/// Keep this catalog in sync with the allow-list and prices in garage.sql.
class GarageItem {
  const GarageItem(this.id, this.group, this.label, this.price, this.detail);

  final String id;
  final String group;
  final String label;
  final int price;
  final String detail;
}

const garageGroupLabels = <String, String>{
  'paint': 'Body paint',
  'windows': 'Side windows',
  'windshield': 'Windshield',
  'headlights': 'Headlights',
  'grille': 'Front grille',
  'bumper': 'Front bumper',
  'fenders': 'Fenders',
  'wheels': 'Wheels',
  'mirrors': 'Mirrors',
  'roof': 'Roof',
};

const garageDefaultEquipped = <String, String>{
  'paint': 'paint_silver',
  'windows': 'windows_clear',
  'windshield': 'windshield_clear',
  'headlights': 'headlights_warm',
  'grille': 'grille_classic',
  'bumper': 'bumper_standard',
  'fenders': 'fenders_standard',
  'wheels': 'wheels_classic',
  'mirrors': 'mirrors_chrome',
  'roof': 'roof_standard',
};

const garageDefaultOwned = <String>[
  'paint_silver',
  'windows_clear',
  'windshield_clear',
  'headlights_warm',
  'grille_classic',
  'bumper_standard',
  'fenders_standard',
  'wheels_classic',
  'mirrors_chrome',
  'roof_standard',
];

const garageItems = <GarageItem>[
  GarageItem(
      'paint_silver', 'paint', 'Silver', 0, 'The included metallic finish.'),
  GarageItem('paint_navy', 'paint', 'Midnight navy', 35, 'Deep, elegant blue.'),
  GarageItem('paint_white', 'paint', 'Pearl white', 30, 'Bright and timeless.'),
  GarageItem('paint_black', 'paint', 'Obsidian black', 30, 'Classic luxury.'),
  GarageItem('paint_graphite', 'paint', 'Graphite gray', 40,
      'Modern and understated.'),
  GarageItem('paint_rose', 'paint', 'Rose pink', 20, 'A soft little-us touch.'),
  GarageItem('paint_mint', 'paint', 'Sage mint', 20, 'Calm and playful.'),
  GarageItem('windows_clear', 'windows', 'Clear glass', 0,
      'Included transparent side windows.'),
  GarageItem('windows_tinted', 'windows', 'Smoked tint', 35,
      'Dark privacy-tinted side windows.'),
  GarageItem('windshield_clear', 'windshield', 'Clear windshield', 0,
      'Included front windshield.'),
  GarageItem('windshield_sunstrip', 'windshield', 'Sunshade strip', 25,
      'A shaded upper windshield band.'),
  GarageItem('headlights_warm', 'headlights', 'Warm headlights', 0,
      'Included soft yellow lamps.'),
  GarageItem('headlights_led', 'headlights', 'LED headlights', 45,
      'Cool white LED light signature.'),
  GarageItem('grille_classic', 'grille', 'Chrome grille', 0,
      'Included horizontal chrome bars.'),
  GarageItem('grille_diamond', 'grille', 'Diamond grille', 55,
      'A premium pin-pattern grille.'),
  GarageItem('bumper_standard', 'bumper', 'Classic bumper', 0,
      'Included front fascia.'),
  GarageItem('bumper_sport', 'bumper', 'Sport bumper', 50,
      'Sculpted front lip and vents.'),
  GarageItem('fenders_standard', 'fenders', 'Classic fenders', 0,
      'Smooth, elegant wheel arches.'),
  GarageItem('fenders_flared', 'fenders', 'Flared fenders', 45,
      'Wider, sporty arch trim.'),
  GarageItem('wheels_classic', 'wheels', 'Classic alloys', 0,
      'Included silver alloys.'),
  GarageItem('wheels_sport', 'wheels', 'Sport alloys', 50,
      'Dark wheels with slim spokes.'),
  GarageItem('mirrors_chrome', 'mirrors', 'Chrome mirrors', 0,
      'Included matching mirrors.'),
  GarageItem('mirrors_black', 'mirrors', 'Black mirrors', 20,
      'Glossy black mirror caps.'),
  GarageItem(
      'roof_standard', 'roof', 'Painted roof', 0, 'Included painted roof.'),
  GarageItem('roof_panorama', 'roof', 'Panoramic roof', 60,
      'A sleek dark-glass roof.'),
];

GarageItem? garageItemById(String id) {
  for (final item in garageItems) {
    if (item.id == id) return item;
  }
  return null;
}

Map<String, dynamic> freshGarageState() => <String, dynamic>{
      'owned': List<String>.from(garageDefaultOwned),
      'equipped': Map<String, String>.from(garageDefaultEquipped),
    };

Color garagePaintColor(String id) => switch (id) {
      'paint_navy' => const Color(0xFF183A65),
      'paint_white' => const Color(0xFFF5F3ED),
      'paint_black' => const Color(0xFF24252B),
      'paint_graphite' => const Color(0xFF606A75),
      'paint_rose' => const Color(0xFFE3A1B8),
      'paint_mint' => const Color(0xFF8DBDA9),
      _ => const Color(0xFFBCC4CE),
    };
