import 'package:flutter/material.dart';

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
  // --- Dummy Data for Orders ---
  // In a real app, this will come from Firebase Firestore
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#UM-9021',
      'buyerName': 'Ahmad Zaki',
      'location': 'Kolej Dahlia 3, Room 102',
      'time': 'Just now',
      'items': '2x Nasi Lemak, 1x Teh Tarik',
      'total': 15.00,
      'status': 'Pending', // Pending, Processing, Delivered, Rejected
    },
    {
      'id': '#UM-9018',
      'buyerName': 'Sarah Liyana',
      'location': 'Kolej Mawar 2, Room 410',
      'time': '10 mins ago',
      'items': '1x White Chocojar',
      'total': 12.50,
      'status': 'Processing',
    },
    {
      'id': '#UM-8990',
      'buyerName': 'Irfan Hakim',
      'location': 'Kolej Delima, Room 211',
      'time': 'Yesterday',
      'items': '3x Printing (A4 B&W)',
      'total': 3.00,
      'status': 'Delivered',
    },
  ];

  // --- Functions to update order status (Simulating Backend) ---
  void _updateOrderStatus(String orderId, String newStatus) {
    setState(() {
      final index = _orders.indexWhere((order) => order['id'] == orderId);
      if (index != -1) {
        _orders[index]['status'] = newStatus;
      }
    });

    // Show a quick success pop-up
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order $orderId marked as $newStatus!', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: newStatus == 'Rejected' ? Colors.red.shade400 : kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter orders based on their status
    final pendingOrders = _orders.where((o) => o['status'] == 'Pending').toList();
    final activeAndPastOrders = _orders.where((o) => o['status'] != 'Pending').toList();

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
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(25)),
                  labelColor: kWhite,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: 'New Requests (${pendingOrders.length})'),
                    const Tab(text: 'Active & Past'),
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
          child: TabBarView(
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
          ),
        ),
      ),
    );
  }

  // HELPER WIDGET: Order Card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'];

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
              Text(order['id'], style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary, fontSize: 14)),
              Text(order['time'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
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
                    Text(order['buyerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: kAccent),
                        const SizedBox(width: 4),
                        Expanded(child: Text(order['location'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(order['items'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                  ],
                ),
              ),
              // Price
              Text('RM ${order['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1A2E))),
            ],
          ),

          const SizedBox(height: 16),

          // Footer: Action Buttons based on Status
          if (status == 'Pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateOrderStatus(order['id'], 'Rejected'),
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
                    onPressed: () => _updateOrderStatus(order['id'], 'Processing'),
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
                onPressed: () => _updateOrderStatus(order['id'], 'Delivered'),
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