import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/wallet_repository.dart';
import '../../../auth/data/auth_provider.dart';

final currentWalletProvider = StreamProvider.autoDispose<Map<String, dynamic>?>(
  (ref) {
    final repository = ref.watch(walletRepositoryProvider);
    final user = ref.watch(userProfileProvider).value;

    if (user == null) return const Stream.empty();

    return repository.getWalletStream(user['id']);
  },
);

/// Fetches the transaction history for the current user's wallet.
final walletTransactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repository = ref.watch(walletRepositoryProvider);
      final user = ref.watch(userProfileProvider).value;
      if (user == null) return [];
      return repository.getTransactions(user['id']);
    });
