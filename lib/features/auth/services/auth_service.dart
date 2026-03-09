import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

abstract class IAuthService {
  Future<void> sendOtp(String contact);
  Future<AuthResponse> verifyOtp(String contact, String token);

  Future<void> syncUserRecord(User user);
  Future<void> signOut();
  User? get currentUser;
}

class SupabaseAuthService implements IAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Future<void> sendOtp(String contact) async {
    // Modular approach: currently treats 'contact' as email.
    // Later can be updated to check if contact is email or phone.
    await _supabase.auth.signInWithOtp(email: contact);
  }

  @override
  Future<AuthResponse> verifyOtp(String contact, String token) async {
    // Modular approach: currently treats 'contact' as email token.
    return await _supabase.auth.verifyOTP(
      type: OtpType.email,
      token: token,
      email: contact,
    );
  }

  @override
  Future<void> syncUserRecord(User user) async {
    // Check if user exists in "users" table.
    final response = await _supabase
        .from('users')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      final metadata = user.userMetadata ?? {};
      final fullName = metadata['full_name'] as String? ?? 'New User';
      final avatarUrl = metadata['avatar_url'] as String?;

      // If not exists, create new user record
      // Wallet balance is auto-created by DB trigger handle_new_user_wallet
      final insertData = {
        'id': user.id,
        'email': user.email ?? '',
        'role': 'merchant', // default
        'full_name': fullName,
        'phone': user.email ?? user.id, // Fallback for unique constraint
        'governorate': 'Cairo',
      };
      if (avatarUrl != null) {
        insertData['avatar_url'] = avatarUrl;
      }

      try {
        await _supabase.from('users').insert(insertData);
      } catch (e) {
        // Just ignore any error here. It's usually a duplicate key
        // violation (23505) if the user was already created by a trigger
        // or concurrent request. We don't want to crash the app.
        debugPrint('Warning: syncUserRecord failed: $e');
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
