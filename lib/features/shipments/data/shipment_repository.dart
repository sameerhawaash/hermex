import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepository(Supabase.instance.client);
});

class ShipmentRepository {
  final SupabaseClient _supabase;

  ShipmentRepository(this._supabase);

  // Merchant creates a shipment
  Future<void> createShipment({
    required String merchantId,
    required String productName,
    double? weightKg,
    String? imageUrl,
    required String pickupAddress,
    required String deliveryAddress,
    required double shipmentPrice,
    required double deliveryFee,
  }) async {
    final data = {
      'merchant_id': merchantId,
      'product_name': productName,
      'weight_kg': weightKg,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'shipment_price': shipmentPrice,
      'delivery_fee': deliveryFee,
      'status': 'pending',
    };
    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }
    await _supabase.from('shipments').insert(data);
  }

  // Courier accepts a shipment via RPC Escrow Wallet System
  Future<void> acceptShipment({
    required String shipmentId,
    required String courierId,
  }) async {
    await _supabase.rpc(
      'accept_shipment',
      params: {'p_shipment_id': shipmentId, 'p_courier_id': courierId},
    );
  }

  // Courier marks shipment as delivered using RPC Escrow Wallet System
  Future<void> deliverShipment({required String shipmentId}) async {
    await _supabase.rpc(
      'deliver_shipment',
      params: {'p_shipment_id': shipmentId},
    );
  }

  // Streams for real-time tracking
  Stream<List<Map<String, dynamic>>> getMerchantShipments(String merchantId) {
    return _supabase
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false)
        .map((data) => data);
  }

  Stream<List<Map<String, dynamic>>> getCourierShipments(String courierId) {
    return _supabase
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('courier_id', courierId)
        .order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> getAvailableShipments() {
    return _supabase
        .from('shipments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }
}
