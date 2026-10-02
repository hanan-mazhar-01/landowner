import 'package:flutter/widgets.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/icons/homely_icon.dart';

/// 3D portfolio and financial intelligence visual for Onboarding Screen 5.
/// Showcases the multi-property portfolio, total value HUD, cash flow trajectory,
/// and calm AI portfolio insight.
class OnboardingPortfolioFinancialVisual extends StatefulWidget {
  const OnboardingPortfolioFinancialVisual({super.key});

  @override
  State<OnboardingPortfolioFinancialVisual> createState() =>
      _OnboardingPortfolioFinancialVisualState();
}

class _OnboardingPortfolioFinancialVisualState
    extends State<OnboardingPortfolioFinancialVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final curve = AppMotion.standard;

        // Staggered transitions
        final stackProgress = Interval(0.0, 0.45, curve: curve).transform(t);
        final valueProgress = Interval(0.25, 0.65, curve: curve).transform(t);
        final chartProgress = Interval(0.45, 0.85, curve: AppMotion.draw).transform(t);
        final aiProgress = Interval(0.68, 1.0, curve: curve).transform(t);

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Ambient Radial Glow
                Positioned(
                  top: h * 0.12,
                  child: Container(
                    width: w * 0.8,
                    height: w * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.blue200.withValues(alpha: 0.35),
                          AppColors.blue100.withValues(alpha: 0.12),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Layer 1: Stepped 3D Property Mini-Deck (Top section)
                Positioned(
                  top: 8,
                  child: Opacity(
                    opacity: stackProgress.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - stackProgress) * 20),
                      child: SizedBox(
                        width: w * 0.85,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Tier 3: Marina Loft (Deepest layer)
                            Positioned(
                              top: 0,
                              child: Transform.scale(
                                scale: 0.88,
                                child: _MiniPropertyCard(
                                  title: 'Marina Loft',
                                  value: '\$400,000',
                                  units: '1 Unit',
                                  bgColor: AppColors.canvas,
                                  textColor: AppColors.textMuted,
                                ),
                              ),
                            ),
                            // Tier 2: Oakridge Villa (Middle layer)
                            Positioned(
                              top: 10,
                              child: Transform.scale(
                                scale: 0.94,
                                child: _MiniPropertyCard(
                                  title: 'Oakridge Villa',
                                  value: '\$1,200,000',
                                  units: '4 Units',
                                  bgColor: AppColors.blue50,
                                  textColor: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            // Tier 1: Skyline Penthouse (Foreground layer)
                            Positioned(
                              top: 20,
                              child: _MiniPropertyCard(
                                title: 'Skyline Penthouse',
                                value: '\$850,000',
                                units: '2 Units',
                                bgColor: AppColors.white,
                                textColor: AppColors.ink,
                                isPrimary: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Layer 2: Main Portfolio Financial Command Center HUD (Center)
                Positioned(
                  top: 76,
                  child: Opacity(
                    opacity: valueProgress.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - valueProgress) * 16),
                      child: Container(
                        width: w * 0.88,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.blue100, width: 1.5),
                          boxShadow: AppShadows.heroCard,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('TOTAL PORTFOLIO VALUE', style: AppType.overline),
                                    const SizedBox(height: 2),
                                    Text(
                                      '\$2,450,000',
                                      style: AppType.value40.copyWith(fontSize: 28),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.positiveTint,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const HomelyIcon(
                                        HomelyIcons.trendUp,
                                        size: 13,
                                        color: AppColors.positiveText,
                                        strokeWidth: 2.2,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+12.4%',
                                        style: AppType.caption12Bold.copyWith(
                                          color: AppColors.positiveText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Cash flow metrics row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _StatCell(
                                  label: 'Monthly Rent',
                                  value: '\$18,400',
                                  color: AppColors.primary,
                                ),
                                _StatCell(
                                  label: 'Expenses',
                                  value: '\$3,200',
                                  color: AppColors.textMuted,
                                ),
                                _StatCell(
                                  label: 'Net Cash Flow',
                                  value: '+\$15,200',
                                  color: AppColors.positiveText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Smooth Animated Cash Flow Curve
                            SizedBox(
                              height: 38,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _CashFlowCurvePainter(
                                  progress: chartProgress,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Layer 3: Subtle AI Insight Card (Bottom)
                Positioned(
                  top: 272,
                  child: Opacity(
                    opacity: aiProgress.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - aiProgress) * 12),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: w * 0.88),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.blue200.withValues(alpha: 0.8)),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.blue50,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Center(
                                child: HomelyIcon(
                                  HomelyIcons.sparkle,
                                  size: 13,
                                  color: AppColors.accent,
                                  strokeWidth: 2.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  style: AppType.caption.copyWith(color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(
                                      text: 'Portfolio Intelligence · ',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: 'Cash flow trending +8.2%',
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MiniPropertyCard extends StatelessWidget {
  const _MiniPropertyCard({
    required this.title,
    required this.value,
    required this.units,
    required this.bgColor,
    required this.textColor,
    this.isPrimary = false,
  });

  final String title;
  final String value;
  final String units;
  final Color bgColor;
  final Color textColor;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPrimary ? AppColors.blue200 : AppColors.border,
        ),
        boxShadow: isPrimary ? AppShadows.card : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              HomelyIcon(
                HomelyIcons.home,
                size: 14,
                color: isPrimary ? AppColors.primary : AppColors.textMuted,
                strokeWidth: 2.2,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppType.caption12Bold.copyWith(color: textColor),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: AppType.num(12, FontWeight.w800).copyWith(
                  color: isPrimary ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $units',
                style: AppType.micro.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.micro.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppType.num(13, FontWeight.w800).copyWith(color: color),
        ),
      ],
    );
  }
}

/// Draws an elegant animated bezier performance cash flow curve.
class _CashFlowCurvePainter extends CustomPainter {
  _CashFlowCurvePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;

    // Control points for organic upward curve
    final p0 = Offset(0, h * 0.85);
    final p1 = Offset(w * 0.25, h * 0.7);
    final p2 = Offset(w * 0.55, h * 0.45);
    final p3 = Offset(w * 0.8, h * 0.5);
    final p4 = Offset(w, h * 0.15);

    final path = Path()..moveTo(p0.dx, p0.dy);

    // Approximate bezier path
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
    path.quadraticBezierTo(w * 0.9, h * 0.3, p4.dx, p4.dy);

    // Measure path for progressive drawing
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final currentLength = metric.length * progress;
    final extractedPath = metric.extractPath(0, currentLength);

    // Gradient fill under the curve
    final fillPath = Path.from(extractedPath)
      ..lineTo(extractedPath.getBounds().right, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue400.withValues(alpha: 0.18),
          AppColors.blue400.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.blue400, AppColors.blue600],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractedPath, linePaint);

    // End pulse node
    if (progress > 0.9) {
      final tangent = metric.getTangentForOffset(currentLength);
      if (tangent != null) {
        final nodeCenter = tangent.position;

        final haloPaint = Paint()
          ..color = AppColors.blue400.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nodeCenter, 7, haloPaint);

        final dotPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(nodeCenter, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CashFlowCurvePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
