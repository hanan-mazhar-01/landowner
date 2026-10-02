import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_decor.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/pressable.dart';

/// Draws SVG path data (in a [viewBox]-sized square) scaled to the canvas.
class _SvgLogoPainter extends CustomPainter {
  const _SvgLogoPainter(this.parts, this.viewBox);

  /// (path data, colour) pairs, painted in order.
  final List<(String, Color)> parts;
  final double viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / viewBox;
    canvas.scale(s, s);
    for (final (d, color) in parts) {
      canvas.drawPath(parseSvgPathData(d), Paint()..color = color..isAntiAlias = true);
    }
  }

  @override
  bool shouldRepaint(covariant _SvgLogoPainter old) => old.parts != parts;
}

/// The official four-colour Google "G".
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  static const _parts = [
    ('M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z', Color(0xFFEA4335)),
    ('M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z', Color(0xFF4285F4)),
    ('M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z', Color(0xFFFBBC05)),
    ('M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z', Color(0xFF34A853)),
  ];

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: const CustomPaint(painter: _SvgLogoPainter(_parts, 48)));
}

/// The Apple logo (single colour).
class AppleLogo extends StatelessWidget {
  const AppleLogo({super.key, this.size = 20, this.color = AppColors.white});
  final double size;
  final Color color;

  static const _d =
      'M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 '
      '12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 '
      '2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 '
      '2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 '
      '1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 '
      '3.559-1.701';

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _SvgLogoPainter([(_d, color)], 24)));
}

/// Google and Apple sign-in side by side, equal size, under an "or" divider.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.busy = false,
  });

  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            semanticLabel: 'Continue with Google',
            logo: const GoogleLogo(size: 20),
            onTap: busy ? null : onGoogleTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Apple',
            semanticLabel: 'Continue with Apple',
            logo: const AppleLogo(size: 20, color: Color(0xFF000000)),
            onTap: busy ? null : onAppleTap,
          ),
        ),
      ]),
    ]);
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.semanticLabel, required this.logo, required this.onTap});

  final String label, semanticLabel;
  final Widget logo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap ?? () {},
        semanticLabel: semanticLabel,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: AppShadows.card,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            logo,
            const SizedBox(width: 10),
            Text(label, style: AppType.label14.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
