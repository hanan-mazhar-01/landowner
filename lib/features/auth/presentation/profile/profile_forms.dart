import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../shared/forms/form_spec.dart';
import '../../domain/app_user.dart';
import '../auth_providers.dart';

/// Edit profile — same form shell as every other edit.
FormSpec editProfileForm(AppUser u) => FormSpec(
      title: 'Edit profile',
      initial: FormValues({
        'photo': <String>[?u.avatarUrl],
        'name': u.name,
        'email': u.email,
        'phone': u.phone,
      }),
      steps: const [
        StepSpec('Your profile', fields: [
          FieldSpec('photo', 'Profile photo', FieldKind.upload),
          FieldSpec('name', 'Full name', FieldKind.text, required: true),
          FieldSpec('email', 'Email', FieldKind.text, keyboard: TextInputType.emailAddress, required: true),
          FieldSpec('phone', 'Phone', FieldKind.text, keyboard: TextInputType.phone, placeholder: 'Phone number'),
        ]),
      ],
      onSave: (v, WidgetRef ref) async {
        await ref.read(authRepositoryProvider).updateProfile(
              name: v.str('name'),
              email: v.str('email'),
              phone: v.str('phone'),
              avatarUrl: v.files('photo').lastOrNull,
            );
        return const FormResult(toast: 'Profile updated');
      },
    );

/// Change password.
FormSpec changePasswordForm() => FormSpec(
      title: 'Change password',
      saveLabel: 'Update password',
      initial: const FormValues({'current': '', 'next': '', 'confirm': ''}),
      steps: const [
        StepSpec('Change password', fields: [
          FieldSpec('current', 'Current password', FieldKind.text, obscure: true, required: true),
          FieldSpec('next', 'New password', FieldKind.text, obscure: true, required: true, placeholder: 'At least 6 characters'),
          FieldSpec('confirm', 'Confirm new password', FieldKind.text, obscure: true, required: true),
        ]),
      ],
      onSave: (v, WidgetRef ref) async {
        if (v.str('next') != v.str('confirm')) {
          throw const AppFailure('New passwords don\u2019t match.');
        }
        await ref.read(authRepositoryProvider).changePassword(current: v.str('current'), next: v.str('next'));
        return const FormResult(toast: 'Password updated');
      },
    );
