/// Giriş / Kayıt ekranı
/// Zen minimalist tasarım - Google, GitHub, Apple ve email/password desteği
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _signUpSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; _signUpSuccess = false; });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await repo.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _signUpSuccess = true;
            _isSignUp = false;
          });
        }
      } else {
        await repo.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('email_not_confirmed') || msg.contains('Email not confirmed')) {
        msg = '📧 E-posta adresiniz henüz onaylanmadı.\nKayıt sırasında gönderilen onay e-postasını kontrol edin.';
      } else if (msg.contains('Invalid login credentials')) {
        msg = 'E-posta veya şifre hatalı.';
      } else if (msg.contains('User already registered')) {
        msg = 'Bu e-posta adresi zaten kayıtlı.';
      }
      setState(() { _errorMessage = msg; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleOAuth(Future<bool> Function() authFn) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await authFn();
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      body: Row(
        children: [
          // Sol panel (masaüstünde görünür)
          if (isWide) Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.accent,
                    const Color(0xFF4338CA),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsBold.notebook, color: Colors.white, size: 72),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appTagline,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.2),
              ),
            ),
          ),

          // Sağ panel - Form
          Expanded(
            flex: isWide ? 1 : 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isWide) ...[
                          const Icon(PhosphorIconsBold.notebook,
                              color: AppColors.primary, size: 48),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          _isSignUp ? AppStrings.signUp : AppStrings.signIn,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp
                              ? 'Create your Notebook account'
                              : 'Welcome back to Notebook',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // OAuth Buttons
                        _OAuthButton(
                          icon: PhosphorIconsBold.googleLogo,
                          label: AppStrings.continueWithGoogle,
                          onTap: () => _handleOAuth(
                            ref.read(authRepositoryProvider).signInWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _OAuthButton(
                          icon: PhosphorIconsBold.githubLogo,
                          label: AppStrings.continueWithGitHub,
                          onTap: () => _handleOAuth(
                            ref.read(authRepositoryProvider).signInWithGitHub,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _OAuthButton(
                          icon: PhosphorIconsBold.appleLogo,
                          label: AppStrings.continueWithApple,
                          onTap: () => _handleOAuth(
                            ref.read(authRepositoryProvider).signInWithApple,
                          ),
                        ),

                        const SizedBox(height: 20),
                        _DividerWithText(text: 'or'),
                        const SizedBox(height: 20),

                        // Name Field (Sign Up only)
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: AppStrings.fullName,
                              prefixIcon: Icon(PhosphorIconsRegular.user, size: 20),
                            ),
                            validator: (v) => _isSignUp && (v?.isEmpty ?? true)
                                ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: AppStrings.email,
                            prefixIcon: Icon(PhosphorIconsRegular.envelope, size: 20),
                          ),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Email is required';
                            if (!v!.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleEmailAuth(),
                          decoration: InputDecoration(
                            hintText: AppStrings.password,
                            prefixIcon: const Icon(PhosphorIconsRegular.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? PhosphorIconsRegular.eye
                                    : PhosphorIconsRegular.eyeSlash,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Password is required';
                            if ((v?.length ?? 0) < 6) return 'Min 6 characters';
                            return null;
                          },
                        ),

                        if (_signUpSuccess) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '✅ Hesap oluşturuldu! E-postanızı onaylayıp giriş yapabilirsiniz.',
                                    style: TextStyle(color: Colors.green, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isSignUp ? AppStrings.signUp : AppStrings.signIn),
                        ),

                        const SizedBox(height: 16),

                        // Switch Auth Mode
                        TextButton(
                          onPressed: () => setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          }),
                          child: Text(
                            _isSignUp
                                ? AppStrings.alreadyHaveAccount
                                : AppStrings.dontHaveAccount,
                          ),
                        ),
                      ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OAuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(child: Divider(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        )),
      ],
    );
  }
}
