import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to interact with the Support Settings in Supabase
class SupportService {
  final SupabaseClient _supabase;

  SupportService(this._supabase);

  /// Fetches the current WhatsApp support number from the settings table.
  /// Falls back to a default number if not found or on error.
  Future<String> getSupportWhatsAppNumber() async {
    try {
      final response = await _supabase
          .from('settings')
          .select('support_whatsapp')
          .eq('id', '00000000-0000-0000-0000-000000000000') // Updated to use a valid UUID
          .single();
      
      return response['support_whatsapp'] as String;
    } catch (e) {
      // Return a fallback default number in case of any read issues
      // so the user is never left without a way to contact support.
      return '00201229696427';
    }
  }

  /// Updates the WhatsApp support number. (Used by Admin App)
  Future<void> updateSupportWhatsAppNumber(String newNumber) async {
    await _supabase
        .from('settings')
        .upsert({
          'id': '00000000-0000-0000-0000-000000000000', // Updated to use a valid UUID
          'support_whatsapp': newNumber,
        });
  }
}

/// Provider for the SupportService
final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(Supabase.instance.client);
});

/// FutureProvider to fetch the WhatsApp number asynchronously
final supportNumberProvider = FutureProvider<String>((ref) async {
  final service = ref.read(supportServiceProvider);
  return await service.getSupportWhatsAppNumber();
});
