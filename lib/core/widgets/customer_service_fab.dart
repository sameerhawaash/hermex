import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String _phoneNumber = '01229696427';
const String _whatsappNumber =
    '201229696427'; // International format for WhatsApp

class CustomerServiceFab extends StatefulWidget {
  const CustomerServiceFab({super.key});

  @override
  State<CustomerServiceFab> createState() => _CustomerServiceFabState();
}

class _CustomerServiceFabState extends State<CustomerServiceFab>
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

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsappNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                'خدمة العملاء',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1A237E),
                ),
              ),
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
                // Phone button
                _buildSubButton(
                  icon: Icons.phone,
                  color: const Color(0xFF1976D2),
                  label: 'اتصال',
                  onTap: _callPhone,
                ),
                const SizedBox(height: 10),
                // WhatsApp button
                _buildSubButton(
                  icon: Icons.chat,
                  color: const Color(0xFF25D366),
                  label: 'واتساب',
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
              color: _isOpen ? Colors.red.shade400 : const Color(0xFFFF8800),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isOpen ? Colors.red : const Color(0xFFFF8800))
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
