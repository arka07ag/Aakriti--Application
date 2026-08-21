// saree_repository.dart
// TODO: once the backend is wired up, replace the seed list below with a
// real GET /api/sarees/ call, and swap the add/update/delete methods for
// the matching POST/PATCH/DELETE calls. Nothing else in the app needs to
// change — everything else already just calls these three methods.


import 'package:flutter/foundation.dart';

import '../widgets/saree.dart';

class SareeRepository extends ChangeNotifier {
  SareeRepository._internal();

  static final SareeRepository instance = SareeRepository._internal();

  // ---------------------------------------------------------------------
  // SEED / MOCK DATA — moved here verbatim from dashboard_page.dart's old
  // _mockSarees field. fabricName follows a "Collection - Type" convention
  // (e.g. "Silk - Banarasi") so it can be matched back to a Fabric
  // Collection ("Silk") in Settings — see AttributeRepository.
  // ---------------------------------------------------------------------
  final List<Saree> _sarees = [
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
            VariantImage(source: 'https://via.placeholder.com/600x800.png?text=Maroon+2'),
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
      occasions: const ['Wedding'],
      variants: const [
        SareeVariant(
          id: 'variant_2a',
          colorName: 'Green',
          colorCode: '#2E7D32',
          price: 6499,
          quantity: 12,
          images: [
            VariantImage(source: 'https://via.placeholder.com/150', isPrimary: true),
          ],
        ),
      ],
    ),
    Saree(
      id: 'saree_3',
      name: 'Chanderi Cotton',
      fabricName: 'Cotton - Chanderi',
      occasions: const ['Festive'],
      variants: const [
        SareeVariant(
          id: 'variant_3a',
          colorName: 'Beige',
          colorCode: '#E8DCC4',
          price: 2199,
          quantity: 8,
          images: [
            VariantImage(source: 'https://via.placeholder.com/150', isPrimary: true),
          ],
        ),
      ],
    ),
  ];

  /// Read-only snapshot — callers must go through [addSaree]/[updateSaree]/
  /// [deleteSaree] to mutate, so this repository always knows to notify.
  List<Saree> get sarees => List.unmodifiable(_sarees);

  void addSaree(Saree saree) {
    _sarees.insert(0, saree);
    notifyListeners();
  }

  void updateSaree(Saree saree) {
    final index = _sarees.indexWhere((s) => s.id == saree.id);
    if (index != -1) {
      _sarees[index] = saree;
      notifyListeners();
    }
  }

  void deleteSaree(String id) {
    _sarees.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}