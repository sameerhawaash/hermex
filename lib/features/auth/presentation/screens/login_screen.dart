import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/providers/locale_provider.dart';
import '../../data/auth_repository.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال بيانات صحيحة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signIn(email: email, password: password);
      if (mounted) context.go('/');
    } on EmailNotConfirmedException catch (e) {
      if (mounted) _showEmailNotConfirmedDialog(e.email);
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.toLowerCase().contains('invalid login credentials')) {
          errorMessage = 'auth.invalid_credentials'.tr();
        } else {
          errorMessage = 'auth.login_error'.tr(namedArgs: {'error': errorMessage});
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailNotConfirmedDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('auth.email_not_confirmed_title'.tr(),
            textAlign: TextAlign.right),
        content: Text(
          'auth.email_not_confirmed_content'.tr(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('auth.cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeButton,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.resendConfirmationEmail(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'auth.confirmation_sent'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('auth.resend_failed'.tr(namedArgs: {'error': e.toString()}))));
                }
              }
            },
            child: Text('auth.resend'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    // Max width for the form card on larger screens
    final double formMaxWidth = isDesktop ? 480.0 : double.infinity;
    final double hPadding = isDesktop ? 0 : 24;

    return Scaffold(
      backgroundColor: Colors.white,
      // No AppBar – we use a custom back button inside the Stack
      body: Stack(
        children: [
          // ── Scrollable form ───────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: hPadding,
                  vertical: isDesktop ? 48 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: isDesktop ? 32 : 60), // space for top bar

                    // Logo
                    Image.asset(
                      isRtl
                          ? 'assets/images/logo_ar.png'
                          : 'assets/images/logo_en.png',
                      height: isDesktop ? 180 : 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, _) => const Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: AppColors.orangeButton,
                      ),
                    ),

                    SizedBox(height: isDesktop ? 36 : 28),

                    Text(
                      'auth.welcome_back'.tr(),
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 17,
                        color: AppColors.greyText,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isDesktop ? 40 : 32),

                    // Form fields wrapped in a card on desktop
                    _FormCard(
                      isDesktop: isDesktop,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'auth.email'.tr(),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          CustomTextField(
                            label: 'auth.password'.tr(),
                            controller: _passwordController,
                            isPassword: true,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {},
                              child: Text('auth.forgot_password'.tr()),
                            ),
                          ),
                          SizedBox(height: isDesktop ? 24 : 16),
                          SizedBox(
                            width: double.infinity,
                            height: isDesktop ? 58 : 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orangeButton,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'auth.login_button'.tr(),
                                      style: TextStyle(
                                        fontSize: isDesktop ? 20 : 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Back button ───────────────────────────────────────────────
          Positioned(
            top: 48,
            left: isRtl ? null : 16,
            right: isRtl ? 16 : null,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                  color: AppColors.primaryBlue,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          // ── Language button – opposite side from the back button ──────
          Positioned(
            top: 48,
            right: isRtl ? null : 16,
            left: isRtl ? 16 : null,
            child: const SafeArea(child: _LanguageButton()),
          ),
        ],
      ),
    );
  }
}

/// Wraps children in a shadowed card on desktop, plain on mobile
class _FormCard extends StatelessWidget {
  final bool isDesktop;
  final Widget child;
  const _FormCard({required this.isDesktop, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) return child;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }
}

/// Floating language switcher button
class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isAr = currentLocale.languageCode == 'ar';

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final newLocale =
                isAr ? const Locale('en') : const Locale('ar');
            ref.read(localeProvider.notifier).setLocale(newLocale);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: AppColors.orangeButton, size: 20),
                const SizedBox(width: 6),
                Text(
                  isAr ? 'EN' : 'عربي',
                  style: const TextStyle(
                    color: AppColors.orangeButton,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
