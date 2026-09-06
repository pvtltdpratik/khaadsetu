import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Score band a soil health reading falls into. Shared by [SoilHealthGauge]
/// and any other widget (e.g. the home summary card) that needs to describe
/// a score in words/color without re-guessing the cutoffs.
enum SoilHealthBand {
  needsAttention,
  fair,
  healthy;

  /// Null score (no scan yet) has no band.
  static SoilHealthBand? fromScore(double? score) {
    if (score == null) return null;
    if (score < 40) return SoilHealthBand.needsAttention;
    if (score < 70) return SoilHealthBand.fair;
    return SoilHealthBand.healthy;
  }

  String get label => switch (this) {
        SoilHealthBand.needsAttention => 'Needs attention',
        SoilHealthBand.fair => 'Fair',
        SoilHealthBand.healthy => 'Healthy',
      };

  Color color(AppColorTokens colors) => switch (this) {
        SoilHealthBand.needsAttention => colors.danger,
        SoilHealthBand.fair => colors.warning,
        SoilHealthBand.healthy => colors.success,
      };
}

/// Circular ring gauge for a 0-100 soil health score, color-banded
/// red/yellow/green. Pass [score] as null for the empty/"no scan yet" state
/// — used on the Phase 2 home summary before a farmer has scanned, and swapped
/// for a real score once the soil-scan flow (Phase 3) produces one.
///
/// [size] is caller-supplied rather than fixed, so the same widget reads as a
/// compact summary chip on mobile and a larger hero gauge on tablet/desktop —
/// pass `context.responsive(mobile: 120, tablet: 160)` at the call site.
class SoilHealthGauge extends StatelessWidget {
  const SoilHealthGauge({
    super.key,
    required this.size,
    this.score,
    this.label = 'Soil Health',
    this.strokeWidth = 12,
  });

  /// 0-100. Null renders the empty/placeholder state.
  final double? score;
  final double size;
  final String label;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clamped = score?.clamp(0, 100).toDouble();
    final ringColor = _colorForScore(clamped, colors);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _GaugePainter(
              progress: (clamped ?? 0) / 100,
              trackColor: colors.surfaceSunken,
              progressColor: ringColor,
              strokeWidth: strokeWidth,
              isEmpty: clamped == null,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clamped == null ? '--' : clamped.round().toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: size * 0.22,
                      color: clamped == null ? colors.textMuted : ringColor,
                    ),
              ),
              SizedBox(height: size * 0.02),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: (size * 0.075).clamp(10, 13),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorForScore(double? score, AppColorTokens colors) {
    final band = SoilHealthBand.fromScore(score);
    return band == null ? colors.textMuted : band.color(colors);
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.isEmpty,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final bool isEmpty;

  static const _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (isEmpty) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.isEmpty != isEmpty;
}

/// Compact legend explaining the gauge's color bands. Optional — drop under
/// a [SoilHealthGauge] on screens with room (tablet/desktop cards, the
/// Phase 3 result screen) rather than in tight mobile summaries.
class SoilHealthLegend extends StatelessWidget {
  const SoilHealthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: colors.textMuted);

    Widget dot(Color color, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(text, style: style),
          ],
        );

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        dot(colors.danger, 'Needs attention'),
        dot(colors.warning, 'Fair'),
        dot(colors.success, 'Healthy'),
      ],
    );
  }
}
