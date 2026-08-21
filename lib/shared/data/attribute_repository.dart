// ============================================================================
// attribute_repository.dart
//
// Also owns the matching logic that lets Settings show "which sarees use
// this collection/occasion" when a row is expanded:
//   - A saree belongs to a Fabric Collection if its `fabricName` mentions
//     the collection name, e.g. fabricName "Silk - Banarasi" matches the
//     "Silk" collection. (Today `fabricName` is a free-text string — see
//     the TODO in saree.dart. Once /api/fabrics/ exists and every saree
//     stores a real fabric_collection_id, swap this for an exact id match.)
//   - A saree belongs to an Occasion if its `occasions` tag list contains
//     that occasion name (case-insensitive exact match, since occasions
//     are already picked from a fixed tag list in EditSareePage).
//
// TODO: once the backend exposes /api/fabric-collections/ and
// /api/occasions/, replace the seed lists below with real GET calls, and
// the add/edit/delete methods with POST/PATCH/DELETE calls.
// ============================================================================

import 'package:flutter/foundation.dart';

import '../widgets/saree.dart';
import 'saree_repository.dart';

class AttributeRepository extends ChangeNotifier {
  AttributeRepository._internal();

  static final AttributeRepository instance = AttributeRepository._internal();

  final List<String> _fabricCollections = ['Silk', 'Cotton'];
  final List<String> _occasions = ['Wedding', 'Festive'];

  List<String> get fabricCollections => List.unmodifiable(_fabricCollections);
  List<String> get occasions => List.unmodifiable(_occasions);

  bool _containsIgnoreCase(List<String> list, String value) =>
      list.any((e) => e.toLowerCase() == value.trim().toLowerCase());

  // ---------------------------------------------------------------------
  // FABRIC COLLECTIONS
  // ---------------------------------------------------------------------
  void addFabricCollection(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_containsIgnoreCase(_fabricCollections, trimmed)) return;
    _fabricCollections.add(trimmed);
    notifyListeners();
  }

  void editFabricCollection(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final index = _fabricCollections.indexOf(oldName);
    if (index == -1) return;
    _fabricCollections[index] = trimmed;
    notifyListeners();
  }

  void deleteFabricCollection(String name) {
    if (_fabricCollections.remove(name)) notifyListeners();
  }

  /// Sarees whose fabricName mentions [collection], e.g. "Silk" matches
  /// fabricName "Silk - Banarasi".
  List<Saree> sareesInFabricCollection(String collection) {
    final needle = collection.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return SareeRepository.instance.sarees
        .where((s) => s.fabricName.toLowerCase().contains(needle))
        .toList();
  }

  // ---------------------------------------------------------------------
  // OCCASIONS
  // ---------------------------------------------------------------------
  void addOccasion(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_containsIgnoreCase(_occasions, trimmed)) return;
    _occasions.add(trimmed);
    notifyListeners();
  }

  void editOccasion(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final index = _occasions.indexOf(oldName);
    if (index == -1) return;
    _occasions[index] = trimmed;
    notifyListeners();
  }

  void deleteOccasion(String name) {
    if (_occasions.remove(name)) notifyListeners();
  }

  /// Sarees tagged with [occasion] (case-insensitive exact tag match).
  List<Saree> sareesForOccasion(String occasion) {
    final needle = occasion.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return SareeRepository.instance.sarees
        .where((s) => s.occasions.any((o) => o.toLowerCase() == needle))
        .toList();
  }
}
