import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {

  // --- Functions to update order status (Now talking to Firebase!) ---
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      if (mounted) {
        // Show a quick success pop-up
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as $newStatus!', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: newStatus == 'Rejected' ? Colors.red.shade400 : kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current seller's UID
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Incoming Orders', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 45,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25)),
                child: const TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.all(Radius.circular(25))),
                  labelColor: kWhite,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'New Requests'),
                    Tab(text: 'Active & Past'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_pattern.jpg'),
              repeat: ImageRepeat.repeat,
              opacity: 0.05, 
            ),
          ),
          // --- KITA LETAK STREAMBUILDER KAT SINI ---
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('sellerId', isEqualTo: currentUserId) // Filter orders for this seller
                .snapshots(),
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimary));
              }

              List<QueryDocumentSnapshot> allOrders = snapshot.hasData ? snapshot.data!.docs : [];

              // Filter the data based on status for the two tabs
              final pendingOrders = allOrders.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'Pending';
              }).toList();
              
              final activeAndPastOrders = allOrders.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return data['status'] != 'Pending';
              }).toList();

              return TabBarView(
                children: [
                  // --- TAB 1: PENDING ORDERS ---
                  pendingOrders.isEmpty 
                    ? _buildEmptyState('No new orders right now.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: pendingOrders.length,
                        itemBuilder: (context, index) => _buildOrderCard(pendingOrders[index]),
                      ),

                  // --- TAB 2: ACTIVE & PAST ORDERS ---
                  activeAndPastOrders.isEmpty
                    ? _buildEmptyState('No active or past orders.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: activeAndPastOrders.length,
                        itemBuilder: (context, index) => _buildOrderCard(activeAndPastOrders[index]),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // HELPER WIDGET: Order Card (Now takes DocumentSnapshot to get ID and Data)
  Widget _buildOrderCard(QueryDocumentSnapshot doc) {
    var order = doc.data() as Map<String, dynamic>;
    String orderId = doc.id; // Get the Firestore Document ID
    
    final status = order['status'] ?? 'Pending';
    double totalPrice = order['totalPrice'] is num ? (order['totalPrice'] as num).toDouble() : 0.0;

    // Format a simple order number from the first 5 chars of the document ID
    String displayId = '#UM-${orderId.substring(0, 5).toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order ID & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(displayId, style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary, fontSize: 14)),
              Text('Just now', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)), // You can add timestamp formatting later
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          
          // Body: Buyer Info & Items
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_rounded, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['buyerName'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: kAccent),
                        const SizedBox(width: 4),
                        Expanded(child: Text(order['buyerLocation'] ?? 'UiTM Campus', style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Item list
                    Text('1x ${order['productName'] ?? 'Item'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                    if (order['note'] != null && order['note'].toString().isNotEmpty)
                      Text('📝 ${order['note']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              // Price
              Text('RM ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1A2E))),
            ],
          ),

          const SizedBox(height: 16),

          // Footer: Action Buttons based on Status
          if (status == 'Pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateOrderStatus(orderId, 'Rejected'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Reject', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(orderId, 'Processing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          else if (status == 'Processing')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(orderId, 'Delivered'),
                icon: const Icon(Icons.check_circle_outline_rounded, color: kWhite, size: 18),
                label: const Text('Mark as Delivered', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else 
            // Delivered or Rejected Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: status == 'Delivered' ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  status == 'Delivered' ? 'Completed' : 'Order Rejected',
                  style: TextStyle(
                    color: status == 'Delivered' ? Colors.green.shade700 : Colors.red.shade700, 
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  // HELPER WIDGET: Empty State
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}