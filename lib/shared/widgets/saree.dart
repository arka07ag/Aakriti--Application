// ============================================================================
// saree.dart
// Data models matching the real backend schema (Django models you shared):
//   Saree --(has many)--> SareeVariant --(has many)--> VariantImage
// A saree is a design (name, fabric, occasions, description). Each colour
// it comes in is a separate SareeVariant with its OWN price, stock
// (quantity), blouse option, and its OWN set of photos.
//
// fromJson/toJson are written now so this matches the API shape when you
// wire it up later — no changes needed on that day, just point
// SareeApiService at real endpoints.
// ============================================================================

import 'dart:typed_data';

enum BlouseOption {
  withBlouse,
  withoutBlouse;

  String get apiValue => switch (this) {
    BlouseOption.withBlouse => 'WITH_BLOUSE_CLOTH',
    BlouseOption.withoutBlouse => 'WITHOUT_BLOUSE_CLOTH',
  };

  String get label => switch (this) {
    BlouseOption.withBlouse => 'With Blouse Pieces',
    BlouseOption.withoutBlouse => 'Without Blouse Pieces',
  };

  static BlouseOption fromApiValue(String? value) {
    return value == 'WITHOUT_BLOUSE_CLOTH'
        ? BlouseOption.withoutBlouse
        : BlouseOption.withBlouse;
  }
}

// A single photo belonging to a variant. `source` can be a network URL
// (from the backend) or a local device file path (freshly picked, not
// uploaded yet) — AppImage already knows how to display either.
//
// `bytes` holds the raw picked bytes for a freshly-chosen local photo.
// It's what actually gets rendered for local photos (via Image.memory),
// because a device file *path* can't be read back on Flutter Web — only
// the bytes captured at pick-time can. It's transient/in-memory only:
// not serialized in toJson, since once you upload it to the backend you'll
// have a real network URL instead.
class VariantImage {
  final String? id; // null until the backend has saved it
  final String source;
  final bool isPrimary;
  final Uint8List? bytes;

  const VariantImage({
    this.id,
    required this.source,
    this.isPrimary = false,
    this.bytes,
  });

  VariantImage copyWith({
    String? id,
    String? source,
    bool? isPrimary,
    Uint8List? bytes,
  }) {
    return VariantImage(
      id: id ?? this.id,
      source: source ?? this.source,
      isPrimary: isPrimary ?? this.isPrimary,
      bytes: bytes ?? this.bytes,
    );
  }

  factory VariantImage.fromJson(Map<String, dynamic> json) {
    return VariantImage(
      id: json['id']?.toString(),
      source: json['image'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'image': source,
    'is_primary': isPrimary,
  };
}

// One purchasable colour option of a saree: its own price, stock, blouse
// option, and photo set.
class SareeVariant {
  final String
  id; // stable id — real backend id once saved, local temp id until then
  final String colorName; // e.g. "Maroon"
  final String colorCode; // e.g. "#800000" — optional, used for the swatch
  final double price;
  final int quantity; // stock for THIS colour
  final BlouseOption blouseOption;
  final List<VariantImage> images;

  const SareeVariant({
    required this.id,
    required this.colorName,
    this.colorCode = '',
    required this.price,
    required this.quantity,
    this.blouseOption = BlouseOption.withBlouse,
    this.images = const [],
  });

  // The photo shown as this variant's thumbnail: the one flagged primary,
  // or just the first photo, or null if none yet.
  VariantImage? get primaryImage {
    if (images.isEmpty) return null;
    final primary = images.where((img) => img.isPrimary).toList();
    return primary.isNotEmpty ? primary.first : images.first;
  }

  // Kept for any code that only needs the display string (e.g. sending to
  // the API). For actually rendering a freshly-picked local photo, prefer
  // `primaryImage` so the widget also gets `bytes`.
  String get primaryImageSource => primaryImage?.source ?? '';

  SareeVariant copyWith({
    String? id,
    String? colorName,
    String? colorCode,
    double? price,
    int? quantity,
    BlouseOption? blouseOption,
    List<VariantImage>? images,
  }) {
    return SareeVariant(
      id: id ?? this.id,
      colorName: colorName ?? this.colorName,
      colorCode: colorCode ?? this.colorCode,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      blouseOption: blouseOption ?? this.blouseOption,
      images: images ?? this.images,
    );
  }

  factory SareeVariant.fromJson(Map<String, dynamic> json) {
    return SareeVariant(
      id: json['id'].toString(),
      colorName: json['color_name'] as String? ?? '',
      colorCode: json['color_code'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      blouseOption: BlouseOption.fromApiValue(json['blouse_option'] as String?),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => VariantImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (!id.startsWith('local_')) 'id': id,
    'color_name': colorName,
    'color_code': colorCode,
    'price': price.toStringAsFixed(2),
    'quantity': quantity,
    'blouse_option': blouseOption.apiValue,
  };
}

// The saree "design" — name, fabric, occasions, description — plus all of
// its colour variants.
class Saree {
  final String id;
  final String name;
  final String
  fabricName; // TODO: becomes a Fabric object once fabric picker is wired to /api/fabrics/
  final String description;
  final List<String> occasions;
  final String occasionImageUrl; // single mood photo shown under Occasions
  final Uint8List? occasionImageBytes; // freshly picked, not uploaded yet
  final List<SareeVariant> variants;

  const Saree({
    required this.id,
    required this.name,
    required this.fabricName,
    this.description = '',
    this.occasions = const [],
    this.occasionImageUrl = '',
    this.occasionImageBytes,
    this.variants = const [],
  });

  // ---- derived helpers used by the dashboard/detail screens ----
  int get totalStock => variants.fold(0, (sum, v) => sum + v.quantity);

  double get minPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  double get maxPrice => variants.isEmpty
      ? 0
      : variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);

  // Thumbnail shown on the dashboard card: the primary photo of the first
  // variant that has one, or the first available photo of any kind.
  VariantImage? get coverImage {
    for (final v in variants) {
      final img = v.primaryImage;
      if (img != null && img.source.isNotEmpty) return img;
    }
    return null;
  }

  // Kept for any code that only needs the display string.
  String get coverImageSource => coverImage?.source ?? '';

  Saree copyWith({
    String? id,
    String? name,
    String? fabricName,
    String? description,
    List<String>? occasions,
    String? occasionImageUrl,
    Uint8List? occasionImageBytes,
    List<SareeVariant>? variants,
  }) {
    return Saree(
      id: id ?? this.id,
      name: name ?? this.name,
      fabricName: fabricName ?? this.fabricName,
      description: description ?? this.description,
      occasions: occasions ?? this.occasions,
      occasionImageUrl: occasionImageUrl ?? this.occasionImageUrl,
      occasionImageBytes: occasionImageBytes ?? this.occasionImageBytes,
      variants: variants ?? this.variants,
    );
  }

  factory Saree.fromJson(Map<String, dynamic> json) {
    return Saree(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      fabricName: (json['fabric']?['name'] as String?) ?? '',
      description: json['description'] as String? ?? '',
      occasions:
          (json['occasions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      occasionImageUrl: json['occasion_image_url'] as String? ?? '',
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => SareeVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (!id.startsWith('local_')) 'id': id,
    'name': name,
    'description': description,
    // fabric_id / occasion_ids will replace these once the fabric/occasion
    // pickers are wired to real lookup endpoints.
    'fabric_name': fabricName,
    'occasions': occasions,
    'occasion_image_url': occasionImageUrl,
  };
}
