final shipmentId = s['id']?.toString();
final status = s['status'] as String? ?? '';

final canAccept = shipmentId != null && status == 'pending';
final canDeliver =
    shipmentId != null &&
    (status == 'accepted' || status == 'in_transit');

return SizedBox(
  width: double.infinity,
  height: 45,
  child: ElevatedButton(
    onPressed: canAccept
        ? () => _acceptShipment(context, ref, shipmentId)
        : canDeliver
        ? () => _deliverShipment(context, ref, shipmentId)
        : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: canAccept
          ? AppColors.orangeButton
          : canDeliver
          ? AppColors.primaryBlue
          : Colors.grey,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade400,
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(
      canAccept ? 'قبول الشحنة' : 'توصيل الشحنة',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
);