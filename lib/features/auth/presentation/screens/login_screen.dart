import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
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

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signIn(email: email, password: password);

      if (mounted) {
        context.go('/');
      }
    } on EmailNotConfirmedException catch (e) {
      if (mounted) {
        _showEmailNotConfirmedDialog(e.email);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.toLowerCase().contains('invalid login credentials')) {
          errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else {
          errorMessage = 'خطأ في تسجيل الدخول: $errorMessage';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEmailNotConfirmedDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'البريد الإلكتروني غير مؤكد',
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'لم يتم تأكيد بريدك الإلكتروني بعد.\nهل تريد إعادة إرسال رابط التأكيد؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
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
                    const SnackBar(
                      content: Text(
                        'تم إرسال رابط التأكيد، تحقق من بريدك الإلكتروني',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
                }
              }
            },
            child: const Text('إعادة الإرسال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/LOGO1.png',
                height: 120, // Increased height
                fit: BoxFit.contain, // Added explicit fit
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading logo: $error');
                  return const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: AppColors.orangeButton,
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'أهلاً بك مجدداً\nالرجاء إدخال بيانات الدخول',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.greyText,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                label: 'البريد الإلكتروني',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                label: 'كلمة المرور',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    // Forgot password logic
                  },
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'دخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
