// ============================================================================
// settings_page.dart
// ----------------------------------------------------------------------------
// "Manage Attributes" screen — Fabric Collections + Occasions.
//
// Differences from the earlier reference/mock design:
//  - No "Fabric Types" section — the app only tracks Fabric Collections and
//    Occasions now (per request, fabric items themselves aren't a thing in
//    this app).
//  - No pencil/edit icon per row. Instead each row has a trailing three-dot
//    (⋮) menu with "Edit", "Delete", and "Add" for that section.
//  - Tapping a row (Silk, Cotton, Wedding, Festive, ...) expands it in
//    place and lists the names of every saree on the Dashboard that
//    belongs to that collection/occasion — pulled live from the same data
//    Dashboard uses (see AttributeRepository + SareeRepository), so it's
//    always in sync with real inventory instead of being hardcoded.
//  - Colour palette matches the Dashboard screen (cream background, gold
//    accents, white cards) rather than the app's default purple theme, per
//    request ("theme will be like the dashboard").
// ============================================================================

import 'package:flutter/material.dart';

import '../../shared/data/attribute_repository.dart';
import '../../shared/data/saree_repository.dart';
import '../../shared/widgets/saree.dart';

// Same palette as dashboard_page.dart's _DashboardColors, so this screen
// reads as part of the same "dashboard" theme rather than the app's
// default purple/gold theme used elsewhere (e.g. Style Preview).
class _SettingsColors {
  static const Color goldDark = Color(0xFF9C7D1C);
  static const Color cream = Color(0xFFFAF3E8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2B2620);
  static const Color textGrey = Color(0xFF8A8378);
  static const Color border = Color(0xFFE6DCC8);
  static const Color danger = Color(0xFFB3261E);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Rebuild whenever collections/occasions change (add/edit/delete) OR
    // whenever the underlying saree inventory changes (e.g. a saree's
    // fabric/occasions get edited on Dashboard) — either can change what
    // shows up in the expanded "matching sarees" lists below.
    AttributeRepository.instance.addListener(_onDataChanged);
    SareeRepository.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    AttributeRepository.instance.removeListener(_onDataChanged);
    SareeRepository.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  // -------------------------------------------------------------------
  // ADD / EDIT dialog — shared by both sections, just with different
  // titles/labels passed in.
  // -------------------------------------------------------------------
  Future<void> _showNameDialog({
    required String title,
    required String label,
    String initialValue = '',
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _SettingsColors.cardWhite,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(
              'Save',
              style: TextStyle(
                color: _SettingsColors.goldDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return; // cancelled
    final trimmed = result.trim();
    if (trimmed.isEmpty) return;
    onSubmit(trimmed);
  }

  Future<bool> _confirmDelete(String itemLabel, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _SettingsColors.cardWhite,
        title: Text('Delete this $itemLabel?'),
        content: Text('"$name" will be removed. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: _SettingsColors.danger),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // ---- Fabric Collection actions ----
  void _onAddCollection() {
    _showNameDialog(
      title: 'Add Collection',
      label: 'Collection name',
      onSubmit: (name) =>
          AttributeRepository.instance.addFabricCollection(name),
    );
  }

  void _onEditCollection(String name) {
    _showNameDialog(
      title: 'Edit Collection',
      label: 'Collection name',
      initialValue: name,
      onSubmit: (newName) =>
          AttributeRepository.instance.editFabricCollection(name, newName),
    );
  }

  Future<void> _onDeleteCollection(String name) async {
    final confirmed = await _confirmDelete('collection', name);
    if (confirmed) AttributeRepository.instance.deleteFabricCollection(name);
  }

  // ---- Occasion actions ----
  void _onAddOccasion() {
    _showNameDialog(
      title: 'Add Occasion',
      label: 'Occasion name',
      onSubmit: (name) => AttributeRepository.instance.addOccasion(name),
    );
  }

  void _onEditOccasion(String name) {
    _showNameDialog(
      title: 'Edit Occasion',
      label: 'Occasion name',
      initialValue: name,
      onSubmit: (newName) =>
          AttributeRepository.instance.editOccasion(name, newName),
    );
  }

  Future<void> _onDeleteOccasion(String name) async {
    final confirmed = await _confirmDelete('occasion', name);
    if (confirmed) AttributeRepository.instance.deleteOccasion(name);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AttributeRepository.instance;

    return Container(
      color: _SettingsColors.cream,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'MANAGE ATTRIBUTES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: _SettingsColors.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          _AttributeSectionCard(
            title: 'Fabric Collections',
            items: repo.fabricCollections,
            matchesFor: (name) => repo.sareesInFabricCollection(name),
            addButtonLabel: '+ Add Collection',
            onAdd: _onAddCollection,
            onEdit: _onEditCollection,
            onDelete: _onDeleteCollection,
            editMenuLabel: 'Edit Collection',
            deleteMenuLabel: 'Delete Collection',
            addMenuLabel: 'Add Collection',
          ),
          const SizedBox(height: 16),
          _AttributeSectionCard(
            title: 'Occasions',
            items: repo.occasions,
            matchesFor: (name) => repo.sareesForOccasion(name),
            addButtonLabel: '+ Add Occasion',
            onAdd: _onAddOccasion,
            onEdit: _onEditOccasion,
            onDelete: _onDeleteOccasion,
            editMenuLabel: 'Edit Occasion',
            deleteMenuLabel: 'Delete Occasion',
            addMenuLabel: 'Add Occasion',
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// SECTION CARD — one card per attribute type (Fabric Collections / Occasions),
// containing an expandable row per item plus an "Add" pill button at the
// bottom, matching the reference screenshot's layout.
// ----------------------------------------------------------------------------
class _AttributeSectionCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<Saree> Function(String name) matchesFor;
  final String addButtonLabel;
  final VoidCallback onAdd;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;
  final String editMenuLabel;
  final String deleteMenuLabel;
  final String addMenuLabel;

  const _AttributeSectionCard({
    required this.title,
    required this.items,
    required this.matchesFor,
    required this.addButtonLabel,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.editMenuLabel,
    required this.deleteMenuLabel,
    required this.addMenuLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SettingsColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SettingsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _SettingsColors.textDark,
              ),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'None yet — add one below.',
                style: TextStyle(color: _SettingsColors.textGrey),
              ),
            )
          else
            ...items.map(
              (name) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ExpandableAttributeRow(
                  name: name,
                  matches: matchesFor(name),
                  onEdit: () => onEdit(name),
                  onDelete: () => onDelete(name),
                  onAdd: onAdd,
                  editMenuLabel: editMenuLabel,
                  deleteMenuLabel: deleteMenuLabel,
                  addMenuLabel: addMenuLabel,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _SettingsColors.goldDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  addButtonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// EXPANDABLE ROW — one Fabric Collection / Occasion entry. Tapping the row
// (the ">" chevron area) expands it to show the names of matching sarees.
// The trailing "⋮" opens the Edit/Delete/Add menu (replaces the old pencil
// icon).
// ----------------------------------------------------------------------------
class _ExpandableAttributeRow extends StatefulWidget {
  final String name;
  final List<Saree> matches;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAdd;
  final String editMenuLabel;
  final String deleteMenuLabel;
  final String addMenuLabel;

  const _ExpandableAttributeRow({
    required this.name,
    required this.matches,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    required this.editMenuLabel,
    required this.deleteMenuLabel,
    required this.addMenuLabel,
  });

  @override
  State<_ExpandableAttributeRow> createState() =>
      _ExpandableAttributeRowState();
}

class _ExpandableAttributeRowState extends State<_ExpandableAttributeRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _SettingsColors.textGrey,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _SettingsColors.textDark,
                    ),
                  ),
                ),
                if (widget.matches.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _SettingsColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _SettingsColors.border),
                    ),
                    child: Text(
                      '${widget.matches.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _SettingsColors.goldDark,
                      ),
                    ),
                  ),
                // Three-dot menu — replaces the old pencil/edit icon.
                // Contains Edit / Delete for THIS item, and Add for
                // creating a new one, as requested.
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: _SettingsColors.textGrey,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEdit();
                        break;
                      case 'delete':
                        widget.onDelete();
                        break;
                      // "Add" option commented out per request — the
                      // section-level "+ Add Collection"/"+ Add Occasion"
                      // button at the bottom of the card still works.
                      // case 'add':
                      //   widget.onAdd();
                      //   break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: _SettingsColors.textDark,
                          ),
                          const SizedBox(width: 10),
                          Text(widget.editMenuLabel),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: _SettingsColors.danger,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.deleteMenuLabel,
                            style: const TextStyle(
                              color: _SettingsColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // "Add Collection"/"Add Occasion" menu item commented
                    // out per request — kept here in case it's wanted back
                    // later. The section's "+ Add Collection"/"+ Add
                    // Occasion" pill button still does the same thing.
                    // PopupMenuItem(
                    //   value: 'add',
                    //   child: Row(
                    //     children: [
                    //       const Icon(
                    //         Icons.add,
                    //         size: 18,
                    //         color: _SettingsColors.goldDark,
                    //       ),
                    //       const SizedBox(width: 10),
                    //       Text(widget.addMenuLabel),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 10, right: 4),
            child: widget.matches.isEmpty
                ? const Text(
                    'No sarees yet in this category.',
                    style: TextStyle(
                      fontSize: 13,
                      color: _SettingsColors.textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.matches
                        .map(
                          (saree) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: _SettingsColors.goldDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    saree.name.isEmpty
                                        ? '(Unnamed saree)'
                                        : saree.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: _SettingsColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 150),
        ),
        const Divider(height: 1, color: _SettingsColors.border),
      ],
    );
  }
}
