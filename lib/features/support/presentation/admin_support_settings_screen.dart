import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// NOTE TO THE DEVELOPER:
/// This file is meant to be copied to your **Admin/Owner Application**.
/// It provides a ready-to-use screen to view and update the WhatsApp support number
/// in the Supabase 'settings' table.
class SupportSettingsScreen extends StatefulWidget {
  const SupportSettingsScreen({Key? key}) : super(key: key);

  @override
  _SupportSettingsScreenState createState() => _SupportSettingsScreenState();
}

class _SupportSettingsScreenState extends State<SupportSettingsScreen> {
  final TextEditingController _numberController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCurrentNumber();
  }

  Future<void> _fetchCurrentNumber() async {
    try {
      final response = await _supabase
          .from('settings')
          .select('support_whatsapp')
          .eq('id', '00000000-0000-0000-0000-000000000000')
          .single();

      setState(() {
        _numberController.text = response['support_whatsapp']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في جلب الرقم: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNumber() async {
    final newNumber = _numberController.text.trim();
    if (newNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم واتساب صحيح')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _supabase.from('settings').upsert({
        'id': '00000000-0000-0000-0000-000000000000',
        'support_whatsapp': newNumber,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ رقم الواتساب بنجاح! سيتم تطبيقه فوراً على جميع المستخدمين.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الدعم'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'رقم واتساب خدمة العملاء',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذا الرقم سيظهر لجميع التجار والطيارين في زر خدمة العملاء. يرجى إدخال الرقم متضمناً مفتاح الدولة (مثال: 002010... أو 2010...).',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _numberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الواتساب',
                      hintText: '00201...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _saveNumber,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الرقم'),
                  ),
                ],
              ),
            ),
    );
  }
}
