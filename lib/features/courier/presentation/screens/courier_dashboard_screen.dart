import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/profile_drawer.dart';
import '../../../shipments/presentation/providers/shipment_providers.dart';
import '../../../shipments/data/shipment_repository.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import 'package:easy_localization/easy_localization.dart';

class CourierDashboardScreen extends ConsumerStatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  ConsumerState<CourierDashboardScreen> createState() =>
      _CourierDashboardScreenState();
}

class _CourierDashboardScreenState
    extends ConsumerState<CourierDashboardScreen> {
  final Set<String> _processingIds = {};

  Future<void> _acceptShipment(String shipmentId, double shipmentPrice) async {
    final user = ref.read(userProfileProvider).value;
    if (user == null) return;
    
    // Check available balance
    final walletAsync = ref.read(currentWalletProvider);
    double availableBalance = 0;
    if (walletAsync is AsyncData) {
      availableBalance = (walletAsync.value?['balance'] as num?)?.toDouble() ?? 0;
    }

    if (availableBalance < shipmentPrice) {
      final double remaining = shipmentPrice - availableBalance;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'courier.dashboard.actions.insufficient_balance'
                  .tr(namedArgs: {'amount': remaining.toStringAsFixed(2)}),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _processingIds.add(shipmentId));
    try {
      final repo = ref.read(shipmentRepositoryProvider);
      await repo.acceptShipment(shipmentId: shipmentId, courierId: user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('courier.dashboard.actions.accept_success'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'courier.dashboard.actions.accept_error'.tr();
        final errText = e.toString().toLowerCase();
        if (errText.contains('insufficient') || errText.contains('balance')) {
          errorMsg = 'courier.dashboard.actions.insufficient_balance_short'.tr();
        } else if (errText.contains('already accepted') ||
            errText.contains('status')) {
          errorMsg = 'courier.dashboard.actions.already_accepted'.tr();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(shipmentId));
    }
  }

  Future<void> _deliverShipment(String shipmentId) async {
    setState(() => _processingIds.add(shipmentId));
    try {
      final repo = ref.read(shipmentRepositoryProvider);
      await repo.deliverShipment(shipmentId: shipmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('courier.dashboard.actions.deliver_success'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('merchant.error'.tr(namedArgs: {'error': e.toString()})), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(shipmentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(currentWalletProvider);
    final courierShipmentsAsync = ref.watch(courierShipmentsProvider);
    final availableShipmentsAsync = ref.watch(availableShipmentsProvider);

    double availableBalance = 0;
    if (walletAsync is AsyncData) {
      availableBalance =
          (walletAsync.value?['balance'] as num?)?.toDouble() ?? 0;
    }

    int deliveredCount = 0;
    double earnedDeliveryFee = 0;
    int inTransitCount = 0;
    double lockedGuarantee = 0;
    int returnedCount = 0;

    if (courierShipmentsAsync is AsyncData) {
      for (var s in (courierShipmentsAsync.value ?? [])) {
        final status = (s['status'] as String?)?.toLowerCase() ?? '';
        final deposit = (s['shipment_price'] as num?)?.toDouble() ?? 0;
        final fee = (s['delivery_fee'] as num?)?.toDouble() ?? 0;
        if (status == 'delivered') {
          deliveredCount++;
          earnedDeliveryFee += fee;
        } else if (status == 'accepted' || status == 'in_transit') {
          inTransitCount++;
          lockedGuarantee += deposit;
        } else if (status == 'returned' ||
            status == 'cancelled' ||
            status == 'rejected') {
          returnedCount++;
        }
      }
    }

    // The database now deducts the guarantee immediately upon acceptance.
    // So the 'availableBalance' is the actual withdrawable balance.
    // We can still show 'lockedGuarantee' for informational purposes,
    // but the main 'الإجمالي' (Total) should just be the available balance now,
    // or if the user means "Total wealth = available + locked", we can keep it.
    // However, the user asked to "show only the current balance after deduction".
    double totalBalance = availableBalance < 0 ? 0 : availableBalance; // Prevent showing negative in main card if desired, but actually negative means debt.
    // Wait, the user's screenshot showed "-12000" which means they accepted a shipment before we added the SQL guard.

    return Scaffold(
      drawer: const ProfileDrawer(),
      backgroundColor: const Color(0xFFEBF6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) {
                final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
                return Image.asset(
                  isRtl ? 'assets/images/logo_ar.png' : 'assets/images/logo_en.png',
                  height: 100, // Increased height per user request
                  fit: BoxFit.contain,
                );
              },
            ),
            Row(
              children: [
                Text(
                  'courier.dashboard.live'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top Stat Cards ───
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTopCard(
                    iconBgColor: const Color(0xFF1F487E),
                    iconData: Icons.account_balance_wallet_outlined,
                    title: 'courier.dashboard.available_balance'.tr(),
                    mainValue: '${totalBalance.toStringAsFixed(2)} ${'merchant.currency'.tr()}',
                    buttonText: 'courier.dashboard.withdraw_balance'.tr(),
                    onButtonTap: () => context.push('/courier/wallet'),
                    footerLines: [
                      (
                        'courier.dashboard.locked_guarantee'.tr(),
                        '${lockedGuarantee.toStringAsFixed(2)} ${'merchant.currency'.tr()}',
                      ),
                    ],
                  ),
                  _buildTopCard(
                    iconBgColor: const Color(0xFF2ECC71),
                    iconData: Icons.check,
                    title: 'courier.dashboard.delivered'.tr(),
                    mainValue: '$deliveredCount',
                    footerLines: [
                      (
                        'courier.dashboard.earned_fee'.tr(),
                        '${earnedDeliveryFee.toStringAsFixed(2)} ${'merchant.currency'.tr()}',
                      ),
                      ('courier.dashboard.guarantee_release'.tr(), '$deliveredCount'),
                    ],
                  ),
                  _buildTopCard(
                    iconBgColor: const Color(0xFFF39C12),
                    iconData: Icons.local_shipping_outlined,
                    title: 'courier.dashboard.in_transit'.tr(),
                    mainValue: '$inTransitCount',
                    footerLines: [
                      (
                        'courier.dashboard.locked_insurance'.tr(),
                        '${lockedGuarantee.toStringAsFixed(2)} ${'merchant.currency'.tr()}',
                      ),
                    ],
                  ),
                  _buildTopCard(
                    iconBgColor: const Color(0xFFE74C3C),
                    iconData: Icons.close,
                    title: 'courier.dashboard.returned_issue'.tr(),
                    mainValue: '$returnedCount',
                    footerLines: [
                      ('courier.dashboard.returned_guarantee'.tr(), '$returnedCount'),
                      ('courier.dashboard.pending_issues'.tr(), '0'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Available Shipments ───
            _buildSectionHeader(
              title: 'courier.available_shipments'.tr(),
              badge: availableShipmentsAsync.when(
                data: (s) => 'courier.dashboard.available_shipments_badge'.tr(namedArgs: {'count': s.length.toString()}),
                loading: () => '...',
                error: (_, __) => '',
              ),
            ),
            const SizedBox(height: 12),
            _buildTableCard(
              headers: [
                'courier.dashboard.table.image'.tr(),
                'courier.dashboard.table.weight'.tr(),
                'courier.dashboard.table.from'.tr(),
                'courier.dashboard.table.to'.tr(),
                'courier.dashboard.table.price'.tr(),
                'courier.dashboard.table.fee'.tr(),
                'courier.dashboard.table.status'.tr(),
                'courier.dashboard.table.action'.tr(),
              ],
              flexes: const [1, 1, 1, 1, 1, 1, 1, 2],
              child: availableShipmentsAsync.when(
                data: (shipments) {
                  if (shipments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(child: Text('courier.no_shipments'.tr())),
                    );
                  }
                  return Column(
                    children: shipments
                        .map((s) => _buildAvailableRow(s))
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('merchant.error'.tr(namedArgs: {'error': e.toString()})),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ─── Active Shipments ───
            _buildSectionHeader(
              title: 'courier.dashboard.active_shipments_title'.tr(),
              badge: '',
            ),
            const SizedBox(height: 12),
            _buildTableCard(
              headers: [
                'courier.dashboard.table.tracking'.tr(),
                'courier.dashboard.table.from'.tr(),
                'courier.dashboard.table.to'.tr(),
                'courier.dashboard.table.price'.tr(),
                'courier.dashboard.table.status'.tr(),
                'courier.dashboard.table.confirm_delivery'.tr(),
                'courier.dashboard.table.other_action'.tr(),
              ],
              flexes: const [1, 1, 1, 1, 1, 2, 2],
              child: courierShipmentsAsync.when(
                data: (shipments) {
                  if (shipments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(child: Text('courier.dashboard.no_active_shipments'.tr())),
                    );
                  }
                  return Column(
                    children: shipments.map((s) => _buildActiveRow(s)).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('merchant.error'.tr(namedArgs: {'error': e.toString()})),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard({
    required Color iconBgColor,
    required IconData iconData,
    required String title,
    required String mainValue,
    String? buttonText,
    VoidCallback? onButtonTap,
    required List<(String, String)> footerLines,
  }) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      mainValue,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: onButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F487E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 10),
          for (var line in footerLines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      line.$1,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    line.$2,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2A47),
            ),
          ),
        ),
        if (badge.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableCard({
    required List<String> headers,
    required List<int> flexes,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              color: const Color(0xFFF8F9F9),
              child: Row(
                children: [
                  for (int i = 0; i < headers.length; i++)
                    Expanded(
                      flex: flexes[i],
                      child: Text(
                        headers[i],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableRow(Map<String, dynamic> s) {
    final shipmentId = s['id']?.toString() ?? '';
    final from = s['pickup_address'] ?? '';
    final to = s['delivery_address'] ?? '';
    final price = s['shipment_price'] ?? 0;
    final fee = s['delivery_fee'] ?? 0;
    final weight = s['weight_kg']?.toString() ?? '-';
    final imageUrl = s['image_url'] as String?;
    final isProcessing =
        shipmentId.isNotEmpty && _processingIds.contains(shipmentId);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(8),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Icon(
                        Icons.inventory_2,
                        color: Color(0xFFD68A4A),
                        size: 24,
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$weight كغ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              from,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              to,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$price',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$fee',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'courier.dashboard.status.pending_text'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF856404),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isProcessing || shipmentId.isEmpty
                        ? null
                        : () => _acceptShipment(shipmentId, (price as num).toDouble()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'courier.accept'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'courier.dashboard.actions.temporary_deposit'.tr(namedArgs: {'price': '$price EGP'}),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRow(Map<String, dynamic> s) {
    final shipmentId = s['id']?.toString() ?? '';
    final rawId = s['id']?.toString() ?? '00000000';
    final tracking = 'T-${rawId.substring(0, min(7, rawId.length))}';
    final from = s['pickup_address'] ?? '';
    final to = s['delivery_address'] ?? '';
    final price = s['shipment_price'] ?? 0;
    final status = s['status'] as String? ?? '';
    final isProcessing =
        shipmentId.isNotEmpty && _processingIds.contains(shipmentId);
    final canDeliver = status == 'accepted' || status == 'in_transit';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              tracking,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              from,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              to,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$price ج.م',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getStatusText(status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    if (status == 'delivered')
                      Text(
                        'courier.dashboard.status.delivered_merchant_wait'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: canDeliver
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () => _deliverShipment(shipmentId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'courier.dashboard.actions.deliver'.tr(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'courier.dashboard.actions.confirm_fee'.tr(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    )
                  : status == 'delivered'
                  ? Center(
                      child: Text(
                        'courier.dashboard.actions.merchant_confirmed'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: canDeliver
                  ? SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'courier.dashboard.actions.report_issue'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : status == 'delivered'
                  ? SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'courier.dashboard.actions.view_payment'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF39C12);
      case 'accepted':
      case 'in_transit':
        return const Color(0xFF3498DB);
      case 'delivered':
        return const Color(0xFF2ECC71);
      case 'cancelled':
      case 'rejected':
      case 'returned':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'courier.dashboard.status.pending_text'.tr();
      case 'accepted':
        return 'courier.dashboard.status.accepted_text'.tr();
      case 'in_transit':
        return 'courier.dashboard.status.in_transit_text'.tr();
      case 'delivered':
        return 'courier.dashboard.status.delivered_text'.tr();
      case 'cancelled':
        return 'courier.dashboard.status.cancelled_text'.tr();
      case 'rejected':
      case 'returned':
        return 'courier.dashboard.status.returned_text'.tr();
      default:
        return 'courier.dashboard.status.unknown'.tr();
    }
  }
}
