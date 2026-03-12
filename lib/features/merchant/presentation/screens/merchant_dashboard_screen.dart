import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../shipments/presentation/providers/shipment_providers.dart';
import '../../../../core/widgets/profile_drawer.dart';

class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState
    extends ConsumerState<MerchantDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ProfileDrawer(),
      backgroundColor: AppColors.skyBlueBg,
      appBar: AppBar(
        centerTitle: false,
        title: Builder(
          builder: (context) {
            final isRtl = Directionality.of(context) == TextDirection.rtl;
            return Image.asset(
              isRtl ? 'assets/images/logo_ar.png' : 'assets/images/logo_en.png',
              height: 56, // Increased height
              fit: BoxFit.contain,
            );
          },
        ),
        backgroundColor: AppColors.orangeButton,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final shipmentsAsyncValue = ref.watch(merchantShipmentsProvider);

          return shipmentsAsyncValue.when(
            data: (shipments) {
              int total = shipments.length;
              int pending = shipments
                  .where((s) => s['status'] == 'pending')
                  .length;
              int inTransit = shipments
                  .where(
                    (s) =>
                        s['status'] == 'accepted' ||
                        s['status'] == 'in_transit',
                  )
                  .length;
              int delivered = shipments
                  .where((s) => s['status'] == 'delivered')
                  .length;
              int rejected = shipments
                  .where((s) => s['status'] == 'rejected')
                  .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stats Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 800;
                        return GridView.count(
                          crossAxisCount: isDesktop ? 5 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.5,
                          children: [
                            _buildStatCard(
                              'الإجمالي',
                              total,
                              Icons.inventory_2,
                              Colors.purple,
                            ),
                            _buildStatCard(
                              'مرفوضة',
                              rejected,
                              Icons.error_outline,
                              Colors.red,
                            ),
                            _buildStatCard(
                              'تم التسليم',
                              delivered,
                              Icons.check_circle_outline,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'جاري التوصيل',
                              inTransit,
                              Icons.local_shipping_outlined,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'قيد الانتظار',
                              pending,
                              Icons.schedule,
                              Colors.orange,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Shipments Table Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'شحناتي',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (shipments.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'لا توجد لديك شحنات حالية.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('رقم التتبع')),
                                    DataColumn(label: Text('من')),
                                    DataColumn(label: Text('إلى')),
                                    DataColumn(label: Text('سعر الشحنة')),
                                    DataColumn(label: Text('سعر التوصيل')),
                                    DataColumn(label: Text('الحالة')),
                                  ],
                                  rows: shipments.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final s = entry.value;
                                    final rawId = s['id']?.toString() ?? '';
                                    String trackingHint;
                                    if (rawId.isNotEmpty && rawId != 'null') {
                                      final safeLen = rawId.length < 8
                                          ? rawId.length
                                          : 8;
                                      trackingHint =
                                          'TY${rawId.substring(0, safeLen).toUpperCase()}';
                                    } else {
                                      trackingHint =
                                          'TY${(index + 1).toString().padLeft(4, '0')}';
                                    }
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(trackingHint)),
                                        DataCell(
                                          Text(s['pickup_address'] ?? ''),
                                        ),
                                        DataCell(
                                          Text(s['delivery_address'] ?? ''),
                                        ),
                                        DataCell(
                                          Text('${s['shipment_price']} ج.م'),
                                        ),
                                        DataCell(
                                          Text(
                                            '${s['delivery_fee']} ج.م',
                                            style: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: s['status'] == 'pending'
                                                  ? Colors.orange.shade100
                                                  : Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _translateStatus(s['status']),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('حدث خطأ: $error')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/merchant/shipment/create');
        },
        backgroundColor: AppColors.orangeButton,
        icon: const Icon(Icons.add),
        label: const Text('إنشاء شحنة'),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'تم القبول';
      case 'in_transit':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      case 'rejected':
        return 'مرفوضة';
      default:
        return status;
    }
  }
}
