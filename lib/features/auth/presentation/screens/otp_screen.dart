import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final token = _otpController.text.trim();
    if (token.isEmpty || token.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز صحيح مكون من 6 أرقام')),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.email, token);

    if (mounted) {
      if (success) {
        // Redirect logic will be handled automatically by a Router listener in a full setup,
        // but for now, we simply navigate to home or merchant dashboard as default
        // We will push to an Auth Gateway or simply the app root which handles logic based on role
        context.go('/');
      } else {
        final error = ref.read(authProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'رمز خاطئ أو منتهي الصلاحية')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رمز التحقق'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'الرجاء إدخال الرمز المرسل إلى\n${widget.email}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'رمز التحقق (6 أرقام)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                letterSpacing: 10,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.white,
                ),
                onPressed: authState.isLoading ? null : _handleVerifyOtp,
                child: authState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تأكيد التحقق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
