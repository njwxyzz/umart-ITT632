// Firestore `stores` documents use `status`: Pending | Approved | Rejected.
// Older documents without `status` are treated as approved so existing sellers keep working.

String storeStatusLabel(Map<String, dynamic>? data) {
  if (data == null) return '';
  final s = (data['status'] ?? '').toString().trim();
  if (s.isEmpty) return 'Approved';
  return s;
}

bool storeIsApproved(Map<String, dynamic>? data) {
  final label = storeStatusLabel(data);
  return label == 'Approved';
}

bool storeIsPending(Map<String, dynamic>? data) {
  return storeStatusLabel(data) == 'Pending';
}

bool storeIsRejected(Map<String, dynamic>? data) {
  return storeStatusLabel(data) == 'Rejected';
}
