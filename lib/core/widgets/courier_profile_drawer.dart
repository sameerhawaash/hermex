import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/shipments/presentation/providers/shipment_providers.dart';
import '../../features/wallet/presentation/providers/wallet_providers.dart';

class CourierProfileDrawer extends ConsumerStatefulWidget {
  const CourierProfileDrawer({super.key});

  @override
  ConsumerState<CourierProfileDrawer> createState() =>
      _CourierProfileDrawerState();
}

class _CourierProfileDrawerState extends ConsumerState<CourierProfileDrawer> {
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

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': imageUrl}),
      );

      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة بنجاح!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في رفع الصورة: تأكد من وجود Bucket باسم avatars. ${e.toString()}',
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
              title: const Text('تعديل البيانات', textAlign: TextAlign.right),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالكامل',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
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
                      : const Text('حفظ'),
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
    final myShipmentsAsync = ref.watch(courierShipmentsProvider);
    final walletAsync = ref.watch(currentWalletProvider);

    return Drawer(
      backgroundColor: AppColors.skyBlueBg,
      child: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'طيارك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // White card
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
                          return const Center(child: Text('رجاءً سجل الدخول'));
                        }
                        return _buildProfileContent(
                          profile,
                          myShipmentsAsync,
                          walletAsync,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('خطأ: $err')),
                    ),
                  ),
                  // Avatar floating circle
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
    AsyncValue<List<Map<String, dynamic>>> myShipmentsAsync,
    AsyncValue<Map<String, dynamic>?> walletAsync,
  ) {
    final fullName = profile['full_name'] ?? 'مستخدم غير معروف';
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
          const SizedBox(height: 20),

          // Wallet balance chip
          walletAsync.when(
            data: (wallet) {
              final balance = (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/courier/wallet');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'المحفظة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${balance.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: myShipmentsAsync.when(
              data: (shipments) {
                int delivered = shipments
                    .where((s) => s['status'] == 'delivered')
                    .length;
                int inTransit = shipments
                    .where(
                      (s) =>
                          s['status'] == 'accepted' ||
                          s['status'] == 'in_transit',
                    )
                    .length;
                int rejected = shipments
                    .where((s) => s['status'] == 'rejected')
                    .length;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildStatButton(
                      title: 'شحنات تم تسليمها',
                      count: delivered,
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      bgColor: Colors.green.shade50,
                    ),
                    const SizedBox(height: 10),
                    _buildStatButton(
                      title: 'جاري توصيلها',
                      count: inTransit,
                      icon: Icons.local_shipping,
                      iconColor: Colors.blue,
                      bgColor: Colors.blue.shade50,
                    ),
                    const SizedBox(height: 10),
                    _buildStatButton(
                      title: 'مرتجعة',
                      count: rejected,
                      icon: Icons.cancel,
                      iconColor: Colors.red,
                      bgColor: Colors.red.shade50,
                    ),
                    const SizedBox(height: 20),
                    // Edit profile
                    TextButton.icon(
                      onPressed: () => _showEditDialog(profile),
                      icon: const Icon(Icons.edit, color: AppColors.lightBlue),
                      label: const Text(
                        'تعديل البيانات',
                        style: TextStyle(
                          color: AppColors.lightBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Logout
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/');
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Text('خطأ في جلب الشحنات'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
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
