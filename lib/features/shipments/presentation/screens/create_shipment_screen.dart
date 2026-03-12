import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/shipment_repository.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _shipmentPriceController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _detailsController = TextEditingController(); // Aesthetic field
  final _weightController = TextEditingController(); // Aesthetic field

  final ImagePicker _picker = ImagePicker();
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  bool _isLoading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final fileExt = image.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_shipment.$fileExt';
      final path = '$fileName';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await Supabase.instance.client.storage
            .from('shipments')
            .uploadBinary(path, bytes);
      } else {
        await Supabase.instance.client.storage
            .from('shipments')
            .upload(path, File(image.path));
      }

      final imageUrl = Supabase.instance.client.storage
          .from('shipments')
          .getPublicUrl(path);

      setState(() => _uploadedImageUrl = imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم رفع الصورة بنجاح!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في رفع الصورة: تأكد من وجود Bucket باسم shipments. ${e.toString()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _shipmentPriceController.dispose();
    _deliveryFeeController.dispose();
    _detailsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submitShipment() async {
    final pickup = _pickupAddressController.text.trim();
    final delivery = _deliveryAddressController.text.trim();
    final productName = _detailsController.text.trim();
    final weightStr = _weightController.text.trim();
    final priceStr = _shipmentPriceController.text.trim();
    final feeStr = _deliveryFeeController.text.trim();

    if (pickup.isEmpty ||
        delivery.isEmpty ||
        productName.isEmpty ||
        priceStr.isEmpty ||
        feeStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول الأساسية')),
      );
      return;
    }

    final price = double.tryParse(priceStr);
    final fee = double.tryParse(feeStr);
    final weight = double.tryParse(weightStr);

    if (price == null || fee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال قيم رقمية صحيحة للسعر والرسوم'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('غير مصرح لك بالدخول، يرجى تسجيل الدخول مرة أخرى.');
      }

      final merchantId = currentUser.id;
      final repository = ref.read(shipmentRepositoryProvider);

      await repository.createShipment(
        merchantId: merchantId,
        productName: productName,
        weightKg: weight,
        imageUrl: _uploadedImageUrl,
        pickupAddress: pickup,
        deliveryAddress: delivery,
        shipmentPrice: price,
        deliveryFee: fee,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة طلب الشحن بنجاح')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الإضافة: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyBlueBg,
      appBar: AppBar(
        title: const Text(
          'فوريرة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.orangeButton,
        // The framework automatically adds a back button here because GoRouter pushed this route!
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'من (عنوان الاستلام)',
                            hint: 'مثال: مدينة نصر',
                            icon: Icons.location_on_outlined,
                            controller: _pickupAddressController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: 'إلى (عنوان التسليم)',
                            hint: 'مثال: طنطا',
                            icon: Icons.map_outlined,
                            controller: _deliveryAddressController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      label: 'وصف البضائع',
                      hint: 'مثال: قطع غيار سيارة، ملابس، إلخ...',
                      icon: Icons.inventory_2_outlined,
                      controller: _detailsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploader(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'الوزن (كغ)',
                            hint: '0.00',
                            icon: Icons.scale_outlined,
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child:
                              SizedBox(), // Empty spacer to match the design logic
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'سعر الشحنة (جنيه مصري)',
                            hint: '50.00',
                            icon: Icons.attach_money,
                            controller: _shipmentPriceController,
                            keyboardType: TextInputType.number,
                            helperText: 'السعر الذي يحدده التاجر للشحنة',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: 'سعر التوصيل (جنيه مصري)',
                            hint: '5.00',
                            icon: Icons.local_shipping_outlined,
                            iconColor: Colors.green,
                            borderColor: Colors.green.shade200,
                            controller: _deliveryFeeController,
                            keyboardType: TextInputType.number,
                            helperText: 'أجرة توصيل الشحنة (الطيار يحصل عليها)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeButton,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitShipment,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isLoading ? 'جاري الإنشاء...' : 'إنشاء الشحنة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'صورة الشحنة (اختياري)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.image_outlined, color: AppColors.orangeButton, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        if (_isUploadingImage)
          const Center(child: CircularProgressIndicator())
        else if (_uploadedImageUrl != null)
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_uploadedImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _uploadedImageUrl = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.orangeButton,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.orangeButton),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text(
                'إضافة صورة للشحنة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? helperText,
    Color iconColor = AppColors.orangeButton,
    Color borderColor = Colors.grey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: iconColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
