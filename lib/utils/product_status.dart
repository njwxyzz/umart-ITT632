// Firestore `products` use `status`: Pending | Approved | Rejected.
// Missing `status` is treated as Approved (existing listings before moderation).

String productStatusLabel(Map<String, dynamic>? data) {
  if (data == null) return '';
  final s = (data['status'] ?? '').toString().trim();
  if (s.isEmpty) return 'Approved';
  return s;
}

bool productIsApproved(Map<String, dynamic>? data) {
  return productStatusLabel(data) == 'Approved';
}

bool productIsPending(Map<String, dynamic>? data) {
  return productStatusLabel(data) == 'Pending';
}

bool productIsRejected(Map<String, dynamic>? data) {
  return productStatusLabel(data) == 'Rejected';
}
