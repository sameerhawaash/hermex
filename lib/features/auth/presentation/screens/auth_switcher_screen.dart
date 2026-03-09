import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
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
    // 1. Check if we already have a session (e.g. returning from OAuth browser popup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _handleSession(session);
      }
    });

    // 2. Listen to future auth events
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
      // Ensure user record is synced (useful for Google OAuth creating new users)
      final authService = SupabaseAuthService();
      await authService.syncUserRecord(session.user);

      // Fetch User Profile to get role
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
            // Unknown role, stay on auth switcher and show an error
            setState(() {
              _isRedirecting = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'دور المستخدم غير معروف: $role',
                  textAlign: TextAlign.right,
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // No user record found somehow, default to merchant dashboard
          context.go('/merchant/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRedirecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تحميل بيانات الحساب: $e',
              textAlign: TextAlign.right,
            ),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth > 800;

          Widget bodyContent = SingleChildScrollView(
            child: Column(
              children: [
                // Top Hero Image (Responsive)
                Container(
                  width: double.infinity,
                  height: isDesktop ? 450 : 250,
                  color: AppColors
                      .skyBlueBg, // Background color just in case image is smaller
                  child: Image.asset(
                    'assets/images/header 1.png',
                    fit: BoxFit
                        .contain, // Used contain to prevent cropping and stretching
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/LOGO1.png',
                        height: 60,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text(
                              'TayaRak',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orangeButton,
                              ),
                            ),
                      ),
                      const SizedBox(height: 40),

                      // App Tagline (Optional but fits the design style)
                      const Text(
                        'أهلاً بك في طيارك\nمنصة الشحن الأسهل في مصر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.greyText,
                        ),
                      ),

                      const SizedBox(height: 50),

                      _buildAuthButton(
                        context: context,
                        label: 'تسجيل دخول التاجر',
                        color: AppColors.orangeButton,
                        onPressed: () => context.push('/login'),
                      ),
                      const SizedBox(height: 16),
                      _buildAuthButton(
                        context: context,
                        label: 'تسجيل دخول الطيار',
                        color: AppColors.lightBlue,
                        onPressed: () => context.push('/login'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => context.push('/register/merchant'),
                            child: const Text('إنشاء حساب تاجر'),
                          ),
                          const VerticalDivider(),
                          TextButton(
                            onPressed: () => context.push('/register/courier'),
                            child: const Text('إنشاء حساب طيار'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          return bodyContent;
        },
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 300,
      height: 55,
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
