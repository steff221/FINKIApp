import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/brand_mark.dart';
import 'widgets/auth_form.dart';

/// Најава — the same visual language as Дома: canvas background, left-aligned
/// large title in navy, and the shared field / button treatment from the app
/// theme (white fill, 1pt [AppColors.border] hairline, 14pt radius).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();

  bool _obscure = true;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Drives the button's enabled state.
    _email.addListener(_onChanged);
    _password.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final email = _email.text.trim();
    setState(() {
      _emailError = email.contains('@') && !email.endsWith('@') ? null : 'Внесете валидна е-пошта';
    });
    if (_emailError != null) {
      _emailNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(email, _password.text);
    // On success the router redirects automatically.
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            // Keyboard avoidance: the form scrolls instead of being covered.
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lands the mark and title in the top third.
                  SizedBox(height: constraints.maxHeight * 0.12),
                  const BrandMark(size: 48),
                  const SizedBox(height: 14),
                  Text(
                    'ФИНКИ Распоред',
                    style: text.headlineLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.37,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Најавете се за да продолжите',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthField(
                          label: 'Е-пошта',
                          controller: _email,
                          focusNode: _emailNode,
                          icon: 'assets/mail.svg',
                          errorText: _emailError,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: () {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                          onSubmitted: _passwordNode.requestFocus,
                        ),
                        const SizedBox(height: 12),
                        AuthField(
                          label: 'Лозинка',
                          controller: _password,
                          focusNode: _passwordNode,
                          icon: 'assets/password.svg',
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: _submit,
                          suffix: PasswordToggle(
                            obscured: _obscure,
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Server-side failures are not tied to one field, so they read
                  // as a form-level line rather than a dialog.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.topLeft,
                    child: auth.error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AuthFormError(auth.error!),
                          ),
                  ),
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    label: 'Најави се',
                    loading: auth.loading,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                  const SizedBox(height: 4),
                  AuthSwitchLink(
                    question: 'Немате профил?',
                    action: 'Регистрирајте се',
                    onPressed: () => context.push('/register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
