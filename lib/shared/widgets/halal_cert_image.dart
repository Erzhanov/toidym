import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/app/theme/app_spacing.dart';

/// Отображает фото сертификата Халал из Data URL (`data:image/...;base64,...`) или HTTP URL.
class HalalCertImage extends StatelessWidget {
  const HalalCertImage({
    super.key,
    required this.source,
    this.height = 180,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double height;
  final BoxFit fit;

  static Uint8List? tryDecodeDataUrl(String value) {
    if (!value.startsWith('data:image/')) return null;
    final commaIdx = value.indexOf(',');
    if (commaIdx <= 0 || commaIdx >= value.length - 1) return null;
    try {
      return base64Decode(value.substring(commaIdx + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryBytes = tryDecodeDataUrl(source);
    final Widget imageWidget;
    if (memoryBytes != null) {
      imageWidget = Image.memory(
        memoryBytes,
        cacheWidth: 720,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, _, _) => _ErrorPlaceholder(height: height),
      );
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      imageWidget = Image.network(
        source,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, _, _) => _ErrorPlaceholder(height: height),
      );
    } else {
      imageWidget = _ErrorPlaceholder(height: height);
    }

    return ClipRRect(
      borderRadius: AppRadius.cardBorderRadius,
      child: imageWidget,
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.accentLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 36,
        color: AppColors.textSecondary,
      ),
    );
  }
}
