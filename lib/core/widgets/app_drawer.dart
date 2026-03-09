import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_repository.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            color: AppColors.orangeButton,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/LOGO1.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person_pin,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isLoggedIn ? (session.user.email ?? 'مستخدم') : 'زائر',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (!isLoggedIn) ...[
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('تسجيل الدخول'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('إنشاء حساب تاجر'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/register/merchant');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delivery_dining),
                    title: const Text('إنشاء حساب طيار'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/register/courier');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('الصفحة الرئيسية'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('لوحة التحكم'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
