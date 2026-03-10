import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(Supabase.instance.client);
});

class WalletRepository {
  final SupabaseClient _supabase;

  WalletRepository(this._supabase);

  // ─────────────────────────────────────────────────────────────────────────
  // Real-time wallet balance stream
  // ─────────────────────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>?> getWalletStream(String userId) {
    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch transactions for a wallet by user ID
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactions(String userId) async {
    final wallet = await _supabase
        .from('wallets')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (wallet == null) return [];
    final walletId = wallet['id'] as String;
    final res = await _supabase
        .from('transactions')
        .select()
        .eq('wallet_id', walletId)
        .order('created_at', ascending: false);
    return res;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initiates Kashier payment session.
  // Returns a record with the signed [paymentUrl] and the [orderId] that
  // Kashier will echo back in the redirect URL so we can match the transaction.
  // ─────────────────────────────────────────────────────────────────────────
  Future<({String paymentUrl, String orderId})> startKashierCheckout({
    required double amount,
  }) async {
    final response = await _supabase.functions.invoke(
      'kashier-checkout',
      body: {'amount': amount},
    );

    if (response.status != 200) {
      final err = response.data?['error'] ?? 'Payment initiation failed';
      throw Exception(err);
    }

    final paymentUrl = response.data?['paymentUrl'] as String?;
    final orderId = response.data?['orderId'] as String?;

    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw Exception('No payment URL returned from server');
    }
    if (orderId == null || orderId.isEmpty) {
      throw Exception('No order ID returned from server');
    }

    return (paymentUrl: paymentUrl, orderId: orderId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Confirms a Kashier payment client-side (Webhook fallback).
  //
  // Called after the WebView detects a success redirect from Kashier.
  // Guards against double-crediting: if a transaction with this [orderId]
  // already has status = 'completed' (e.g. Webhook fired first), it skips
  // the balance update to prevent adding the amount twice.
  //
  // When a Webhook IS active in production, the Webhook will write the
  // transaction first; this method then becomes a no-op (returns silently).
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> confirmKashierPayment({
    required String orderId,
    required double amount,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Call the secure RPC to confirm Kashier payment
    // The RPC should check if the orderId was already processed to avoid double-crediting
    await _supabase.rpc(
      'confirm_kashier_payment',
      params: {'p_user_id': userId, 'p_order_id': orderId, 'p_amount': amount},
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin manual deposit (legacy — for admin panel use only)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> adminDeposit({
    required String adminId,
    required String walletId,
    required double amount,
  }) async {
    // Call the secure admin deposit RPC
    await _supabase.rpc(
      'admin_deposit',
      params: {
        'p_admin_id': adminId,
        'p_wallet_id': walletId,
        'p_amount': amount,
      },
    );
  }
}
