import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;

/// Открывает камеру или выбор изображения в браузере и сжимает фото сертификата
/// в компактный JPEG Data URL (`data:image/jpeg;base64,...`).
Future<String?> pickHalalCertPhoto({bool useCamera = false}) {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = 'image/*'
    ..style.display = 'none';

  if (useCamera) {
    input.setAttribute('capture', 'environment');
  }

  web.document.body?.append(input);

  void cleanup() {
    input.remove();
  }

  void completeOnce(String? result) {
    if (!completer.isCompleted) {
      cleanup();
      completer.complete(result);
    }
  }

  late final JSFunction onCancel;
  late final JSFunction onChange;

  onCancel = ((web.Event _) {
    completeOnce(null);
  }).toJS;

  onChange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completeOnce(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      completeOnce(null);
      return;
    }
    _compressImageFileToDataUrl(file).then(completeOnce).catchError((_) {
      completeOnce(null);
    });
  }).toJS;

  input.addEventListener('change', onChange);
  input.addEventListener('cancel', onCancel);
  input.click();

  return completer.future;
}

Future<String?> _compressImageFileToDataUrl(web.File file) async {
  final objectUrl = web.URL.createObjectURL(file);
  final image = web.HTMLImageElement();
  final loaded = Completer<bool>();

  image.onload = ((web.Event _) {
    if (!loaded.isCompleted) loaded.complete(true);
  }).toJS;
  image.onerror = ((web.Event _) {
    if (!loaded.isCompleted) loaded.complete(false);
  }).toJS;
  image.src = objectUrl;

  final ok = await loaded.future;
  web.URL.revokeObjectURL(objectUrl);

  if (!ok || image.width == 0 || image.height == 0) {
    return _readRawFileAsDataUrl(file);
  }

  const maxSide = 1080.0;
  final w = image.width.toDouble();
  final h = image.height.toDouble();
  final scale = math.min(1.0, maxSide / math.max(w, h));
  final targetW = math.max(1, (w * scale).round());
  final targetH = math.max(1, (h * scale).round());

  final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement
    ..width = targetW
    ..height = targetH;
  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
  if (ctx == null) {
    return _readRawFileAsDataUrl(file);
  }
  ctx.fillStyle = '#FFFFFF'.toJS;
  ctx.fillRect(0, 0, targetW.toDouble(), targetH.toDouble());
  ctx.drawImage(image, 0, 0, targetW.toDouble(), targetH.toDouble());

  return canvas.toDataURL('image/jpeg', 0.82.toJS);
}

Future<String?> _readRawFileAsDataUrl(web.File file) {
  final completer = Completer<String?>();
  final reader = web.FileReader();
  reader.onload = ((web.Event _) {
    final result = reader.result;
    if (!completer.isCompleted) {
      completer.complete(
        result.isA<JSString>() ? (result as JSString).toDart : null,
      );
    }
  }).toJS;
  reader.onerror = ((web.Event _) {
    if (!completer.isCompleted) completer.complete(null);
  }).toJS;
  reader.readAsDataURL(file);
  return completer.future;
}
