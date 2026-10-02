import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/profile/profile_forms.dart';
import 'form_screen.dart';

enum ProfileFormKind { edit, password }

/// Hosts the profile forms in the shared form shell.
class ProfileFormRoute extends ConsumerWidget {
  const ProfileFormRoute({super.key, required this.kind});
  final ProfileFormKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.read(currentUserProvider);
    if (kind == ProfileFormKind.password || u == null) return FormScreen(spec: changePasswordForm());
    return FormScreen(spec: editProfileForm(u));
  }
}
