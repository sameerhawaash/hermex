import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../presentation/providers/wallet_providers.dart';
import '../../data/wallet_repository.dart';
import '../../../auth/data/auth_provider.dart';
import 'kashier_webview_screen.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(currentWalletProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final isCourier =
        profileAsync.whenOrNull(data: (p) => p?['role'] == 'courier') ?? false;

    return Scaffold(
      backgroundColor: AppColors.skyBlueBg,
      appBar: AppBar(
        title: const Text('محفظتي'),
        backgroundColor: AppColors.orangeButton,
        foregroundColor: Colors.white,
      ),
      // Top-up FAB visible to Couriers
      floatingActionButton: isCourier
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('شحن الرصيد'),
              onPressed: () => _showTopUpDialog(context, ref),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            walletAsync.when(
              data: (wallet) {
                final balance = (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
                return _buildBalanceCard(context, balance, isCourier);
              },
              loading: () => _buildBalanceCardSkeleton(),
              error: (e, _) => _buildErrorCard('خطأ في تحميل الرصيد: $e'),
            ),
            const SizedBox(height: 24),
            // Commission info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'يتم خصم 10 ج.م عمولة للمنصة من كل شحنة تُسلَّم بنجاح (من محفظة التاجر والطيار).',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'سجل المعاملات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Transactions List
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionTile(transactions[index]);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _buildErrorCard('خطأ في تحميل المعاملات: $e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('شحن الرصيد', textAlign: TextAlign.right),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل المبلغ المراد إضافته لمحفظتك:',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'مثال: 200',
                    suffixText: 'ج.م',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Info about Kashier
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'سيتم تحويلك لبوابة Kashier. عد انتهاء الدفع سيتم تحديث رصيدك تلقائياً.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final amount = double.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0) return;
                        setState(() => isLoading = true);
                        try {
                          final repo = ref.read(walletRepositoryProvider);

                          // 1. Get signed payment URL + orderId from Edge Function
                          final checkout = await repo.startKashierCheckout(
                            amount: amount,
                          );

                          // 2. Close the dialog before opening the WebView
                          // ignore: use_build_context_synchronously
                          Navigator.pop(ctx);

                          // 3. Open the in-app Kashier WebView
                          // ignore: use_build_context_synchronously
                          final result =
                              await Navigator.push<KashierPaymentResult>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KashierWebViewScreen(
                                    paymentUrl: checkout.paymentUrl,
                                    orderId: checkout.orderId,
                                    amount: amount,
                                  ),
                                ),
                              );

                          // 4. React to the payment result
                          // ignore: use_build_context_synchronously
                          if (!context.mounted) return;

                          if (result == KashierPaymentResult.success) {
                            // Refresh wallet data immediately
                            ref.invalidate(currentWalletProvider);
                            ref.invalidate(walletTransactionsProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم شحن رصيدك بنجاح!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          } else if (result == KashierPaymentResult.failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '❌ فشلت عملية الدفع. يرجى المحاولة مجدداً.',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                          // KashierPaymentResult.cancelled → do nothing
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => isLoading = false);
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('دفع عبر Kashier'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    bool isCourier,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'الرصيد الحالي',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'ج.م',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white60, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCourier
                      ? 'يتم خصم 10 ج.م عمولة للمنصة عند كل شحنة تُسلَّم بنجاح.\nاضغط "شحن الرصيد" في الأسفل لإضافة رصيد.'
                      : 'يتم خصم 10 ج.م عمولة للمنصة عند كل شحنة تُسلَّم بنجاح.',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCardSkeleton() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final refType = tx['reference_type'] as String? ?? '';
    final createdAt = tx['created_at'] as String?;
    final isPositive = amount >= 0;

    final (icon, label, color) = switch (refType) {
      'shipment_revenue' ||
      'delivery_reward' => (Icons.check_circle, 'أرباح توصيل', Colors.green),
      'deposit' ||
      'manual_deposit' => (Icons.add_circle, 'إيداع / شحن رصيد', Colors.blue),
      'shipment_deduction' => (Icons.lock, 'خصم شحنة', Colors.orange),
      'platform_commission' => (
        Icons.percent,
        'عمولة المنصة (10 ج.م)',
        Colors.red.shade400,
      ),
      'withdrawal' => (Icons.remove_circle, 'سحب رصيد', Colors.red),
      _ => (Icons.swap_horiz, refType.replaceAll('_', ' '), Colors.grey),
    };

    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: dateStr.isNotEmpty
            ? Text(
                dateStr,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            : null,
        trailing: Text(
          '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)} ج.م',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'لا توجد معاملات حتى الآن',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
