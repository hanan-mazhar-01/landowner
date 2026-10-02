import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_decor.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/icons/homely_icon.dart';
import '../../../core/services/notification_permission.dart';
import '../../../core/utils/regions.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/pressable.dart';
import '../../../shared/forms/fields/text_fields.dart';
import 'auth_providers.dart';

enum _LocationState {
  initial,
  loading,
  confirmation,
  manual,

  /// Final onboarding step: turn on reminders.
  notifications,
}

class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  ConsumerState<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> with SingleTickerProviderStateMixin {
  _LocationState _state = _LocationState.initial;
  String _detectedCity = 'Lahore';
  String _detectedCountry = 'Pakistan';
  String _detectedCurrencyCode = 'PKR';
  String _detectedCurrencySymbol = 'Rs';
  String _manualCity = '';
  String _manualCountry = 'Pakistan';
  String _manualCurrencyCode = 'PKR';
  String _manualCurrencySymbol = 'Rs';

  bool _isSaving = false;

  late final AnimationController _pulseController;

  static final _currencies = [
    for (final c in Regions.currencies) {'code': c.code, 'symbol': c.symbol, 'name': c.name},
  ];

  static final _countries = Regions.countryNames;

  /// Shown above the manual form, e.g. when location access was declined.
  String? _notice;

  void _useCountry(String name) {
    _manualCountry = _countries.contains(name) ? name : 'Other';
    final cur = Regions.currency(Regions.countryByName(name)?.currency ?? '');
    if (cur != null) {
      _manualCurrencyCode = cur.code;
      _manualCurrencySymbol = cur.symbol;
    }
  }

  void _goManual(String? notice) {
    if (!mounted) return;
    setState(() {
      _notice = notice;
      _state = _LocationState.manual;
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Asks for the device location (system prompt). Allowed → reverse-geocode
  /// to city / country and suggest that country's currency. Declined or
  /// unavailable → the manual form.
  Future<void> _detectLocation() async {
    setState(() => _state = _LocationState.loading);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _goManual('Location services are off. Choose your country and currency below.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return _goManual('No problem — choose your country and currency below.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
      final places = await Geocoding(locale: const Locale('en'))
          .placemarkFromCoordinates(position.latitude, position.longitude);
      final place = places.isEmpty ? null : places.first;
      final known = Regions.countryByIso(place?.isoCountryCode);
      final country = known?.name ?? place?.country?.trim() ?? '';
      final city = [
        place?.locality,
        place?.subAdministrativeArea,
        place?.administrativeArea,
      ].firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => '')!.trim();
      final currency = Regions.currency(known?.currency ?? '');

      if (country.isEmpty || currency == null) {
        // Found the place but not a currency we support: prefill what we know.
        if (mounted) {
          setState(() {
            _manualCity = city;
            if (country.isNotEmpty) _useCountry(country);
          });
        }
        return _goManual('Choose the currency you use for your properties.');
      }

      if (mounted) {
        setState(() {
          _detectedCity = city.isEmpty ? country : city;
          _detectedCountry = country;
          _detectedCurrencyCode = currency.code;
          _detectedCurrencySymbol = currency.symbol;
          _manualCity = city;
          _useCountry(country);
          _state = _LocationState.confirmation;
        });
      }
    } catch (e) {
      debugPrint('Location setup: $e');
      _goManual('Couldn\u2019t get your location. Choose your country and currency below.');
    }
  }

  Future<void> _saveAndEnterApp({
    required String city,
    required String currencyCode,
    required String currencySymbol,
  }) async {
    setState(() => _isSaving = true);
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref
            .read(authRepositoryProvider)
            .updateProfile(
              name: user.name,
              email: user.email,
              phone: user.phone,
              avatarUrl: user.avatarUrl,
              city: city.trim(),
              currencyCode: currencyCode,
              currencySymbol: currencySymbol,
            );
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isSaving = false;
        _state = _LocationState.notifications;
      });
    }
  }

  void _skip() {
    if (_state == _LocationState.notifications) {
      _finishNotifications(allow: false);
      return;
    }
    setState(() => _state = _LocationState.notifications);
  }

  Future<void> _finishNotifications({required bool allow}) async {
    if (allow) {
      await NotificationPermission.request();
    } else {
      await NotificationPermission.decline();
    }
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final isCompact = size.height < 700;
    final visualHeight = (size.height * 0.25).clamp(130.0, 220.0);
    final horizontalPad = (size.width * 0.07).clamp(20.0, 28.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Top Bar with Skip for now
              Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppGradients.cta,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: HomelyIcon(HomelyIcons.home, size: 16, color: AppColors.white, strokeWidth: 2.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('LandOwner', style: AppType.brand.copyWith(fontSize: 18)),
                      ],
                    ),
                    Pressable(
                      onTap: _skip,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('Skip for now', style: AppType.button15.copyWith(color: AppColors.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Positioned.fill(
                top: 56,
                bottom: bottom + 20 + viewInsets,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: Column(
                    children: [
                      SizedBox(height: isCompact ? 8 : 16),

                      // 3D Spatial Globe Visual
                      SizedBox(
                        height: visualHeight,
                        width: double.infinity,
                        child: _state == _LocationState.notifications
                            ? const _BellVisual()
                            : AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) => _SpatialGlobeVisual(
                                  pulse: _pulseController.value,
                                  currencySymbol: _state == _LocationState.confirmation
                                      ? _detectedCurrencySymbol
                                      : _manualCurrencySymbol,
                                ),
                              ),
                      ),
                      SizedBox(height: isCompact ? 14 : 20),

                      // Headline and Supporting Text
                      Text(
                        switch (_state) {
                          _LocationState.confirmation => 'Looks right?',
                          _LocationState.notifications => 'Never miss a rent day.',
                          _ => 'Set up LandOwner for you.',
                        },
                        style: isCompact ? AppType.title28.copyWith(fontSize: 24) : AppType.title28,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        switch (_state) {
                          _LocationState.confirmation => 'We set your region and currency from your location. You can change them anytime in Settings.',
                          _LocationState.notifications => 'Get a reminder before rent is due, when a payment is late, and before leases, insurance or documents expire.',
                          _ => 'Allow location to set your city and currency automatically, or choose them yourself.',
                        },
                        style: isCompact ? AppType.body15.copyWith(fontSize: 14) : AppType.body15,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isCompact ? 18 : 28),

                      // State-specific layout
                      if (_state == _LocationState.initial) ...[
                        GradientCta(label: 'Use My Location', height: 58, onTap: _detectLocation),
                        const SizedBox(height: 14),
                        Pressable(
                          onTap: () => setState(() => _state = _LocationState.manual),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(AppRadius.cta),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.card,
                            ),
                            child: Center(
                              child: Text('Choose Manually', style: AppType.button.copyWith(color: AppColors.ink)),
                            ),
                          ),
                        ),

                      ] else if (_state == _LocationState.loading) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.blue100),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: HomelyIcon(
                                  HomelyIcons.sparkle,
                                  size: 24,
                                  color: AppColors.primary,
                                  strokeWidth: 2.2,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Personalizing regional settings…',
                                style: AppType.caption12Bold.copyWith(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_state == _LocationState.confirmation) ...[
                        // Confirmation Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.blue200, width: 1.5),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.blue50,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: const Center(
                                      child: HomelyIcon(
                                        HomelyIcons.pin,
                                        size: 18,
                                        color: AppColors.primary,
                                        strokeWidth: 2.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('REGION & CITY', style: AppType.overline),
                                        const SizedBox(height: 2),
                                        Text('$_detectedCity, $_detectedCountry', style: AppType.cardTitle),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const SizedBox(height: 1, child: ColoredBox(color: AppColors.dividerSoft)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.positiveTint,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _detectedCurrencySymbol,
                                        style: AppType.num(14, FontWeight.w800).copyWith(color: AppColors.positiveText),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('SUGGESTED CURRENCY', style: AppType.overline),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$_detectedCurrencyCode — $_detectedCurrencySymbol',
                                          style: AppType.cardTitle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientCta(
                          label: _isSaving ? 'Saving…' : 'Continue',
                          height: 58,
                          onTap: _isSaving
                              ? null
                              : () => _saveAndEnterApp(
                                  city: '$_detectedCity, $_detectedCountry',
                                  currencyCode: _detectedCurrencyCode,
                                  currencySymbol: _detectedCurrencySymbol,
                                ),
                        ),
                        const SizedBox(height: 12),
                        Pressable(
                          onTap: () => setState(() => _state = _LocationState.manual),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Change details manually',
                              style: AppType.button15.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ] else if (_state == _LocationState.manual) ...[
                        if (_notice != null) ...[
                          Text(
                            _notice!,
                            textAlign: TextAlign.center,
                            style: AppType.body15.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Manual Setup Form
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Country', style: AppType.label13),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(AppRadius.input),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _countries.contains(_manualCountry) ? _manualCountry : _countries.first,
                                    isExpanded: true,
                                    icon: const HomelyIcon(
                                      HomelyIcons.chevronRight,
                                      size: 14,
                                      color: AppColors.chevron,
                                      strokeWidth: 2,
                                    ),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _useCountry(val));
                                    },
                                    items: _countries
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c, style: AppType.input),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text('City / Region', style: AppType.label13),
                              const SizedBox(height: 6),
                              HomelyTextField(
                                value: _manualCity,
                                placeholder: 'e.g. Lahore, Karachi, Dubai',
                                onChanged: (v) => _manualCity = v,
                              ),
                              const SizedBox(height: 14),
                              Text('Currency', style: AppType.label13),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(AppRadius.input),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _manualCurrencyCode,
                                    isExpanded: true,
                                    icon: const HomelyIcon(
                                      HomelyIcons.chevronRight,
                                      size: 14,
                                      color: AppColors.chevron,
                                      strokeWidth: 2,
                                    ),
                                    onChanged: (code) {
                                      if (code != null) {
                                        final item = _currencies.firstWhere((c) => c['code'] == code);
                                        setState(() {
                                          _manualCurrencyCode = item['code']!;
                                          _manualCurrencySymbol = item['symbol']!;
                                        });
                                      }
                                    },
                                    items: _currencies
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c['code'],
                                            child: Text(
                                              '${c['code']} (${c['symbol']}) — ${c['name']}',
                                              style: AppType.input,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientCta(
                          label: _isSaving ? 'Saving…' : 'Save & Continue',
                          height: 58,
                          onTap: _isSaving
                              ? null
                              : () => _saveAndEnterApp(
                                  city: _manualCity.isEmpty ? _manualCountry : '$_manualCity, $_manualCountry',
                                  currencyCode: _manualCurrencyCode,
                                  currencySymbol: _manualCurrencySymbol,
                                ),
                        ),
                      ] else if (_state == _LocationState.notifications) ...[
                        GradientCta(
                          label: 'Allow notifications',
                          height: 58,
                          onTap: () => _finishNotifications(allow: true),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'You can change this anytime in Settings → Notifications.',
                          textAlign: TextAlign.center,
                          style: AppType.caption.copyWith(color: AppColors.textFaint),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A spatial 3D Globe with concentric longitude/latitude rings, atmospheric corona glow,
/// and subtle floating currency beacon.
class _SpatialGlobeVisual extends StatelessWidget {
  const _SpatialGlobeVisual({required this.pulse, required this.currencySymbol});

  final double pulse;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final globeDiameter = (h * 0.64).clamp(90.0, 140.0);
        final coronaSize = (globeDiameter * 1.25 + (pulse * 8)).clamp(110.0, 180.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Atmospheric Corona
            Container(
              width: coronaSize,
              height: coronaSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue400.withValues(alpha: 0.22),
                    AppColors.blue200.withValues(alpha: 0.08),
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),

            // Globe Body & Coordinate Grid
            CustomPaint(
              size: Size(globeDiameter, globeDiameter),
              painter: _GlobePainter(pulse: pulse),
            ),

            // Pulsing Location Beacon Pin
            Positioned(
              top: h * 0.22,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppGradients.cta,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.pin,
                ),
                child: const HomelyIcon(HomelyIcons.pin, size: 16, color: AppColors.white, strokeWidth: 2.2),
              ),
            ),

            // Floating Currency Token
            Positioned(
              right: (w * 0.22).clamp(16.0, 90.0),
              bottom: (h * 0.16).clamp(10.0, 40.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.blue200),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(currencySymbol, style: AppType.caption12Bold.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Globe Base sphere with lighting
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: [AppColors.blue50, AppColors.blue100.withValues(alpha: 0.8), AppColors.blue200.withValues(alpha: 0.5)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, spherePaint);

    // Globe Border
    final borderPaint = Paint()
      ..color = AppColors.blue300.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius, borderPaint);

    // Latitude rings
    final ringPaint = Paint()
      ..color = AppColors.blue400.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Equator and Parallels
    canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.7), ringPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - radius * 0.4), width: radius * 1.6, height: radius * 0.45),
      ringPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.4), width: radius * 1.6, height: radius * 0.45),
      ringPaint,
    );

    // Longitude Meridian
    canvas.drawOval(Rect.fromCenter(center: center, width: radius * 0.7, height: radius * 2), ringPaint);
  }

  @override
  bool shouldRepaint(covariant _GlobePainter oldDelegate) => oldDelegate.pulse != pulse;
}

/// Notifications step visual: the brand tile with a bell.
class _BellVisual extends StatelessWidget {
  const _BellVisual();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final size = (h * 0.15).clamp(96.0, 132.0);
    final iconSize = (size * 0.44).roundToDouble();

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppGradients.cta,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: AppShadows.plus,
        ),
        child: Center(child: HomelyIcon(HomelyIcons.bell, size: iconSize, color: AppColors.white, strokeWidth: 1.8)),
      ),
    );
  }
}
