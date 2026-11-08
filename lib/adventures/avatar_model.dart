import 'package:flutter/material.dart';

/// Stable item IDs are shared with supabase/avatar_profiles.sql.
/// Keep the SQL validation lists in sync if you add options.
class AvatarCatalog {
  static const options = <String, List<String>>{
    'body_style': ['classic', 'petite'],
    'skin_tone': ['porcelain', 'fair', 'tan', 'olive', 'brown', 'deep'],
    'hair_style': ['short', 'bob', 'curly', 'long'],
    'hair_color': ['espresso', 'black', 'chestnut', 'blonde', 'copper'],
    'outfit': ['hoodie', 'sweater', 'summer', 'denim'],
    'accessory': ['none', 'glasses', 'cap', 'bow'],
  };

  static const labels = <String, String>{
    'body_style': 'Body style',
    'skin_tone': 'Skin tone',
    'hair_style': 'Hairstyle',
    'hair_color': 'Hair color',
    'outfit': 'Outfit',
    'accessory': 'Accessory',
    'classic': 'Classic',
    'petite': 'Petite',
    'porcelain': 'Porcelain',
    'fair': 'Fair',
    'tan': 'Tan',
    'olive': 'Olive',
    'brown': 'Brown',
    'deep': 'Deep',
    'short': 'Short',
    'bob': 'Bob',
    'curly': 'Curly',
    'long': 'Long',
    'espresso': 'Espresso',
    'black': 'Black',
    'chestnut': 'Chestnut',
    'blonde': 'Blonde',
    'copper': 'Copper',
    'hoodie': 'Hoodie',
    'sweater': 'Sweater',
    'summer': 'Summer',
    'denim': 'Denim',
    'none': 'None',
    'glasses': 'Glasses',
    'cap': 'Cap',
    'bow': 'Hair bow',
  };

  static const swatches = <String, Color>{
    'porcelain': Color(0xFFF4D5BC),
    'fair': Color(0xFFE5B895),
    'tan': Color(0xFFD5A17A),
    'olive': Color(0xFFBE906D),
    'brown': Color(0xFF925F42),
    'deep': Color(0xFF683E2C),
    'espresso': Color(0xFF34262E),
    'black': Color(0xFF201D27),
    'chestnut': Color(0xFF77483D),
    'blonde': Color(0xFFD4A65E),
    'copper': Color(0xFFAC583A),
  };

  static String label(String id) => labels[id] ?? id;
}

@immutable
class CoupleAvatar {
  const CoupleAvatar({
    this.bodyStyle = 'classic',
    this.skinTone = 'tan',
    this.hairStyle = 'short',
    this.hairColor = 'espresso',
    this.outfit = 'hoodie',
    this.accessory = 'none',
  });

  final String bodyStyle;
  final String skinTone;
  final String hairStyle;
  final String hairColor;
  final String outfit;
  final String accessory;

  static const partnerPlaceholder = CoupleAvatar(
    skinTone: 'fair',
    hairStyle: 'long',
    hairColor: 'chestnut',
    outfit: 'summer',
  );

  Map<String, String> toJson() => {
        'body_style': bodyStyle,
        'skin_tone': skinTone,
        'hair_style': hairStyle,
        'hair_color': hairColor,
        'outfit': outfit,
        'accessory': accessory,
      };

  factory CoupleAvatar.fromJson(Map<String, dynamic> json) {
    String valid(String key, String fallback) {
      final value = json[key];
      return value is String && AvatarCatalog.options[key]!.contains(value)
          ? value
          : fallback;
    }

    return CoupleAvatar(
      bodyStyle: valid('body_style', 'classic'),
      skinTone: valid('skin_tone', 'tan'),
      hairStyle: valid('hair_style', 'short'),
      hairColor: valid('hair_color', 'espresso'),
      outfit: valid('outfit', 'hoodie'),
      accessory: valid('accessory', 'none'),
    );
  }

  CoupleAvatar withOption(String key, String value) {
    if (!(AvatarCatalog.options[key]?.contains(value) ?? false)) {
      throw ArgumentError.value(value, key, 'Unknown avatar option');
    }
    return CoupleAvatar(
      bodyStyle: key == 'body_style' ? value : bodyStyle,
      skinTone: key == 'skin_tone' ? value : skinTone,
      hairStyle: key == 'hair_style' ? value : hairStyle,
      hairColor: key == 'hair_color' ? value : hairColor,
      outfit: key == 'outfit' ? value : outfit,
      accessory: key == 'accessory' ? value : accessory,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoupleAvatar &&
      bodyStyle == other.bodyStyle &&
      skinTone == other.skinTone &&
      hairStyle == other.hairStyle &&
      hairColor == other.hairColor &&
      outfit == other.outfit &&
      accessory == other.accessory;

  @override
  int get hashCode => Object.hash(
        bodyStyle,
        skinTone,
        hairStyle,
        hairColor,
        outfit,
        accessory,
      );
}
