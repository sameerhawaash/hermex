import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

// Stream provider for the authenticated user session state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Future provider for fetching the user profile data from public.users
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Watch auth state changes so this provider recalculates when a user logs in or out
  ref.watch(authStateProvider);

  final repository = ref.watch(authRepositoryProvider);
  return await repository.getCurrentUserProfile();
});
