// ============================================================================
// products_page.dart
// Detail screen for a Saree. Colour swatches switch which SareeVariant is
// selected — that changes the photo gallery, price, and stock shown, since
// each variant has its own. Occasions/description/fabric stay saree-level.
// ============================================================================

import 'package:flutter/material.dart';

import '/shared/widgets/swatch_color.dart';
import '/shared/widgets/app_image.dart';
import '/shared/widgets/saree.dart';

class _ProductColors {
  static const Color goldDark = Color(0xFF9C7D1C);
  static const Color cream = Color(0xFFFAF3E8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2B2620);
  static const Color textGrey = Color(0xFF8A8378);
  static const Color border = Color(0xFFE6DCC8);
  static const Color inStock = Color(0xFF3F8A4C);
  static const Color outOfStock = Color(0xFFC0392B);
}

class ProductsPage extends StatefulWidget {
  final Saree saree;

  const ProductsPage({super.key, required this.saree});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late SareeVariant _selectedVariant;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.saree.variants.isNotEmpty
        ? widget.saree.variants.first
        : SareeVariant(id: '', colorName: '', price: 0, quantity: 0);
  }

  void _selectVariant(SareeVariant variant) {
    setState(() {
      _selectedVariant = variant;
      _selectedImageIndex = 0; // reset to the new variant's first photo
    });
  }

  List<VariantImage> get _galleryImages {
    final images = _selectedVariant.images;
    return images.isNotEmpty ? images : const [VariantImage(source: '')];
  }

  @override
  Widget build(BuildContext context) {
    final saree = widget.saree;
    final images = _galleryImages;
    final inStock = _selectedVariant.quantity > 0;

    return Scaffold(
      backgroundColor: _ProductColors.cream,
      appBar: AppBar(
        backgroundColor: _ProductColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ProductColors.textDark),
        title: const Text(
          'Saree Details',
          style: TextStyle(
            color: _ProductColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGallery(images),
              const SizedBox(height: 20),

              Text(
                saree.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _ProductColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _buildAvailabilityBadge(inStock, _selectedVariant.quantity),

              const SizedBox(height: 20),

              _sectionLabel('Fabric'),
              const SizedBox(height: 4),
              Text(
                saree.fabricName,
                style: const TextStyle(
                  fontSize: 15,
                  color: _ProductColors.textDark,
                ),
              ),

              if (saree.description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel('Description'),
                const SizedBox(height: 4),
                Text(
                  saree.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _ProductColors.textDark,
                  ),
                ),
              ],

              if (saree.occasions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel('Occasions'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: saree.occasions
                      .map((occasion) => _occasionChip(occasion))
                      .toList(),
                ),
                if (saree.occasionImageUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  AppImage(
                    source: saree.occasionImageUrl,
                    bytes: saree.occasionImageBytes,
                    width: double.infinity,
                    height: 150,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ],
              ],

              // ---- Colour Available — tap to switch variant ----
              if (saree.variants.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel('Colour Available'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: saree.variants
                      .map((v) => _colorChip(v, v.id == _selectedVariant.id))
                      .toList(),
                ),
              ],

              // ---- Price (for the selected colour) ----
              const SizedBox(height: 24),
              _sectionLabel('Price'),
              const SizedBox(height: 4),
              Text(
                '\u20B9${_selectedVariant.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _ProductColors.goldDark,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(List<VariantImage> images) {
    final safeIndex = _selectedImageIndex.clamp(0, images.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppImage(
          source: images[safeIndex].source,
          bytes: images[safeIndex].bytes,
          width: double.infinity,
          height: 340,
          borderRadius: BorderRadius.circular(18),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == safeIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? _ProductColors.goldDark
                            : _ProductColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: AppImage(
                      source: images[index].source,
                      bytes: images[index].bytes,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _ProductColors.textGrey,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildAvailabilityBadge(bool inStock, int stock) {
    final color = inStock ? _ProductColors.inStock : _ProductColors.outOfStock;
    final label = inStock ? 'In Stock ($stock)' : 'Out of Stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _occasionChip(String occasion) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _ProductColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ProductColors.border),
      ),
      child: Text(
        occasion,
        style: const TextStyle(fontSize: 13, color: _ProductColors.textDark),
      ),
    );
  }

  // Tapping a colour chip switches the whole page (photos/price/stock) to
  // that variant.
  Widget _colorChip(SareeVariant variant, bool selected) {
    final outOfStock = variant.quantity == 0;
    return GestureDetector(
      onTap: () => _selectVariant(variant),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _ProductColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _ProductColors.goldDark : _ProductColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: swatchColorFor(variant.colorCode, variant.colorName),
                shape: BoxShape.circle,
                border: Border.all(color: _ProductColors.border),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              variant.colorName,
              style: TextStyle(
                fontSize: 13,
                color: outOfStock
                    ? _ProductColors.textGrey
                    : _ProductColors.textDark,
                decoration: outOfStock ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}