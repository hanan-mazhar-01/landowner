import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';

/// Cached, down-sampled network (or local file) image on the design's `#DFE5F5` placeholder.
///
/// Decodes at the rendered pixel width (never full resolution) to keep memory
/// flat in long lists and carousels.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center});

  /// Set false in widget tests (no network / cache plugins there).
  static bool enabled = true;

  final String? url;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!enabled || url == null || url!.isEmpty) return const ColoredBox(color: AppColors.imagePlaceholder);
    return LayoutBuilder(builder: (context, c) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final w = c.maxWidth.isFinite ? (c.maxWidth * dpr).round() : null;
      if (!url!.startsWith('http')) {
        return Image.file(File(url!), fit: fit, alignment: alignment, cacheWidth: w,
            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.imagePlaceholder));
      }
      return CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        alignment: alignment,
        memCacheWidth: w,
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (_, _) => const ColoredBox(color: AppColors.imagePlaceholder),
        errorWidget: (_, _, _) => const ColoredBox(color: AppColors.imagePlaceholder),
      );
    });
  }
}
