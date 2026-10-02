import 'package:flutter/widgets.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'net_image.dart';

/// Circular avatar: the photo when [url] is set, otherwise the initials of
/// [name] on the accent tint (never a blank circle).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.url, this.size = 40});

  final String name;
  final String? url;
  final double size;

  static String initialsOf(String name) {
    final letters = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(p[0]))
        .map((p) => p[0])
        .take(2)
        .join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: hasPhoto
            ? NetImage(url)
            : ColoredBox(
                color: AppColors.blue100,
                child: Center(
                  child: Text(
                    initialsOf(name),
                    style: AppType.num(size * 0.36).copyWith(color: AppColors.primary),
                  ),
                ),
              ),
      ),
    );
  }
}
