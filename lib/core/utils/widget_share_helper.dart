import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Утилита экспорта `RepaintBoundary` в PNG-изображение с шэрингом через `share_plus`.
abstract final class WidgetShareHelper {
  /// Захватывает [boundaryKey] в PNG и открывает системный шэринг с [text].
  /// Если платформенный шэринг недоступен (например, в headless-тесте),
  /// копирует текст в буфер обмена и возвращает `false`.
  static Future<bool> shareBoundaryAsPng({
    required GlobalKey boundaryKey,
    required String text,
    String fileName = 'toidym_card.png',
  }) async {
    try {
      final renderObj = boundaryKey.currentContext?.findRenderObject();
      if (renderObj is RenderRepaintBoundary) {
        final image = await renderObj.toImage(pixelRatio: 2.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          final xFile = XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          );
          await SharePlus.instance.share(
            ShareParams(
              files: [xFile],
              text: text,
            ),
          );
          return true;
        }
      }
      await SharePlus.instance.share(ShareParams(text: text));
      return true;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    }
  }
}
