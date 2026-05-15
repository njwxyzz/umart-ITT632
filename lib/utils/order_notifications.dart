import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Writes an in-app notification to the buyer's inbox (not FCM).
Future<void> notifyBuyerOrderStatus({
  required String buyerId,
  required String orderId,
  required String newStatus,
  String? sellerName,
}) async {
  final uid = buyerId.trim();
  if (uid.isEmpty) return;

  final String title;
  final String body;
  final String type;

  switch (newStatus) {
    case 'Processing':
      title = 'Order accepted';
      final store = (sellerName ?? '').trim();
      body = store.isNotEmpty
          ? '$store accepted your order. It is now being prepared.'
          : 'Your order was accepted and is being prepared.';
      type = 'order_accepted';
      break;
    case 'Rejected':
    case 'Cancelled':
      title = 'Order cancelled';
      final store = (sellerName ?? '').trim();
      body = store.isNotEmpty
          ? '$store could not fulfil your order. It has been cancelled.'
          : 'Your order was cancelled by the seller.';
      type = 'order_rejected';
      break;
    default:
      return;
  }

  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'orderId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e, st) {
    debugPrint('notifyBuyerOrderStatus failed: $e\n$st');
  }
}
