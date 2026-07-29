import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/auth_form.dart';

/// Minimum the backend accepts (`@Size(min = 8)` on RegisterRequest).
const _kMinPasswordLength = 8;

/// Нов профил — registration, laid out exactly like Најава so the pair reads as
/// one flow. On success the backend returns a token with the 201, so the router
/// redirects straight into the app.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameNode = FocusNode();
  final _emailNode = FocusNode();
  final _passwordNode = FocusNode();
  final _confirmNode = FocusNode();

  bool _obscure = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onChanged);
    _email.addListener(_onChanged);
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _nameNode.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    _confirmNode.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _confirm.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final email = _email.text.trim();
    setState(() {
      _nameError = _name.text.trim().length < 2 ? 'Внесете го вашето име' : null;
      _emailError = email.contains('@') && !email.endsWith('@') ? null : 'Внесете валидна е-пошта';
      _passwordError = _password.text.length < _kMinPasswordLength
          ? 'Лозинката мора да има барем $_kMinPasswordLength знаци'
          : null;
      _confirmError = _confirm.text == _password.text ? null : 'Лозинките не се совпаѓаат';
    });

    if (_nameError != null) {
      _nameNode.requestFocus();
      return;
    }
    if (_emailError != null) {
      _emailNode.requestFocus();
      return;
    }
    if (_passwordError != null) {
      _passwordNode.requestFocus();
      return;
    }
    if (_confirmError != null) {
      _confirmNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .register(email, _password.text, name: _name.text.trim());
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Pushed over Најава, so it needs a way back.
                  IconButton(
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Назад',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.navy),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.06),
                  Text(
                    'Нов профил',
                    style: text.headlineLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.37,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Регистрирајте се за да го зачувате вашиот распоред',
                    style: text.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 28),
                  AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthField(
                          label: 'Име',
                          controller: _name,
                          focusNode: _nameNode,
                          iconData: Icons.person_outline_rounded,
                          errorText: _nameError,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.givenName],
                          onChanged: () {
                            if (_nameError != null) setState(() => _nameError = null);
                          },
                          onSubmitted: _emailNode.requestFocus,
                        ),
                        const SizedBox(height: 12),
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
                          errorText: _passwordError,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: () {
                            if (_passwordError != null) setState(() => _passwordError = null);
                          },
                          onSubmitted: _confirmNode.requestFocus,
                          suffix: PasswordToggle(
                            obscured: _obscure,
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AuthField(
                          label: 'Потврди лозинка',
                          controller: _confirm,
                          focusNode: _confirmNode,
                          icon: 'assets/password.svg',
                          errorText: _confirmError,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: () {
                            if (_confirmError != null) setState(() => _confirmError = null);
                          },
                          onSubmitted: _submit,
                        ),
                      ],
                    ),
                  ),
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
                    label: 'Креирај профил',
                    loading: auth.loading,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                  const SizedBox(height: 4),
                  AuthSwitchLink(
                    question: 'Веќе имате профил?',
                    action: 'Најавете се',
                    onPressed: () => context.pop(),
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
