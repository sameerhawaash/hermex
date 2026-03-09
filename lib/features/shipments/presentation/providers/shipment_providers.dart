import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/shipment_repository.dart';
import '../../../auth/data/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as import_supabase;

// Provider for available shipments (For Couriers)
final availableShipmentsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final repository = ref.watch(shipmentRepositoryProvider);
      return repository.getAvailableShipments();
    });

// Provider for merchant's own shipments
final merchantShipmentsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final repository = ref.watch(shipmentRepositoryProvider);
      final user = ref.watch(userProfileProvider).value;

      if (user == null) return const Stream.empty();

      return repository.getMerchantShipments(user['id']);
    });

// Provider for courier's active/past shipments
final courierShipmentsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final repository = ref.watch(shipmentRepositoryProvider);
      final user = ref.watch(userProfileProvider).value;

      if (user == null) return const Stream.empty();

      return repository.getCourierShipments(user['id']);
    });

// Provider to fetch single user details (for merchant info on shipment cards)
final userDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final client = import_supabase.Supabase.instance.client;
      final res = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return res;
    });
