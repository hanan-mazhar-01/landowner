import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/pressable.dart';
import '../../../shared/forms/fields/text_fields.dart';
import '../domain/auth_repository.dart';
import '../domain/app_user.dart';
import 'auth_providers.dart';
import 'auth_scaffold.dart';

import 'widgets/social_auth_buttons.dart';

mixin _Submit<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  String? error;

  Future<void> submit(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Google / Apple sign-in. A new account (no city on the profile yet) goes
  /// through location + notifications setup, like email sign-up.
  void social(Future<AppUser> Function() signIn) => submit(() async {
        final user = await signIn();
        if (mounted && user.city.trim().isEmpty) context.go(Routes.locationSetup);
      });
}

Widget _footer(BuildContext context, String lead, String action, VoidCallback onTap) => Pressable(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text.rich(TextSpan(style: const TextStyle(fontSize: 15, color: AppColors.textMuted), children: [
            TextSpan(text: '$lead · '),
            TextSpan(text: action, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ])),
        ),
      ),
    );

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with _Submit {
  String _email = '', _password = '';

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to your portfolio.',
        error: error,
        fields: [
          LabeledField(
            label: 'Email',
            child: HomelyTextField(value: '', onChanged: (v) => _email = v, placeholder: 'you@example.com',
                keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
          ),
          LabeledField(
            label: 'Password',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              HomelyTextField(value: '', onChanged: (v) => _password = v, placeholder: '••••••••',
                  obscure: true, autofill: const [AutofillHints.password]),
              // Below the input, right-aligned, with a comfortable tap area.
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinkText('Forgot password?', size: 13, onTap: () => context.push(Routes.forgot)),
                ),
              ),
            ]),
          ),
          SocialAuthButtons(
            busy: busy,
            onGoogleTap: () => social(ref.read(authRepositoryProvider).signInWithGoogle),
            onAppleTap: () => social(ref.read(authRepositoryProvider).signInWithApple),
          ),
        ],
        cta: GradientCta(
          label: busy ? 'Signing in…' : 'Sign in',
          onTap: busy ? null : () => submit(() => ref.read(authRepositoryProvider).signIn(email: _email, password: _password)),
        ),
        footer: _footer(context, 'New to LandOwner', 'Create account', () => context.pushReplacement(Routes.signUp)),
      );
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> with _Submit {
  String _name = '', _email = '', _password = '';

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Create your account',
        subtitle: 'Your properties, rent and costs — private to you.',
        error: error,
        fields: [
          LabeledField(
            label: 'Full name',
            child: HomelyTextField(value: '', onChanged: (v) => _name = v, placeholder: 'Your name',
                autofill: const [AutofillHints.name]),
          ),
          LabeledField(
            label: 'Email',
            child: HomelyTextField(value: '', onChanged: (v) => _email = v, placeholder: 'you@example.com',
                keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
          ),
          LabeledField(
            label: 'Password',
            child: HomelyTextField(value: '', onChanged: (v) => _password = v, placeholder: 'At least 6 characters',
                obscure: true, autofill: const [AutofillHints.newPassword]),
          ),
          SocialAuthButtons(
            busy: busy,
            onGoogleTap: () => social(ref.read(authRepositoryProvider).signInWithGoogle),
            onAppleTap: () => social(ref.read(authRepositoryProvider).signInWithApple),
          ),
        ],
        cta: GradientCta(
          label: busy ? 'Creating account…' : 'Create account',
          onTap: busy
              ? null
              : () => submit(
                  () => ref.read(authRepositoryProvider).signUp(name: _name, email: _email, password: _password)),
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                  children: [
                    const TextSpan(text: 'By continuing you agree to our '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => context.push(Routes.termsOfService),
                        child: const Text('Terms of Service',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => context.push(Routes.privacyPolicy),
                        child: const Text('Privacy Policy',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            _footer(context, 'Already have an account', 'Sign in', () => context.pushReplacement(Routes.signIn)),
          ],
        ),
      );
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with _Submit {
  String _email = '';
  bool _sent = false;

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: _sent ? 'Check your inbox' : 'Reset password',
        subtitle: _sent
            ? 'We sent a reset link to $_email. It expires in one hour.'
            : 'Enter the email you signed up with and we’ll send a reset link.',
        error: error,
        fields: [
          if (!_sent)
            LabeledField(
              label: 'Email',
              child: HomelyTextField(value: '', onChanged: (v) => _email = v, placeholder: 'you@example.com',
                  keyboard: TextInputType.emailAddress, autofill: const [AutofillHints.email]),
            ),
        ],
        cta: GradientCta(
          label: _sent ? 'Back to sign in' : (busy ? 'Sending…' : 'Send reset link'),
          onTap: busy
              ? null
              : _sent
                  ? () => context.pop()
                  : () => submit(() async {
                        await ref.read(authRepositoryProvider).sendPasswordReset(_email);
                        if (mounted) setState(() => _sent = true);
                      }),
        ),
      );
}
