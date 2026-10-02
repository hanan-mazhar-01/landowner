import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/icons/homely_icon.dart';
import '../../core/utils/contact_launcher.dart';
import '../../core/utils/regions.dart';
import '../../core/widgets/brand_logos.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/toast.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/preferences_provider.dart';

/// The owner's international dialling code, used to turn a tenant's local
/// number into the international form WhatsApp needs. From the profile's
/// country, else from the currency when it belongs to a single country.
final ownerDialCodeProvider = Provider<String?>((ref) {
  final city = ref.watch(currentUserProvider)?.city ?? '';
  final country = Regions.countryByName(city.split(',').last.trim());
  if (country != null) return country.dial;
  final code = ref.watch(preferencesProvider).code;
  final matches = [for (final c in Regions.countries) if (c.currency == code) c];
  return matches.length == 1 ? matches.single.dial : null;
});

/// Call · Message · WhatsApp tiles (64px, #F1F3FF), as on the Overdue rent screen.
class ContactTiles extends ConsumerWidget {
  const ContactTiles({super.key, required this.phone, this.message = ''});
  final String phone, message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> go(Future<bool> Function() f) async {
      if (!await f()) ref.read(toastProvider.notifier).show('Couldn’t open that app on this device');
    }

    Widget tile(Widget icon, String label, VoidCallback onTap) => Expanded(
          child: SurfaceCard(
            onTap: onTap,
            color: AppColors.blue50,
            radius: 18,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 64,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                icon,
                const SizedBox(height: 5),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ),
        );

    return Row(children: [
      tile(_icon(HomelyIcons.phone), 'Call', () => go(() => ContactLauncher.call(phone))),
      const SizedBox(width: 8),
      tile(_icon(HomelyIcons.message), 'Message', () => go(() => ContactLauncher.message(phone, message))),
      const SizedBox(width: 8),
      tile(const WhatsAppLogo(size: 21), 'WhatsApp',
          () => go(() => ContactLauncher.whatsapp(phone, message, dialCode: ref.read(ownerDialCodeProvider)))),
    ]);
  }
}

Widget _icon(HomelyIcons icon) => HomelyIcon(icon, size: 20, color: AppColors.primary, strokeWidth: 1.9);
