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
import '/shared/services/stock_notification_center.dart';
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
  // Owned by MainShell and shared with the bottom nav's "Search" tab —
  // tapping that tab flips this to true, which is what actually reveals
  // the search bar here (see _DashboardPageState). Optional so this page
  // still works if used standalone somewhere without a shell around it.
  final ValueNotifier<bool>? searchVisible;

  const DashboardPage({super.key, this.searchVisible});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Falls back to a locally-owned notifier when no shell provides one, so
  // the rest of the code below never has to null-check widget.searchVisible.
  late final ValueNotifier<bool> _searchVisible =
      widget.searchVisible ?? ValueNotifier(false);

  // In-memory only for now — most-recent-first, capped at 5, no repeats.
  final List<String> _recentSearches = [];

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
  void initState() {
    super.initState();
    // Rebuilds this page whenever the bottom nav's Search tab toggles
    // _searchVisible — that's what actually reveals/hides the panel below.
    _searchVisible.addListener(_onSearchVisibleChanged);
    // Scans the initial saree list for any colour already at 0 stock (e.g.
    // "Pink" below) and raises the bell alert + device notification for it.
    // TODO: once _mockSarees is replaced by a real API call, call this
    // again inside the same place the fetched list is set.
    StockNotificationCenter.instance.syncFromSarees(_mockSarees);
  }

  void _onSearchVisibleChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _searchVisible.removeListener(_onSearchVisibleChanged);
    // Only dispose the notifier if we created it ourselves — the shell-
    // provided one is owned (and disposed) by MainShell.
    if (widget.searchVisible == null) _searchVisible.dispose();
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
            // Fixed — always visible, not tied to the Search tab anymore.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppSearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (value) {
                  _commitSearch(value);
                  _closeOverlay();
                },
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
              child: Stack(
                children: [
                  _filteredSarees.isEmpty
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
                  // Only appears when the bottom nav's Search tab is
                  // tapped: a translucent scrim over the list below the
                  // (already-fixed) search bar, with a panel of recent
                  // searches sitting right under it. Tapping the scrim, or
                  // picking a recent search, closes it again.
                  if (_searchVisible.value) _recentSearchOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Translucent scrim + panel that drops down when the bottom nav's Search
  // tab is tapped — sits below the (always-visible) fixed search bar above
  // it, dims the saree list behind it, and shows either recent searches
  // (query empty) or live matching-saree suggestions as you type (query
  // non-empty) — typing itself still happens in the fixed bar above.
  Widget _recentSearchOverlay() {
    final query = _searchQuery.trim();
    final showingSuggestions = query.isNotEmpty;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closeOverlay, // tap the dimmed backdrop to dismiss
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () {}, // absorb taps so the panel itself doesn't close it
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _DashboardColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: showingSuggestions
                        ? [
                            const Text(
                              'Matching Sarees',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _DashboardColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_filteredSarees.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'No matching sarees',
                                  style: TextStyle(
                                    color: _DashboardColors.textGrey,
                                  ),
                                ),
                              )
                            else
                              for (final s in _filteredSarees)
                                _suggestionTile(s),
                          ]
                        : [
                            const Text(
                              'Recent Searches',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _DashboardColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_recentSearches.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'No recent searches yet',
                                  style: TextStyle(
                                    color: _DashboardColors.textGrey,
                                  ),
                                ),
                              )
                            else
                              for (final q in _recentSearches)
                                _recentSearchTile(q),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Tapping a live match: fill the field with that saree's name, log it as
  // a completed search (same as hitting enter would), and close the
  // overlay back to the (now-filtered) dashboard.
  Widget _suggestionTile(Saree saree) {
    return InkWell(
      onTap: () {
        _searchController.text = saree.name;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: saree.name.length),
        );
        setState(() => _searchQuery = saree.name);
        _commitSearch(saree.name);
        _closeOverlay();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              size: 18,
              color: _DashboardColors.textGrey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saree.name,
                    style: const TextStyle(color: _DashboardColors.textDark),
                  ),
                  Text(
                    'in ${saree.fabricName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _DashboardColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentSearchTile(String query) {
    return InkWell(
      onTap: () {
        _searchController.text = query;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: query.length),
        );
        setState(() => _searchQuery = query);
        _closeOverlay();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.history,
              size: 18,
              color: _DashboardColors.textGrey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                query,
                style: const TextStyle(color: _DashboardColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Records a completed search (enter / keyboard search action — not every
  // keystroke) into _recentSearches: most-recent-first, no duplicates,
  // capped at 5 so the panel doesn't grow unbounded.
  void _commitSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 5) {
        _recentSearches.removeRange(5, _recentSearches.length);
      }
    });
  }

  // Just hides the overlay — the fixed search bar's own text/query is left
  // exactly as-is, since it's always on screen now and isn't "closed" by
  // this the way it used to be.
  void _closeOverlay() {
    _searchVisible.value = false;
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
    StockNotificationCenter.instance.syncFromSarees(_mockSarees);
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
    StockNotificationCenter.instance.syncFromSarees(_mockSarees);
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
    StockNotificationCenter.instance.syncFromSarees(_mockSarees);
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
