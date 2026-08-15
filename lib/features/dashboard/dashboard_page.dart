// ============================================================================
// dashboard_page.dart
// Rebuilt around the real schema: each Saree has multiple SareeVariant
// colour options, each with its own price/stock/photos.
//  - Card shows: cover photo (first variant's primary photo), name, fabric,
//    total stock across all variants, and a price range if variants differ.
//  - Mock data lives in _mockSarees below — swap for your API call later.
// ============================================================================

import 'package:flutter/material.dart';

import '/shared/widgets/app_search_field.dart';
import '/shared/widgets/app_button.dart';
import '/shared/widgets/app_image.dart';
import '/shared/widgets/saree.dart';
import '/shared/widgets/swatch_color.dart';
import '../products/products_page.dart';
import '../products/edit_saree_page.dart';

class _DashboardColors {
  static const Color goldDark = Color(0xFF9C7D1C);
  static const Color cream = Color(0xFFFAF3E8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2B2620);
  static const Color textGrey = Color(0xFF8A8378);
  static const Color border = Color(0xFFE6DCC8);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ---------------------------------------------------------------------
  // MOCK DATA — TODO: replace with a real API call (GET /api/sarees/)
  // when the backend is ready. The shape here matches Saree.fromJson, so
  // swapping in real data later is a one-line change in a FutureBuilder.
  // ---------------------------------------------------------------------
  final List<Saree> _mockSarees = [
    Saree(
      id: 'saree_1',
      name: 'Banarasi Silk',
      fabricName: 'Silk - Banarasi',
      description:
          'A handwoven Banarasi silk saree with a rich gold zari border and '
          'traditional motifs. Comes with a matching unstitched blouse piece.',
      occasions: const ['Wedding', 'Festive', 'Party'],
      occasionImageUrl:
          'https://via.placeholder.com/600x300.png?text=Wedding+Occasion',
      variants: [
        SareeVariant(
          id: 'variant_1a',
          colorName: 'Maroon',
          colorCode: '#800000',
          price: 4999,
          quantity: 10,
          images: const [
            VariantImage(
              source:
                  'https://cdn.pixabay.com/photo/2023/12/29/10/50/banarasi-saree-8475975_1280.jpg',
              isPrimary: true,
            ),
            VariantImage(
              source: 'https://via.placeholder.com/600x800.png?text=Maroon+2',
            ),
          ],
        ),
        SareeVariant(
          id: 'variant_1b',
          colorName: 'Gold',
          colorCode: '#C9A227',
          price: 5299,
          quantity: 4,
          images: const [
            VariantImage(
              source: 'https://via.placeholder.com/600x800.png?text=Gold+1',
              isPrimary: true,
            ),
          ],
        ),
        SareeVariant(
          id: 'variant_1c',
          colorName: 'Pink',
          colorCode: '#D6336C',
          price: 4999,
          quantity: 0, // out of stock in this colour
          images: const [
            VariantImage(
              source: 'https://via.placeholder.com/600x800.png?text=Pink+1',
              isPrimary: true,
            ),
          ],
        ),
      ],
    ),
    Saree(
      id: 'saree_2',
      name: 'Kanjivaram',
      fabricName: 'Silk - Kanjivaram',
      variants: const [
        SareeVariant(
          id: 'variant_2a',
          colorName: 'Green',
          colorCode: '#2E7D32',
          price: 6499,
          quantity: 12,
          images: [
            VariantImage(
              source: 'https://via.placeholder.com/150',
              isPrimary: true,
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Saree> get _filteredSarees {
    if (_searchQuery.trim().isEmpty) return _mockSarees;
    final query = _searchQuery.toLowerCase();
    return _mockSarees
        .where(
          (saree) =>
              saree.name.toLowerCase().contains(query) ||
              saree.fabricName.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashboardColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: AppButton(
                  label: 'ADD NEW SAREE',
                  onPressed: _onAddSaree,
                  fullWidth: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredSarees.isEmpty
                  ? const Center(
                      child: Text(
                        'No sarees found',
                        style: TextStyle(color: _DashboardColors.textGrey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filteredSarees.length,
                      itemBuilder: (context, index) {
                        final saree = _filteredSarees[index];
                        return _SareeCard(
                          saree: saree,
                          onTap: () => _onSareeTapped(saree),
                          onEdit: () => _onEditSaree(saree),
                          onAddVariant: () => _onAddVariant(saree),
                          onDelete: () => _onDeleteSaree(saree),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Opens EditSareePage pre-filled with a blank saree (empty name/fabric,
  // one blank colour variant to fill in — EditSareePage already does this
  // whenever it's handed a saree with no variants). On save, the new
  // saree is inserted at the top of _mockSarees — this is the in-memory
  // "database" for now; once a real backend endpoint exists, swap the
  // setState insert below for the POST /api/sarees/ call and use the
  // saree the server returns instead.
  Future<void> _onAddSaree() async {
    final blankSaree = Saree(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: '',
      fabricName: '',
    );

    final created = await Navigator.push<Saree>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSareePage(saree: blankSaree, isNew: true),
      ),
    );

    if (created == null) return;

    setState(() {
      _mockSarees.insert(0, created);
    });
  }

  void _onSareeTapped(Saree saree) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductsPage(saree: saree)),
    );
  }

  // Opens EditSareePage pre-filled with this saree (name, fabric,
  // description, occasions, and every colour variant). On save, replaces
  // the matching saree in _mockSarees by id.
  Future<void> _onEditSaree(Saree saree) async {
    final updated = await Navigator.push<Saree>(
      context,
      MaterialPageRoute(builder: (context) => EditSareePage(saree: saree)),
    );

    if (updated == null) return;

    setState(() {
      final index = _mockSarees.indexWhere((s) => s.id == updated.id);
      if (index != -1) _mockSarees[index] = updated;
    });
  }

  // TODO: shortcut into EditSareePage focused on adding just one new
  // variant, rather than opening the full editor. For now this opens the
  // same full editor, where "Add Variant" is one tap away.
  void _onAddVariant(Saree saree) {
    _onEditSaree(saree);
  }

  // CHANGED: was a debugPrint-only stub — nothing was actually deleted.
  // Now: confirms first (deleting is permanent and easy to hit by
  // accident from a popup menu), then removes ONLY this oane saree by its
  // id. Every other saree in _mockSarees is untouched.
  Future<void> _onDeleteSaree(Saree saree) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this saree?'),
        content: Text(
          '"${saree.name}" and all its colour variants will be removed. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      // Remove by id, so only the exact saree that was tapped is removed —
      // never the whole list.
      _mockSarees.removeWhere((s) => s.id == saree.id);
    });
  }
}

// ----------------------------------------------------------------------------
// SAREE CARD WIDGET
// ----------------------------------------------------------------------------
class _SareeCard extends StatelessWidget {
  final Saree saree;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAddVariant;
  final VoidCallback? onDelete;

  const _SareeCard({
    required this.saree,
    this.onTap,
    this.onEdit,
    this.onAddVariant,
    this.onDelete,
  });

  String get _priceLabel {
    if (saree.variants.isEmpty) return '\u2014';
    if (saree.minPrice == saree.maxPrice) {
      return '\u20B9${saree.minPrice.toStringAsFixed(0)}';
    }
    return '\u20B9${saree.minPrice.toStringAsFixed(0)}\u2013${saree.maxPrice.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _DashboardColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _DashboardColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppImage(
                    source: saree.coverImageSource,
                    bytes: saree.coverImage?.bytes,
                    width: 80,
                    height: 90,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saree Name',
                          style: TextStyle(
                            fontSize: 12,
                            color: _DashboardColors.textGrey,
                          ),
                        ),
                        Text(
                          saree.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _DashboardColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fabric',
                          style: TextStyle(
                            fontSize: 12,
                            color: _DashboardColors.textGrey,
                          ),
                        ),
                        Text(
                          saree.fabricName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _DashboardColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _priceLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _DashboardColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'STOCK',
                        style: TextStyle(
                          fontSize: 11,
                          color: _DashboardColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        saree.totalStock.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _DashboardColors.goldDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${saree.variants.length} colour${saree.variants.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _DashboardColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: _DashboardColors.textGrey,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'add_variant':
                          onAddVariant?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      // "Edit Saree" and "Add Variant" menu buttons removed
                      // per request — the underlying handlers (_onEditSaree,
                      // _onAddVariant, and the 'edit'/'add_variant' cases
                      // below in onSelected) are left in place untouched in
                      // case these buttons come back later.
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (saree.variants.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ColourStockBreakdown(saree: saree),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// COLOUR STOCK BREAKDOWN — small pill per colour showing its own stock, so
// you can see at a glance which colour is running low without opening the
// saree.
// ----------------------------------------------------------------------------
class _ColourStockBreakdown extends StatelessWidget {
  final Saree saree;

  const _ColourStockBreakdown({required this.saree});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: saree.variants.map((variant) {
        final outOfStock = variant.quantity == 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _DashboardColors.cream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _DashboardColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: swatchColorFor(variant.colorCode, variant.colorName),
                  shape: BoxShape.circle,
                  border: Border.all(color: _DashboardColors.border),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                variant.colorName,
                style: const TextStyle(
                  fontSize: 12,
                  color: _DashboardColors.textDark,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                outOfStock ? 'Out of stock' : '${variant.quantity}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: outOfStock
                      ? Colors.redAccent
                      : _DashboardColors.goldDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
