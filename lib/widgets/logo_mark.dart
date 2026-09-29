import 'package:flutter/material.dart';

/// Edge length of the grid the logo is drawn on.
const logoGrid = 100.0;
const _strokeWidth = 11.0;

/// The ring: an open circle, its gap at the top right. Same geometry as
/// `assets/logo/logo.svg`.
Path logoRingPath() => Path()
  ..moveTo(78, 26)
  ..arcToPoint(
    const Offset(84, 60),
    radius: const Radius.circular(36),
    largeArc: true,
    clockwise: false,
  );

/// The check: it starts inside the ring and leaves through the gap.
Path logoCheckPath() => Path()
  ..moveTo(34, 52)
  ..lineTo(50, 68)
  ..lineTo(90, 22);

/// The Done logo, a check that breaks out of its circle.
///
/// [ringProgress] and [checkProgress] (0 to 1) control how much of each
/// stroke is drawn, which the splash screen uses to animate the mark.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    required this.size,
    required this.ringColor,
    required this.checkColor,
    this.ringProgress = 1,
    this.checkProgress = 1,
  });

  final double size;
  final Color ringColor;
  final Color checkColor;
  final double ringProgress;
  final double checkProgress;

  /// Ring and check coloured for the current theme.
  factory LogoMark.themed(
    BuildContext context, {
    required double size,
    double ringProgress = 1,
    double checkProgress = 1,
  }) {
    final cs = Theme.of(context).colorScheme;
    return LogoMark(
      size: size,
      ringColor: cs.onSurface,
      checkColor: cs.primary,
      ringProgress: ringProgress,
      checkProgress: checkProgress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo Done',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _LogoPainter(
              ringColor: ringColor,
              checkColor: checkColor,
              ringProgress: ringProgress,
              checkProgress: checkProgress,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.ringColor,
    required this.checkColor,
    required this.ringProgress,
    required this.checkProgress,
  });

  final Color ringColor;
  final Color checkColor;
  final double ringProgress;
  final double checkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / logoGrid, size.height / logoGrid);
    _stroke(canvas, logoRingPath(), ringColor, ringProgress);
    _stroke(canvas, logoCheckPath(), checkColor, checkProgress);
  }

  void _stroke(Canvas canvas, Path path, Color color, double progress) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.ringColor != ringColor ||
      old.checkColor != checkColor ||
      old.ringProgress != ringProgress ||
      old.checkProgress != checkProgress;
}
