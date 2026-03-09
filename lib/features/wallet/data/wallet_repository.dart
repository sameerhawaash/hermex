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

    // 1. Fetch the user's wallet (single row per user)
    final wallet = await _supabase
        .from('wallets')
        .select('id, balance')
        .eq('user_id', userId)
        .single();

    final walletId = wallet['id'] as String;
    final currentBalance = (wallet['balance'] as num).toDouble();

    // 2. Check for an existing transaction with this orderId
    final existing = await _supabase
        .from('transactions')
        .select('id, status')
        .eq('wallet_id', walletId)
        .eq('reference_id', orderId)
        .maybeSingle();

    // ── Guard: if Webhook already completed it, skip to avoid double-credit ──
    if (existing != null && existing['status'] == 'completed') {
      return; // Webhook beat us to it — wallet already updated.
    }

    // 3. Credit the wallet
    await _supabase
        .from('wallets')
        .update({'balance': currentBalance + amount})
        .eq('id', walletId);

    // 4. Mark the pending transaction as completed, or insert a new one
    if (existing != null) {
      await _supabase
          .from('transactions')
          .update({'status': 'completed'})
          .eq('id', existing['id'] as String);
    } else {
      await _supabase.from('transactions').insert({
        'wallet_id': walletId,
        'amount': amount,
        'reference_type': 'deposit',
        'reference_id': orderId,
        'status': 'completed',
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin manual deposit (legacy — for admin panel use only)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> adminDeposit({
    required String adminId,
    required String walletId,
    required double amount,
  }) async {
    final wallet = await _supabase
        .from('wallets')
        .select('balance')
        .eq('id', walletId)
        .single();
    final newBalance = (wallet['balance'] as num).toDouble() + amount;

    await _supabase
        .from('wallets')
        .update({'balance': newBalance})
        .eq('id', walletId);

    await _supabase.from('transactions').insert({
      'wallet_id': walletId,
      'amount': amount,
      'reference_type': 'manual_deposit',
      'admin_id': adminId,
    });
  }
}
