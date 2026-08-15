// ============================================================================
// edit_saree_page.dart
// Editable form for an existing Saree, rebuilt around the real schema:
//  - Saree-level fields: name, fabric, description, occasions, occasion photo
//  - A list of colour VARIANTS, each with its own price, stock, blouse
//    option, and its own photo gallery (picked straight from the device).
// On Save, pops back with the updated Saree. The dashboard replaces the
// matching saree in its list by id, so the detail page shows the new data
// next time it's opened.
//
// TODO (when backend is wired up): in `_onSave`, upload any local (not-yet-
// uploaded) variant photos and swap in the resulting URLs, POST any brand
// new variants (id starts with "local_") and PUT any edited existing ones,
// before/alongside popping.
// ============================================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/shared/widgets/app_button.dart';
import '/shared/widgets/app_image.dart';
import '/shared/widgets/saree.dart';

class _EditColors {
  static const Color goldDark = Color(0xFF9C7D1C);
  static const Color cream = Color(0xFFFAF3E8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2B2620);
  static const Color textGrey = Color(0xFF8A8378);
  static const Color border = Color(0xFFE6DCC8);
  static const Color danger = Color(0xFFC0392B);
}

class EditSareePage extends StatefulWidget {
  final Saree saree;
  // True when this page was opened from "Add New Saree" (blank starting
  // saree) rather than editing an existing one — only changes the title/
  // button copy, the save logic underneath is identical either way.
  final bool isNew;

  const EditSareePage({super.key, required this.saree, this.isNew = false});

  @override
  State<EditSareePage> createState() => _EditSareePageState();
}

// Mutable, controller-backed working copy of one variant while it's being
// edited. Converted back to a SareeVariant on Save.
class _VariantForm {
  String id;
  final TextEditingController colorNameController;
  final TextEditingController colorCodeController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  BlouseOption blouseOption;
  List<VariantImage> images;

  _VariantForm({
    required this.id,
    required String colorName,
    required String colorCode,
    required double price,
    required int quantity,
    required this.blouseOption,
    required this.images,
  }) : colorNameController = TextEditingController(text: colorName),
       colorCodeController = TextEditingController(text: colorCode),
       // Leave the field blank (so the "Price ₹" / "Stock" hint shows
       // through) instead of literally showing "0" — toVariant() already
       // falls back to 0 on save if nothing was typed, so behaviour is
       // unchanged either way.
       priceController = TextEditingController(
         text: price == 0
             ? ''
             : (price == price.roundToDouble()
                   ? price.toStringAsFixed(0)
                   : price.toString()),
       ),
       quantityController = TextEditingController(
         text: quantity == 0 ? '' : quantity.toString(),
       );

  factory _VariantForm.fromVariant(SareeVariant v) => _VariantForm(
    id: v.id,
    colorName: v.colorName,
    colorCode: v.colorCode,
    price: v.price,
    quantity: v.quantity,
    blouseOption: v.blouseOption,
    images: List<VariantImage>.from(v.images),
  );

  factory _VariantForm.blank() => _VariantForm(
    id: 'local_${DateTime.now().microsecondsSinceEpoch}',
    colorName: '',
    colorCode: '',
    price: 0,
    quantity: 0,
    blouseOption: BlouseOption.withBlouse,
    images: const [],
  );

  void dispose() {
    colorNameController.dispose();
    colorCodeController.dispose();
    priceController.dispose();
    quantityController.dispose();
  }

  SareeVariant toVariant() => SareeVariant(
    id: id,
    colorName: colorNameController.text.trim(),
    colorCode: colorCodeController.text.trim(),
    price: double.tryParse(priceController.text.trim()) ?? 0,
    quantity: int.tryParse(quantityController.text.trim()) ?? 0,
    blouseOption: blouseOption,
    images: images,
  );
}

class _EditSareePageState extends State<EditSareePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _fabricController;
  late final TextEditingController _descriptionController;
  late final TextEditingController
  _occasionImageDummy; // unused, kept for symmetry
  late String _occasionImage;
  Uint8List? _occasionImageBytes;

  late List<_VariantForm> _variants;
  late List<String> _occasions;
  final _newOccasionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = widget.saree;
    _nameController = TextEditingController(text: s.name);
    _fabricController = TextEditingController(text: s.fabricName);
    _descriptionController = TextEditingController(text: s.description);
    _occasionImageDummy = TextEditingController();
    _occasionImage = s.occasionImageUrl;

    _occasions = List<String>.from(s.occasions);
    _variants = s.variants.map(_VariantForm.fromVariant).toList();
    if (_variants.isEmpty) {
      // Every saree needs at least one colour to be sellable — start the
      // editor with one blank variant to fill in.
      _variants.add(_VariantForm.blank());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fabricController.dispose();
    _descriptionController.dispose();
    _occasionImageDummy.dispose();
    _newOccasionController.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // PHOTO PICKING (shared by every variant's gallery + the occasion photo)
  // ---------------------------------------------------------------------
  Future<void> _pickImage(
    void Function(String path, Uint8List bytes) onPicked,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _EditColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: _EditColors.textDark,
              ),
              title: const Text('Choose from Gallery / Files'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: _EditColors.textDark,
              ),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    // Read bytes (not just the path) so the photo can actually be rendered
    // on Flutter Web — see the note in app_image.dart.
    final bytes = await picked.readAsBytes();
    onPicked(picked.path, bytes);
  }

  // ---------------------------------------------------------------------
  // VARIANT LIST OPS
  // ---------------------------------------------------------------------
  void _addVariant() {
    // Insert at the front (not appended at the end) so the new colour card
    // opens right where you're looking, instead of you having to scroll
    // past every existing colour to find it. Save order doesn't matter —
    // this only changes where it shows up on screen.
    setState(() => _variants.insert(0, _VariantForm.blank()));
  }

  void _removeVariant(_VariantForm variant) {
    if (_variants.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A saree needs at least one colour.')),
      );
      return;
    }
    setState(() {
      _variants.remove(variant);
      variant.dispose();
    });
  }

  // ---------------------------------------------------------------------
  // SAVE
  // ---------------------------------------------------------------------
  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation the Form widget can't express: every variant needs
    // a colour name, and at least one photo is strongly recommended.
    for (final v in _variants) {
      if (v.colorNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Every colour needs a name.')),
        );
        return;
      }
    }

    final updated = widget.saree.copyWith(
      name: _nameController.text.trim(),
      fabricName: _fabricController.text.trim(),
      description: _descriptionController.text.trim(),
      occasions: List<String>.from(_occasions),
      occasionImageUrl: _occasionImage,
      occasionImageBytes: _occasionImageBytes,
      variants: _variants.map((v) => v.toVariant()).toList(),
    );

    // TODO: once the Django API URL/endpoints are wired up — replace this
    // local pop with a real call: POST /api/sarees/ when widget.isNew is
    // true (create), PUT /api/sarees/<id>/ when it's false (update), plus
    // uploading any local (not-yet-uploaded) variant photos first. Until
    // then this "saves" by handing the new/updated Saree back to the
    // dashboard, which keeps it in _mockSarees so Add New Saree is fully
    // usable as a demo right now.
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _EditColors.cream,
      appBar: AppBar(
        backgroundColor: _EditColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _EditColors.textDark),
        title: Text(
          widget.isNew ? 'Add New Saree' : 'Edit Saree',
          style: const TextStyle(
            color: _EditColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Name'),
                const SizedBox(height: 6),
                _textField(
                  controller: _nameController,
                  hint: 'e.g. Banarasi Silk',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 18),

                _sectionLabel('Fabric'),
                const SizedBox(height: 4),
                Text(
                  'TODO: swap for a dropdown once /api/fabrics/ is wired up.',
                  style: TextStyle(fontSize: 11, color: _EditColors.textGrey),
                ),
                const SizedBox(height: 6),
                _textField(
                  controller: _fabricController,
                  hint: 'e.g. Silk - Banarasi',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 18),

                _sectionLabel('Description'),
                const SizedBox(height: 6),
                _textField(
                  controller: _descriptionController,
                  hint: 'Describe the saree...',
                  maxLines: 4,
                ),
                const SizedBox(height: 20),

                _sectionLabel('Occasions'),
                const SizedBox(height: 8),
                _editableChipList(
                  values: _occasions,
                  controller: _newOccasionController,
                  hint: 'e.g. Wedding',
                  onAdd: (v) => setState(() => _occasions.add(v)),
                  onRemove: (v) => setState(() => _occasions.remove(v)),
                ),
                const SizedBox(height: 28),
                // Occasion Photo section removed per request — only the
                // Occasions tag list stays. _occasionPhotoPicker() and the
                // _occasionImage/_occasionImageBytes state are left in
                // place untouched (occasionImageUrl just stays whatever it
                // started as, unset for a new saree) in case the photo
                // picker comes back later.

                // ---- Colour variants ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionLabel('Colour Variants'),
                    TextButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: _EditColors.goldDark,
                      ),
                      label: const Text(
                        'Add Colour',
                        style: TextStyle(color: _EditColors.goldDark),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Each colour has its own price, stock, and photos.',
                  style: TextStyle(fontSize: 12, color: _EditColors.textGrey),
                ),
                const SizedBox(height: 10),
                for (final variant in _variants) ...[
                  _variantCard(variant),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 18),
                AppButton(
                  label: widget.isNew ? 'ADD SAREE' : 'SAVE CHANGES',
                  onPressed: _onSave,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'CANCEL',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // VALIDATORS
  // ---------------------------------------------------------------------
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _intValidator(String? value) {
    // Empty is fine — left blank + Save means "0" (see toVariant()'s
    // int.tryParse(...) ?? 0), so don't force the person to type a 0.
    if (value == null || value.trim().isEmpty) return null;
    if (int.tryParse(value.trim()) == null) return 'Whole number';
    return null;
  }

  String? _priceValidator(String? value) {
    // Empty is fine — left blank + Save means "0" (see toVariant()'s
    // double.tryParse(...) ?? 0), so don't force the person to type a 0.
    if (value == null || value.trim().isEmpty) return null;
    if (double.tryParse(value.trim()) == null) return 'Invalid price';
    return null;
  }

  // ---------------------------------------------------------------------
  // SHARED WIDGETS
  // ---------------------------------------------------------------------
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _EditColors.textGrey,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _EditColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _EditColors.textGrey, fontSize: 14),
        filled: true,
        fillColor: _EditColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _EditColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _EditColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _EditColors.goldDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _EditColors.danger),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // VARIANT CARD
  // ---------------------------------------------------------------------
  Widget _variantCard(_VariantForm variant) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _EditColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _EditColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: variant.colorNameController,
                  builder: (context, value, _) => Text(
                    value.text.trim().isEmpty
                        ? 'New Colour'
                        : value.text.trim(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _EditColors.textDark,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: _EditColors.danger,
                  size: 20,
                ),
                onPressed: () => _removeVariant(variant),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _textField(
                  controller: variant.colorNameController,
                  hint: 'Colour name (e.g. Maroon)',
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  controller: variant.colorCodeController,
                  hint: '#Hex (optional)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _textField(
                  controller: variant.priceController,
                  hint: 'Price \u20B9',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _priceValidator,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  controller: variant.quantityController,
                  hint: 'Stock',
                  keyboardType: TextInputType.number,
                  validator: _intValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Blouse option dropdown
          DropdownButtonFormField<BlouseOption>(
            initialValue: variant.blouseOption,
            decoration: InputDecoration(
              filled: true,
              fillColor: _EditColors.cream,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _EditColors.border),
              ),
            ),
            items: BlouseOption.values
                .map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(o.label, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => variant.blouseOption = value);
              }
            },
          ),
          const SizedBox(height: 12),

          Text(
            'Photos for this colour',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _EditColors.textGrey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          _variantGallery(variant),
        ],
      ),
    );
  }

  // Horizontal photo strip for one variant: tap a photo to mark it primary,
  // remove with the × badge, add more with the trailing "+" tile.
  Widget _variantGallery(_VariantForm variant) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final img in variant.images)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  variant.images = variant.images
                      .map((i) => i.copyWith(isPrimary: i == img))
                      .toList();
                }),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: img.isPrimary
                              ? _EditColors.goldDark
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: AppImage(
                        source: img.source,
                        bytes: img.bytes,
                        width: 76,
                        height: 84,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: GestureDetector(
                        onTap: () => setState(
                          () => variant.images = variant.images
                              .where((i) => i != img)
                              .toList(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (img.isPrimary)
                      Positioned(
                        bottom: 3,
                        left: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _EditColors.goldDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(fontSize: 9, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: 76,
            height: 84,
            child: GestureDetector(
              onTap: () => _pickImage(
                (path, bytes) => setState(() {
                  final makePrimary = variant.images.isEmpty;
                  variant.images = [
                    ...variant.images,
                    VariantImage(
                      source: path,
                      bytes: bytes,
                      isPrimary: makePrimary,
                    ),
                  ];
                }),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _EditColors.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _EditColors.border),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: _EditColors.goldDark,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // // ---------------------------------------------------------------------
  // // OCCASION PHOTO (saree-level, single image)
  // // ---------------------------------------------------------------------
  // Widget _occasionPhotoPicker() {
  //   if (_occasionImage.trim().isEmpty) {
  //     return GestureDetector(
  //       onTap: () => _pickImage(
  //         (path, bytes) => setState(() {
  //           _occasionImage = path;
  //           _occasionImageBytes = bytes;
  //         }),
  //       ),
  //       child: Container(
  //         width: double.infinity,
  //         height: 90,
  //         decoration: BoxDecoration(
  //           color: _EditColors.cardWhite,
  //           borderRadius: BorderRadius.circular(14),
  //           border: Border.all(color: _EditColors.border),
  //         ),
  //         alignment: Alignment.center,
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Icon(
  //               Icons.add_a_photo_outlined,
  //               color: _EditColors.goldDark,
  //               size: 22,
  //             ),
  //             const SizedBox(height: 6),
  //             Text(
  //               'Add Occasion Photo (optional)',
  //               style: TextStyle(fontSize: 12, color: _EditColors.textGrey),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //   return Stack(
  //     alignment: Alignment.topRight,
  //     children: [
  //       GestureDetector(
  //         onTap: () => _pickImage(
  //           (path, bytes) => setState(() {
  //             _occasionImage = path;
  //             _occasionImageBytes = bytes;
  //           }),
  //         ),
  //         child: AppImage(
  //           source: _occasionImage,
  //           bytes: _occasionImageBytes,
  //           width: double.infinity,
  //           height: 140,
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //       ),
  //       Padding(
  //         padding: const EdgeInsets.all(6),
  //         child: GestureDetector(
  //           onTap: () => setState(() {
  //             _occasionImage = '';
  //             _occasionImageBytes = null;
  //           }),
  //           child: Container(
  //             padding: const EdgeInsets.all(3),
  //             decoration: const BoxDecoration(
  //               color: Colors.black54,
  //               shape: BoxShape.circle,
  //             ),
  //             child: const Icon(Icons.close, size: 14, color: Colors.white),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ---------------------------------------------------------------------
  // OCCASIONS CHIP LIST (saree-level)
  // ---------------------------------------------------------------------
  Widget _editableChipList({
    required List<String> values,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (v) => Chip(
                  label: Text(v, style: const TextStyle(fontSize: 13)),
                  backgroundColor: _EditColors.cardWhite,
                  side: const BorderSide(color: _EditColors.border),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: _EditColors.danger,
                  onDeleted: () => onRemove(v),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _textField(controller: controller, hint: hint),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: _EditColors.goldDark,
                size: 28,
              ),
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty || values.contains(value)) return;
                onAdd(value);
                controller.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}
