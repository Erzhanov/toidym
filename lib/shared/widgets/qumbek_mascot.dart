import 'package:flutter/material.dart';
import 'package:toidym/app/theme/app_colors.dart';
import 'package:toidym/shared/models/enums.dart';

enum QumbekMood {
  happy,
  tip,
  empty,
}

/// Плоская «стикерная» иллюстрация маскота Құмбек — барханного кота в очках.
///
/// ЖЁСТКОЕ ПРАВИЛО: глаза маскота и любых животных НИКОГДА не видны.
/// Очки всегда плотно закрывают область глаз.
///
/// // TODO asset: заменить на векторный/Lottie-ассет из брендбука при добавлении.
class QumbekMascot extends StatelessWidget {
  const QumbekMascot({
    super.key,
    this.size = 120,
    this.mood = QumbekMood.happy,
  });

  final double size;
  final QumbekMood mood;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Маскот Құмбек в солнечных очках',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _QumbekPainter(mood: mood),
        ),
      ),
    );
  }
}

class _QumbekPainter extends CustomPainter {
  _QumbekPainter({required this.mood});

  final QumbekMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Фон-стикер (мягкий жёлтый круг)
    final bgPaint = Paint()
      ..color = mood == QumbekMood.happy
          ? AppColors.accentLight
          : AppColors.primaryLight;
    canvas.drawCircle(Offset(w * 0.5, h * 0.53), w * 0.44, bgPaint);

    final furPaint = Paint()..color = AppColors.mascotSand;
    final furShadePaint = Paint()..color = AppColors.mascotSandDark;
    final earInnerPaint = Paint()..color = AppColors.mascotEarInner;

    // Широкие уши барханного кота
    final leftEar = Path()
      ..moveTo(w * 0.19, h * 0.42)
      ..lineTo(w * 0.14, h * 0.15)
      ..lineTo(w * 0.39, h * 0.27)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.81, h * 0.42)
      ..lineTo(w * 0.86, h * 0.15)
      ..lineTo(w * 0.61, h * 0.27)
      ..close();
    canvas.drawPath(leftEar, furPaint);
    canvas.drawPath(rightEar, furPaint);

    final leftEarInner = Path()
      ..moveTo(w * 0.21, h * 0.38)
      ..lineTo(w * 0.18, h * 0.20)
      ..lineTo(w * 0.35, h * 0.28)
      ..close();
    final rightEarInner = Path()
      ..moveTo(w * 0.79, h * 0.38)
      ..lineTo(w * 0.82, h * 0.20)
      ..lineTo(w * 0.65, h * 0.28)
      ..close();
    canvas.drawPath(leftEarInner, earInnerPaint);
    canvas.drawPath(rightEarInner, earInnerPaint);

    // Плечи / воротник в фирменном цвете индиго
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.84),
        width: w * 0.46,
        height: h * 0.22,
      ),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(bodyRect, Paint()..color = AppColors.primary);

    // Жёлтый значок-таг на ошейнике
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.83),
      w * 0.055,
      Paint()..color = AppColors.accent,
    );

    // Голова барханного кота (округлая, широкая в скулах)
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.50),
      width: w * 0.62,
      height: h * 0.50,
    );
    canvas.drawOval(headRect, furPaint);

    // Светлая мордочка внизу
    final muzzleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.59),
      width: w * 0.36,
      height: h * 0.22,
    );
    canvas.drawOval(muzzleRect, earInnerPaint);

    // Полоски на лбу (характерные для барханного кота)
    final stripePaint = Paint()
      ..color = AppColors.mascotSandDark
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.28),
      Offset(w * 0.50, h * 0.35),
      stripePaint,
    );
    canvas.drawLine(
      Offset(w * 0.42, h * 0.30),
      Offset(w * 0.44, h * 0.36),
      stripePaint,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.30),
      Offset(w * 0.56, h * 0.36),
      stripePaint,
    );

    // Солнечные очки (полностью непрозрачные — глаза НИКОГДА не рисуются)
    final glassesPaint = Paint()..color = AppColors.mascotGlasses;
    final glarePaint = Paint()
      ..color = AppColors.mascotGlassesGlare
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;

    final leftLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.21, h * 0.40, w * 0.25, h * 0.15),
      Radius.circular(w * 0.045),
    );
    final rightLens = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.54, h * 0.40, w * 0.25, h * 0.15),
      Radius.circular(w * 0.045),
    );
    canvas.drawRRect(leftLens, glassesPaint);
    canvas.drawRRect(rightLens, glassesPaint);

    // Переносица и дужки очков
    final framePaint = Paint()
      ..color = AppColors.mascotGlasses
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.45, h * 0.44),
      Offset(w * 0.55, h * 0.44),
      framePaint,
    );
    canvas.drawLine(
      Offset(w * 0.18, h * 0.43),
      Offset(w * 0.22, h * 0.44),
      framePaint,
    );
    canvas.drawLine(
      Offset(w * 0.78, h * 0.44),
      Offset(w * 0.82, h * 0.43),
      framePaint,
    );

    // Блики на линзах
    canvas.drawLine(
      Offset(w * 0.26, h * 0.43),
      Offset(w * 0.31, h * 0.50),
      glarePaint,
    );
    canvas.drawLine(
      Offset(w * 0.59, h * 0.43),
      Offset(w * 0.64, h * 0.50),
      glarePaint,
    );

    // Носик
    final nose = Path()
      ..moveTo(w * 0.47, h * 0.57)
      ..lineTo(w * 0.53, h * 0.57)
      ..lineTo(w * 0.50, h * 0.605)
      ..close();
    canvas.drawPath(nose, furShadePaint);

    // Улыбка
    final mouthPaint = Paint()
      ..color = AppColors.mascotGlasses
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(w * 0.43, h * 0.62)
      ..quadraticBezierTo(w * 0.47, h * 0.66, w * 0.50, h * 0.62)
      ..quadraticBezierTo(w * 0.53, h * 0.66, w * 0.57, h * 0.62);
    canvas.drawPath(smilePath, mouthPaint);

    // Усики
    final whiskerPaint = Paint()
      ..color = AppColors.mascotSandDark
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.22, h * 0.58),
      Offset(w * 0.33, h * 0.59),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.23, h * 0.63),
      Offset(w * 0.33, h * 0.62),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.78, h * 0.58),
      Offset(w * 0.67, h * 0.59),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(w * 0.77, h * 0.63),
      Offset(w * 0.67, h * 0.62),
      whiskerPaint,
    );

    // Звёздочка-искра радости для mood == happy
    if (mood == QumbekMood.happy) {
      final sparklePaint = Paint()..color = AppColors.accentDark;
      canvas.drawCircle(Offset(w * 0.84, h * 0.24), w * 0.032, sparklePaint);
      canvas.drawCircle(Offset(w * 0.16, h * 0.28), w * 0.022, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QumbekPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}

/// Иллюстрация жителя коллекции «Қызыл кітап» (силуэт или в очках, БЕЗ глаз).
///
/// // TODO asset: заменить на финальные иллюстрации животных из брендбука.
class QyzylKitapAnimalArt extends StatelessWidget {
  const QyzylKitapAnimalArt({
    required this.animal,
    required this.isUnlocked,
    super.key,
    this.size = 88,
  });

  final QyzylKitapAnimal animal;
  final bool isUnlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (animal == QyzylKitapAnimal.qumbek && isUnlocked) {
      return QumbekMascot(size: size, mood: QumbekMood.happy);
    }
    return Semantics(
      image: true,
      label: isUnlocked ? animal.apiValue : 'Закрытый силуэт ${animal.apiValue}',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _AnimalSilhouettePainter(
            animal: animal,
            isUnlocked: isUnlocked,
          ),
        ),
      ),
    );
  }
}

class _AnimalSilhouettePainter extends CustomPainter {
  _AnimalSilhouettePainter({
    required this.animal,
    required this.isUnlocked,
  });

  final QyzylKitapAnimal animal;
  final bool isUnlocked;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.45,
      Paint()
        ..color = isUnlocked ? AppColors.primaryLight : AppColors.surfaceVariant,
    );

    final silhouetteColor =
        isUnlocked ? AppColors.primary : AppColors.silhouetteLocked;
    final paint = Paint()..color = silhouetteColor;

    switch (animal) {
      case QyzylKitapAnimal.qumbek:
      case QyzylKitapAnimal.irbis:
        // Силуэт барса/кота (голова + уши, без глаз)
        final leftEar = Path()
          ..moveTo(w * 0.25, h * 0.46)
          ..lineTo(w * 0.22, h * 0.24)
          ..lineTo(w * 0.42, h * 0.34)
          ..close();
        final rightEar = Path()
          ..moveTo(w * 0.75, h * 0.46)
          ..lineTo(w * 0.78, h * 0.24)
          ..lineTo(w * 0.58, h * 0.34)
          ..close();
        canvas.drawPath(leftEar, paint);
        canvas.drawPath(rightEar, paint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.54),
            width: w * 0.54,
            height: h * 0.44,
          ),
          paint,
        );
      case QyzylKitapAnimal.saigak:
        // Силуэт сайгака (рога + вытянутый профиль, без глаз)
        final hornPaint = Paint()
          ..color = silhouetteColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045
          ..strokeCap = StrokeCap.round;
        final leftHorn = Path()
          ..moveTo(w * 0.40, h * 0.36)
          ..quadraticBezierTo(w * 0.34, h * 0.20, w * 0.42, h * 0.14);
        final rightHorn = Path()
          ..moveTo(w * 0.60, h * 0.36)
          ..quadraticBezierTo(w * 0.66, h * 0.20, w * 0.58, h * 0.14);
        canvas.drawPath(leftHorn, hornPaint);
        canvas.drawPath(rightHorn, hornPaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.54),
            width: w * 0.40,
            height: h * 0.44,
          ),
          paint,
        );
      case QyzylKitapAnimal.seal:
        // Силуэт каспийского тюленя (обтекаемый силуэт, без глаз)
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.56),
            width: w * 0.58,
            height: h * 0.40,
          ),
          paint,
        );
        canvas.drawCircle(Offset(w * 0.44, h * 0.40), w * 0.17, paint);
    }

    // Если животное открыто — надеваем стильные очки (никаких глаз!).
    if (isUnlocked) {
      final glassPaint = Paint()..color = AppColors.mascotGlasses;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.44, w * 0.19, h * 0.11),
          Radius.circular(w * 0.03),
        ),
        glassPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.53, h * 0.44, w * 0.19, h * 0.11),
          Radius.circular(w * 0.03),
        ),
        glassPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(w * 0.46, h * 0.47, w * 0.08, h * 0.03),
        glassPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimalSilhouettePainter oldDelegate) {
    return oldDelegate.animal != animal || oldDelegate.isUnlocked != isUnlocked;
  }
}
