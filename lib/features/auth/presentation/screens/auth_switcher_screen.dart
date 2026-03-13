import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../../../core/widgets/app_drawer.dart';

class AuthSwitcherScreen extends ConsumerStatefulWidget {
  const AuthSwitcherScreen({super.key});

  @override
  ConsumerState<AuthSwitcherScreen> createState() => _AuthSwitcherScreenState();
}

class _AuthSwitcherScreenState extends ConsumerState<AuthSwitcherScreen> {
  late final StreamSubscription<AuthState> _authStateSubscription;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _handleSession(session);
      }
    });

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) async {
          if (_isRedirecting || !mounted) return;
          final session = data.session;
          final event = data.event;
          if (session != null && event == AuthChangeEvent.signedIn) {
            _handleSession(session);
          }
        });
  }

  Future<void> _handleSession(Session session) async {
    if (_isRedirecting || !mounted) return;

    setState(() {
      _isRedirecting = true;
    });

    try {
      final authService = SupabaseAuthService();
      await authService.syncUserRecord(session.user);

      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      if (mounted) {
        if (response != null) {
          final role = (response['role'] as String?)?.toLowerCase() ?? '';
          if (role == 'merchant') {
            context.go('/merchant/dashboard');
          } else if (role == 'courier') {
            context.go('/courier/dashboard');
          } else if (role == 'admin' || role == 'owner') {
            context.go('/admin/dashboard');
          } else {
            setState(() => _isRedirecting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('auth.unknown_role'.tr(namedArgs: {'role': role}),
                    textAlign: TextAlign.right),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          context.go('/merchant/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedirecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.account_load_error'.tr(namedArgs: {'error': e.toString()}),
                textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRedirecting) {
      return const Scaffold(
        drawer: AppDrawer(),
        backgroundColor: AppColors.skyBlueBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.white)),
      );
    }

    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Main scrollable content ──────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth > 700;
              final double heroHeight = isDesktop ? 420 : 220;
              final double contentMaxWidth = isDesktop ? 560.0 : double.infinity;

              Widget content = SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero image
                    Container(
                      width: double.infinity,
                      height: heroHeight,
                      color: AppColors.skyBlueBg,
                      child: Image.asset(
                        'assets/images/header 1.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Content area
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 24,
                        vertical: 24,
                      ),
                      child: Column(
                        children: [
                          // Logo (centred, language-aware)
                          Builder(builder: (context) {
                            return Image.asset(
                              isRtl
                                  ? 'assets/images/logo_ar.png'
                                  : 'assets/images/logo_en.png',
                              height: isDesktop ? 120 : 90,
                              errorBuilder: (_, __, ___) => Text(
                                'Forrira',
                                style: TextStyle(
                                  fontSize: isDesktop ? 40 : 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orangeButton,
                                ),
                              ),
                            );
                          }),

                          SizedBox(height: isDesktop ? 32 : 24),

                          // Tagline
                          Text(
                            isRtl
                                ? 'auth.tagline'.tr()
                                : 'auth.tagline'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 16,
                              color: AppColors.greyText,
                            ),
                          ),

                          SizedBox(height: isDesktop ? 48 : 36),

                          // Auth buttons
                          _buildAuthButton(
                            context: context,
                            label: 'auth.merchant_login'.tr(),
                            color: AppColors.orangeButton,
                            onPressed: () => context.push('/login'),
                          ),
                          const SizedBox(height: 16),
                          _buildAuthButton(
                            context: context,
                            label: 'auth.courier_login'.tr(),
                            color: AppColors.lightBlue,
                            onPressed: () => context.push('/login'),
                          ),

                          SizedBox(height: isDesktop ? 40 : 28),

                          // Register links
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    context.push('/register/merchant'),
                                child: Text('auth.create_merchant'.tr()),
                              ),
                              const SizedBox(
                                  width: 1,
                                  height: 24,
                                  child: VerticalDivider()),
                              TextButton(
                                onPressed: () =>
                                    context.push('/register/courier'),
                                child: Text('auth.create_courier'.tr()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              // On desktop: center content with max width
              if (isDesktop) {
                content = Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: content,
                  ),
                );
              }

              return content;
            },
          ),

          // ── Language button – floating top corner based on direction ──
          Positioned(
            top: 48,
            right: isRtl ? 16 : null,
            left: isRtl ? null : 16,
            child: const _LanguageButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 400 : double.infinity,
        minWidth: isDesktop ? 300 : 0,
      ),
      child: SizedBox(
        width: double.infinity,
        height: isDesktop ? 60 : 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
