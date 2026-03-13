import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/shipments/presentation/providers/shipment_providers.dart';
import '../../features/wallet/presentation/providers/wallet_providers.dart';

class ProfileDrawer extends ConsumerStatefulWidget {
  const ProfileDrawer({super.key});

  @override
  ConsumerState<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<ProfileDrawer> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() => _isUploading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      final fileExt = image.path.split('.').last;
      final fileName = '${user.id}_avatar.$fileExt';
      final path = 'avatars/$fileName';

      // Ensure 'avatars' bucket exists in Supabase. If not, this throws an error!
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(
              path,
              File(image.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      // Save to Auth Metadata so it can be retrieved globally
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      // Refresh Profile Provider
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('drawer.alerts.image_upload_success'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'drawer.alerts.image_upload_fail'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> currentProfile) async {
    final nameController = TextEditingController(
      text: currentProfile['full_name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: currentProfile['phone'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('drawer.edit_profile'.tr(), textAlign: TextAlign.right),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'drawer.full_name'.tr(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'drawer.phone'.tr()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('auth.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setStateDialog(() => isLoading = true);
                          try {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            if (user == null) throw Exception('لا يوجد مستخدم');

                            await Supabase.instance.client
                                .from('users')
                                .update({
                                  'full_name': nameController.text.trim(),
                                  'phone': phoneController.text.trim(),
                                })
                                .eq('id', user.id);

                            ref.invalidate(userProfileProvider);
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          } catch (e) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                            setStateDialog(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('drawer.save'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final merchantShipmentsAsync = ref.watch(merchantShipmentsProvider);
    final courierShipmentsAsync = ref.watch(courierShipmentsProvider);

    return Drawer(
      backgroundColor: AppColors.skyBlueBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) {
                      final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
                      return Image.asset(
                        isRtl ? 'assets/images/logo_ar1.png' : 'assets/images/logo_en1.png',
                        height: 80, // Increased height per user request
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: AppColors.orangeButton),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                      top: 60,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: userProfileAsync.when(
                      data: (profile) {
                        if (profile == null) {
                          return Center(child: Text('drawer.please_login'.tr()));
                        }

                        final role = profile['role'];
                        final isCourier = role == 'courier';
                        final shipmentsAsync = isCourier
                            ? courierShipmentsAsync
                            : merchantShipmentsAsync;

                        return _buildProfileContent(
                          profile,
                          isCourier,
                          shipmentsAsync,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('خطأ: $err')),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.lightBlue,
                              backgroundImage:
                                  Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.userMetadata?['avatar_url'] !=
                                      null
                                  ? NetworkImage(
                                      Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser!
                                          .userMetadata!['avatar_url'],
                                    )
                                  : null,
                              child:
                                  Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.userMetadata?['avatar_url'] ==
                                      null
                                  ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            if (_isUploading)
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            if (!_isUploading)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.orangeButton,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    Map<String, dynamic> profile,
    bool isCourier,
    AsyncValue<List<Map<String, dynamic>>> shipmentsAsync,
  ) {
    final fullName = profile['full_name'] ?? 'drawer.unknown_user'.tr();
    final phone = profile['phone'] ?? '+20 000 000 0000';
    final email = profile['email'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
      child: Column(
        children: [
          Text(
            fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          Expanded(
            child: shipmentsAsync.when(
              data: (shipments) {
                if (isCourier) {
                  return _buildCourierStats(shipments, profile);
                } else {
                  return _buildMerchantStats(shipments, profile);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('drawer.alerts.fetch_error'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierStats(
    List<Map<String, dynamic>> shipments,
    Map<String, dynamic> profile,
  ) {
    int delivered = shipments.where((s) => s['status'] == 'delivered').length;
    int inTransit = shipments
        .where((s) => s['status'] == 'accepted' || s['status'] == 'in_transit')
        .length;
    int rejected = shipments.where((s) => s['status'] == 'rejected').length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Wallet Balance Header
        Consumer(
          builder: (context, ref, _) {
            final walletAsync = ref.watch(currentWalletProvider);
            return walletAsync.when(
              data: (wallet) {
                final balance = (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/courier/wallet');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'drawer.courier_stats.wallet_balance'.tr(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${balance.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => const SizedBox.shrink(),
            );
          },
        ),

        // Stats Cards
        _buildStatCard(
          title: 'drawer.courier_stats.delivered'.tr(),
          count: delivered,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          bgColor: Colors.green.shade50,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'drawer.courier_stats.in_transit'.tr(),
          count: inTransit,
          icon: Icons.local_shipping,
          iconColor: Colors.blue,
          bgColor: Colors.blue.shade50,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'drawer.courier_stats.returned'.tr(),
          count: rejected,
          icon: Icons.cancel,
          iconColor: Colors.red,
          bgColor: Colors.red.shade50,
        ),

        const SizedBox(height: 24),
        _buildActionButtons(profile),
      ],
    );
  }

  Widget _buildMerchantStats(
    List<Map<String, dynamic>> shipments,
    Map<String, dynamic> profile,
  ) {
    int accepted = shipments.where((s) => s['status'] == 'accepted').length;
    int pending = shipments.where((s) => s['status'] == 'pending').length;
    int delivered = shipments.where((s) => s['status'] == 'delivered').length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildStatCard(
          title: 'drawer.merchant_stats.accepted'.tr(),
          count: accepted,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          bgColor: Colors.green.shade50,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'drawer.merchant_stats.pending'.tr(),
          count: pending,
          icon: Icons.access_time_filled,
          iconColor: Colors.orange,
          bgColor: Colors.orange.shade50,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'drawer.merchant_stats.delivered_or_returned'.tr(),
          count: delivered,
          icon: Icons.sync,
          iconColor: Colors.deepOrange,
          bgColor: Colors.deepOrange.shade50,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeButton,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.fact_check, color: Colors.white),
            label: Text(
              'drawer.merchant_stats.confirm_delivery'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButtons(profile),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> profile) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => _showEditDialog(profile),
          icon: const Icon(Icons.edit, color: AppColors.lightBlue),
          label: Text(
            'drawer.edit_profile'.tr(),
            style: const TextStyle(
              color: AppColors.lightBlue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final router = GoRouter.of(context);
            Navigator.pop(context);
            await ref.read(authRepositoryProvider).signOut();
            router.go('/');
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(
            'drawer.logout'.tr(),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          Icon(icon, color: iconColor, size: 28),
        ],
      ),
    );
  }
}
