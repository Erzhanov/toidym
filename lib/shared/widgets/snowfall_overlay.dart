import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';

/// Виджет падающего снега (зимняя атмосфера Астаны), ненавязчивый оверлей
/// с нулевым влиянием на интерактивность (клики свободно проходят сквозь снег).
class SnowfallOverlay extends ConsumerStatefulWidget {
  const SnowfallOverlay({
    super.key,
    required this.child,
    this.numberOfFlakes = 70,
  });

  final Widget child;
  final int numberOfFlakes;

  @override
  ConsumerState<SnowfallOverlay> createState() => _SnowfallOverlayState();
}

class _SnowfallOverlayState extends ConsumerState<SnowfallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Snowflake> _flakes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    final random = math.Random();
    _flakes = List.generate(
      widget.numberOfFlakes,
      (_) => _Snowflake.random(random),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(snowfallEnabledProvider);

    if (!enabled) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return widget.child;
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SnowPainter(
                      progress: _controller.value,
                      flakes: _flakes,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Snowflake {
  _Snowflake({
    required this.x,
    required this.y,
    required this.radius,
    required this.fallSpeed,
    required this.driftSpeed,
    required this.driftAmplitude,
    required this.phase,
    required this.opacity,
    required this.isStar,
  });

  factory _Snowflake.random(math.Random random) {
    final isLarge = random.nextDouble() < 0.22;
    final isStar = isLarge && random.nextBool();
    return _Snowflake(
      x: random.nextDouble(),
      y: random.nextDouble(),
      radius: isLarge ? 2.8 + random.nextDouble() * 1.5 : 1.2 + random.nextDouble() * 1.6,
      fallSpeed: 0.0012 + random.nextDouble() * 0.0028,
      driftSpeed: 1.2 + random.nextDouble() * 2.2,
      driftAmplitude: 0.012 + random.nextDouble() * 0.024,
      phase: random.nextDouble() * 2 * math.pi,
      opacity: 0.45 + random.nextDouble() * 0.5,
      isStar: isStar,
    );
  }

  double x;
  double y;
  final double radius;
  final double fallSpeed;
  final double driftSpeed;
  final double driftAmplitude;
  final double phase;
  final double opacity;
  final bool isStar;
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({
    required this.progress,
    required this.flakes,
  });

  final double progress;
  final List<_Snowflake> flakes;

  static final Paint _haloPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x332B2350); // Тонкий мягкий индиго-ореол для контраста на кремовом фоне

  static final Paint _flakePaint = Paint()..style = PaintingStyle.fill;

  static final Paint _starPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final flake in flakes) {
      // Обновляем позицию по вертикали
      final currentY = ((flake.y + flake.fallSpeed * (progress * 600)) % 1.0) * size.height;

      // Плавное горизонтальное покачивание (ветер/дрейф снежинки)
      final sway = math.sin(flake.phase + progress * 2 * math.pi * flake.driftSpeed) *
          flake.driftAmplitude *
          size.width;
      final currentX = ((flake.x * size.width + sway) % size.width + size.width) % size.width;

      final flakeCenter = Offset(currentX, currentY);

      if (flake.isStar) {
        // Кристаллическая звездообразная снежинка
        _starPaint
          ..color = Colors.white.withValues(alpha: flake.opacity)
          ..strokeWidth = 1.2;

        final arm = flake.radius * 1.4;

        // Рисуем мягкую тень
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0
          ..color = const Color(0x2B235026);

        _drawStar(canvas, flakeCenter, arm, shadowPaint);
        _drawStar(canvas, flakeCenter, arm, _starPaint);
      } else {
        // Мягкая пушистая круглая снежинка с микро-контрастом
        canvas.drawCircle(flakeCenter, flake.radius + 0.6, _haloPaint);

        _flakePaint.color = Colors.white.withValues(alpha: flake.opacity);
        canvas.drawCircle(flakeCenter, flake.radius, _flakePaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double arm, Paint paint) {
    // 6 лучей снежинки
    for (var i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      final dx = math.cos(angle) * arm;
      final dy = math.sin(angle) * arm;
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
}
