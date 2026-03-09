import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthStateData {
  final bool isLoading;
  final String? errorMessage;

  AuthStateData({this.isLoading = false, this.errorMessage});

  AuthStateData copyWith({bool? isLoading, String? errorMessage}) {
    // We intentionally allow clearing errorMessage by checking if the caller passed a value,
    // but to keep it simple, if errorMessage is explicitly passed as null, we want to clear it?
    // Dart doesn't support differentiating "not passed" vs "passed null" easily in copyWith without tricks,
    // so we'll just use a 'clearError' flag if we really need it, or we handle it directly in the Notifier.
    return AuthStateData(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage, // Notice we don't fallback to this.errorMessage if we want to clear it, but here we just replace it.
    );
  }
}

class AuthNotifier extends Notifier<AuthStateData> {
  late final IAuthService _authService;

  @override
  AuthStateData build() {
    _authService = SupabaseAuthService();
    return AuthStateData();
  }

  // Sends OTP to the provided contact (email)
  Future<bool> sendOtp(String contact) async {
    state = AuthStateData(isLoading: true, errorMessage: null);
    try {
      await _authService.sendOtp(contact);
      state = AuthStateData(isLoading: false, errorMessage: null);
      return true;
    } catch (e) {
      state = AuthStateData(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Verifies OTP and syncs user
  Future<bool> verifyOtp(String contact, String token) async {
    state = AuthStateData(isLoading: true, errorMessage: null);
    try {
      final response = await _authService.verifyOtp(contact, token);
      if (response.user != null) {
        await _authService.syncUserRecord(response.user!);
        state = AuthStateData(isLoading: false, errorMessage: null);
        return true;
      }
      state = AuthStateData(
        isLoading: false,
        errorMessage: 'Verification failed. No user found.',
      );
      return false;
    } catch (e) {
      state = AuthStateData(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthStateData(); // Reset state
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStateData>(() {
  return AuthNotifier();
});
