import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/pressable.dart';
import '../../../shared/data/seed/seed_portfolio.dart';
import 'auth_providers.dart';
import 'widgets/onboarding_portfolio_financial_visual.dart';

class _Slide {
  const _Slide(
    this.image,
    this.lead,
    this.accent,
    this.body, {
    this.customVisual,
  });
  final String image, lead, accent, body;
  final Widget? customVisual;
}

/// Welcome + onboarding: the design's welcome layout as a 5-slide pager.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static final _slides = [
    _Slide(
      unsplash('photo-1600585154340-be6161a56a0c', w: 900),
      'Everything you own, ',
      'in one calm place.',
      'Value, rent, tenants and upkeep for every property — with an assistant that explains your numbers.',
    ),
    _Slide(
      unsplash('photo-1545324418-cc1a3fa10c00', w: 900),
      'Rent that ',
      'reminds itself.',
      'Every lease schedules its own reminders. Overdue rent arrives with Call, Message and Email one tap away.',
    ),
    _Slide(
      unsplash('photo-1486406146926-c627a92ad1ab', w: 900),
      'Numbers that ',
      'explain themselves.',
      'Cash flow, yield and costs update the moment you record them — and Intelligence tells you what changed.',
    ),
    _Slide(
      '',
      'See the ',
      'bigger picture.',
      'Understand your rental income, expenses, cash flow, and portfolio performance at a glance.',
      customVisual: const OnboardingPortfolioFinancialVisual(),
    ),
  ];

  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: AppMotion.standard,
      );
    } else {
      _start();
    }
  }

  void _start() {
    ref.read(onboardingSeenProvider.notifier).markSeen();
    context.push(Routes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLastPage = _page == _slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
          ),
          Positioned(top: MediaQuery.paddingOf(context).top + 20, left: 28, child: const _GlassBrand()),
          Positioned(
            left: 28,
            right: 28,
            bottom: bottom + 24,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                for (var i = 0; i < _slides.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: Motion.of(context, AppMotion.transition),
                    curve: AppMotion.standard,
                    width: i == _page ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.accent : AppColors.dotInactive,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 28),
              GradientCta(
                label: isLastPage ? 'Get started' : 'Continue',
                height: 58,
                padding: 22,
                style: AppType.button,
                shadow: AppShadows.cta,
                onTap: isLastPage ? _start : _next,
              ),
              Pressable(
                onTap: () => context.push(Routes.signIn),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text.rich(TextSpan(
                      style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                      children: const [
                        TextSpan(text: 'I already have an account · '),
                        TextSpan(text: 'Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    )),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCustom = slide.customVisual != null;
    final visualHeight = isCustom
        ? (screenHeight * 0.44).clamp(310.0, 400.0)
        : (screenHeight * 0.52).clamp(380.0, 520.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: visualHeight,
          child: isCustom
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.surface,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                    slide.customVisual!,
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(slide.image),
                    const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.welcome)),
                  ],
                ),
        ),
        Transform.translate(
          offset: Offset(0, isCustom ? 0 : -64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(style: AppType.welcome, children: [
                TextSpan(text: slide.lead),
                TextSpan(text: slide.accent, style: const TextStyle(color: AppColors.accent)),
              ])),
              const SizedBox(height: 14),
              Text(slide.body, style: AppType.body15),
            ]),
          ),
        ),
      ],
    );
  }
}

class _GlassBrand extends StatelessWidget {
  const _GlassBrand();

  @override
  Widget build(BuildContext context) => Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white.withValues(alpha: .35)),
              ),
              child: const Center(child: HomelyIcon(HomelyIcons.home, size: 18, color: AppColors.white, strokeWidth: 2.2)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('LandOwner', style: AppType.brand.copyWith(color: AppColors.white, letterSpacing: -.4)),
      ]);
}

/// Brand mark used by the splash and auth screens.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(gradient: AppGradients.cta, borderRadius: BorderRadius.circular(size * .32)),
          child: Center(
            child: HomelyIcon(HomelyIcons.home, size: size * .53, color: AppColors.white, strokeWidth: 2.2),
          ),
        ),
        const SizedBox(width: 10),
        Text('LandOwner', style: AppType.brand.copyWith(fontSize: size * .59)),
      ]);
}
