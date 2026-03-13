import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/support/data/support_service.dart';

const String _phoneNumber = '01229696427';

/// FAB is now a ConsumerStatefulWidget so it can read Riverpod providers
class CustomerServiceFab extends ConsumerStatefulWidget {
  const CustomerServiceFab({super.key});

  @override
  ConsumerState<CustomerServiceFab> createState() =>
      _CustomerServiceFabState();
}

class _CustomerServiceFabState extends ConsumerState<CustomerServiceFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _callPhone() async {
    final uri = Uri(scheme: 'tel', path: _phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Opens WhatsApp using the dynamic support number and pre-filled message structure.
  Future<void> _openWhatsApp() async {
    _toggle(); // close FAB before launching

    // 1. Fetch dynamic support number
    final supportNumber = await ref.read(supportNumberProvider.future);

    // 2. Fetch User Information
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'غير معروف';
    final rawRole = user?.userMetadata?['role'] as String?;
    
    String roleText = 'مستخدم';
    if (rawRole == 'merchant') roleText = 'تاجر';
    if (rawRole == 'courier') roleText = 'طيار';

    // Read the user profile synchronously from the cached provider
    final profileAsync = ref.read(userProfileProvider);
    final userName = profileAsync.when(
      data: (profile) =>
          (profile?['full_name'] as String?)?.trim().isNotEmpty == true
              ? profile!['full_name'] as String
              : 'عميل',
      loading: () => 'عميل',
      error: (_, __) => 'عميل',
    );

    // 3. Format message
    final String messageText = '''مرحبا
أنا $roleText في تطبيق فوريرة وأحتاج مساعدة

الاسم: $userName
المعرف: $userId''';

    final message = Uri.encodeComponent(messageText);
    final uri = Uri.parse('https://wa.me/$supportNumber?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب، يرجى التأكد من تثبيته.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Label on top when closed
        if (!_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'customer_service',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1A237E),
                ),
              ).tr(),
            ),
          ),

        // Expanded sub buttons
        FadeTransition(
          opacity: _expandAnimation,
          child: SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSubButton(
                  icon: Icons.phone,
                  color: const Color(0xFF1976D2),
                  label: 'call'.tr(),
                  onTap: _callPhone,
                ),
                const SizedBox(height: 10),
                _buildSubButton(
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  label: 'whatsapp'.tr(),
                  onTap: _openWhatsApp,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // Main toggle button
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  _isOpen ? Colors.red.shade400 : const Color(0xFFFF8800),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_isOpen ? Colors.red : const Color(0xFFFF8800))
                          .withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 25),
              turns: _isOpen ? 0.125 : 0,
              child: Icon(
                _isOpen ? Icons.close : Icons.support_agent,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
