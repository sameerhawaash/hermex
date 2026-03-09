import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// خطأ مخصص: البريد الإلكتروني غير مؤكد
class EmailNotConfirmedException implements Exception {
  final String email;
  EmailNotConfirmedException(this.email);

  @override
  String toString() => 'Email not confirmed: $email';
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Sign Up a new user
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
    required String phone,
    required String governorate,
    String? storeName,
  }) async {
    try {
      // 1. Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('فشل في إنشاء الحساب. تأكد من صحة البيانات.');
      }

      // Check for email enumeration protection (fake user object)
      // When email already exists, Supabase returns a user with empty identities.
      if (user.identities == null || user.identities!.isEmpty) {
        throw Exception(
          'هذا البريد الإلكتروني مسجل مسبقاً، رُبما تحتاج لتسجيل الدخول.',
        );
      }

      // 2. Insert into public.users table or update if trigger created it
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': email,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'governorate': governorate,
        'store_name': ?storeName,
      }, onConflict: 'id');
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw EmailNotConfirmedException(email);
      }
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Resend confirmation email
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get Current User Profile Data from public.users
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  // Auth State Changes Stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
