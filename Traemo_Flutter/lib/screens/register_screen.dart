import 'package:flutter/material.dart';

import '../core/constants/app_messages.dart';
import '../core/widgets/app_notifier.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _passwordConfirmationError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;

    final validationMessage = _validateRegisterForm(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    if (validationMessage != null) {
      AppNotifier.showWarning(
        context,
        message: validationMessage,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.register(name, email, password);

      if (!mounted) return;
      AppNotifier.showSuccess(
        context,
        message: AppMessages.registerSuccess,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _applyApiValidationErrors(e);
      AppNotifier.showError(
        context,
        message: _buildErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildErrorMessage(Object error) {
    if (error is ApiException && _isEmailAlreadyUsed(error.message)) {
      return AppMessages.emailAlreadyUsed;
    }

    if (error is ApiException && _isServerError(error.message)) {
      return AppMessages.serverError;
    }

    return AppMessages.registerFailed;
  }

  bool _isServerError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('server') ||
        normalized.contains('invalid response') ||
        normalized.contains('status 5');
  }

  String? _validateRegisterForm({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    final nextNameError = name.isEmpty ? AppMessages.nameRequired : null;
    final nextEmailError = email.isEmpty
        ? AppMessages.incompleteForm
        : _isValidEmail(email)
            ? null
            : AppMessages.invalidEmail;
    final nextPasswordError = password.isEmpty
        ? AppMessages.incompleteForm
        : password.length < 8
            ? AppMessages.passwordTooShort
            : null;
    final nextPasswordConfirmationError = passwordConfirmation.isEmpty
        ? AppMessages.incompleteForm
        : passwordConfirmation != password
            ? AppMessages.passwordConfirmationMismatch
            : null;

    final errors = [
      nextNameError,
      nextEmailError,
      nextPasswordError,
      nextPasswordConfirmationError,
    ].whereType<String>().toList();

    setState(() {
      _nameError = nextNameError;
      _emailError = nextEmailError;
      _passwordError = nextPasswordError;
      _passwordConfirmationError = nextPasswordConfirmationError;
    });

    if (errors.isEmpty) return null;
    if (errors.length > 1) return AppMessages.validationReview;
    return errors.first;
  }

  void _clearFieldError(String field) {
    if (_nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _passwordConfirmationError == null) {
      return;
    }

    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
        case 'email':
          _emailError = null;
        case 'password':
          _passwordError = null;
          _passwordConfirmationError = null;
        case 'password_confirmation':
          _passwordConfirmationError = null;
      }
    });
  }

  void _applyApiValidationErrors(Object error) {
    if (error is! ApiException || !_isEmailAlreadyUsed(error.message)) return;

    setState(() {
      _emailError = AppMessages.emailAlreadyUsed;
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  bool _isEmailAlreadyUsed(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('email') &&
        (normalized.contains('terdaftar') ||
            normalized.contains('already') ||
            normalized.contains('exists') ||
            normalized.contains('taken'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.05),
                    bg,
                    primary.withValues(alpha: 0.10),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 40,
                                  color: onPrimary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Traemo',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: fg,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your finance assistant account',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: muted, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: fg.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                enabled: !_isLoading,
                                onChanged: (_) => _clearFieldError('name'),
                                decoration: InputDecoration(
                                  hintText: 'Your name',
                                  errorText: _nameError,
                                  hintStyle: TextStyle(color: muted),
                                  filled: true,
                                  fillColor: card,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: fg.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                onChanged: (_) => _clearFieldError('email'),
                                decoration: InputDecoration(
                                  hintText: 'you@example.com',
                                  errorText: _emailError,
                                  hintStyle: TextStyle(color: muted),
                                  filled: true,
                                  fillColor: card,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: fg.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                enabled: !_isLoading,
                                onChanged: (_) => _clearFieldError('password'),
                                onSubmitted: (_) => _handleRegister(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  errorText: _passwordError,
                                  hintStyle: TextStyle(color: muted),
                                  filled: true,
                                  fillColor: card,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: fg.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordConfirmationController,
                                obscureText: true,
                                enabled: !_isLoading,
                                onChanged: (_) => _clearFieldError(
                                  'password_confirmation',
                                ),
                                onSubmitted: (_) => _handleRegister(),
                                decoration: InputDecoration(
                                  hintText: 'Confirm your password',
                                  errorText: _passwordConfirmationError,
                                  hintStyle: TextStyle(color: muted),
                                  filled: true,
                                  fillColor: card,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              onPrimary,
                                            ),
                                          ),
                                        )
                                      : const Text('Register'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(fontSize: 14, color: muted),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: GestureDetector(
                                        onTap: _isLoading
                                            ? null
                                            : () => Navigator.pop(context),
                                        child: Text(
                                          'Login',
                                          style: TextStyle(
                                            color: primary,
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
