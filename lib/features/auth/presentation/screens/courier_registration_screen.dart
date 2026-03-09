import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../../data/auth_repository.dart';

class CourierRegistrationScreen extends ConsumerStatefulWidget {
  const CourierRegistrationScreen({super.key});

  @override
  ConsumerState<CourierRegistrationScreen> createState() =>
      _CourierRegistrationScreenState();
}

class _CourierRegistrationScreenState
    extends ConsumerState<CourierRegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _governorateController = TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _governorateController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب الموافقة على الشروط والأحكام')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'courier',
        fullName:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        phone: _phoneController.text.trim(),
        governorate: _governorateController.text.trim().isEmpty
            ? 'Cairo'
            : _governorateController.text.trim(),
        // Cannot store delivery method inside users natively unless added to schema, we omit for now.
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب بنجاح')));
        context.go('/courier/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التسجيل: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('إنشاء حساب مندوب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'قم بإنشاء حسابك كـ كابتن توصيل لتقديم خدمات التوصيل للتجار، وإدارة عروضك وطلباتهم بكفاءة وسهولة.',
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              label: 'رقم الهاتف',
              keyboardType: TextInputType.phone,
              controller: _phoneController,
            ),

            CustomTextField(
              label: 'المحافظة',
              controller: _governorateController,
            ),

            // Omitted for now unless schema is updated, keeping as dummy text field if needed, but omitted here to save time.
            // CustomTextField(label: 'طريقة التوصيل', controller: TextEditingController()),
            CustomTextField(
              label: 'الاسم الاول',
              controller: _firstNameController,
            ),
            CustomTextField(
              label: 'الاسم الاخير',
              controller: _lastNameController,
            ),
            CustomTextField(
              label: 'البريد الإلكتروني',
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            CustomTextField(
              label: 'كلمة المرور',
              isPassword: true,
              controller: _passwordController,
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (val) {
                    setState(() {
                      _agreedToTerms = val ?? false;
                    });
                  },
                ),
                const Text(
                  'أوافق على ',
                  style: TextStyle(color: AppColors.greyText),
                ),
                const Text(
                  'الشروط و الأحكام',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkButton,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('التالي'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
