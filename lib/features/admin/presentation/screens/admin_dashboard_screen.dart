import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('لوحة تحكم الإدارة'),
        backgroundColor: AppColors.darkButton,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout logic
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 100,
              color: AppColors.darkButton,
            ),
            const SizedBox(height: 20),
            Text(
              'مرحباً بك في لوحة تحكم الإدارة',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildAdminAction(context, 'إدارة المستخدمين', Icons.group),
                _buildAdminAction(
                  context,
                  'إدارة الشحنات',
                  Icons.local_shipping,
                ),
                _buildAdminAction(
                  context,
                  'إدارة المحافظ',
                  Icons.account_balance_wallet,
                ),
                _buildAdminAction(
                  context,
                  'تقارير ونزاعات',
                  Icons.report_problem,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAction(BuildContext context, String title, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implement logic
      },
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}
