// ============================================================================
// app_image.dart
// A saree's photo can now come from two places:
//   1. A network URL (old mock data, or a real backend URL once you upload
//      the picked photo to storage).
//   2. A local file path on the user's device (fresh pick from gallery/
//      camera on the Edit Saree page, not uploaded anywhere yet).
// Every place that used to call `Image.network(saree.imageUrl)` directly
// now uses <AppImage source: saree.imageUrl /> instead, so it doesn't have
// to care which kind of path it got.
//
// NOTE (web): local file picking on Flutter Web returns a blob: URL, not a
// real filesystem path, so `dart:io File` can't read it there — that's the
// "Image.file is not supported on Flutter Web" crash. Fix: whoever picks a
// local photo (see edit_saree_page._pickImage) also reads its raw bytes via
// XFile.readAsBytes() and passes them in as `bytes`. When `bytes` is set,
// this widget always renders with Image.memory, which works identically on
// web, mobile, and desktop. `source`/`File` is now only the mobile/desktop
// fallback for a local path with no bytes attached.
// ============================================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String source; // network URL OR local file path
  final Uint8List? bytes; // raw bytes for a freshly-picked local photo
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final Color placeholderIconColor;

  const AppImage({
    super.key,
    required this.source,
    this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor = const Color(0xFFFAF3E8),
    this.placeholderIconColor = const Color(0xFF8A8378),
  });

  bool get _isNetwork =>
      source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (bytes != null) {
      // Freshly picked local photo — works on every platform, web included.
      image = Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else if (source.trim().isEmpty) {
      image = _placeholder();
    } else if (_isNetwork) {
      image = Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else if (kIsWeb) {
      // A local file path with no bytes attached can't be read on web
      // (dart:io File isn't supported there) — show the placeholder
      // instead of crashing.
      image = _placeholder();
    } else {
      // Local file path picked from the device (gallery/camera), mobile/desktop.
      image = Image.file(
        File(source),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported, color: placeholderIconColor),
    );
  }
}