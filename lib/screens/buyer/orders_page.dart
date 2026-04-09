import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_detail_page.dart'; // Pastikan ni wujud!

// ─── Color Constants ─────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

// ─── Data Models ─────────────────────────────────────────────────────────────
class OrderHistory {
  final String orderId;
  final String itemName;
  final String sellerName;
  final String sellerPhoto;
  final String sellerAddress;
  final double sellerRating;
  final int sellerReviews;
  final String sellerLocation;
  final String buyerLocation;
  final DateTime dateTime;
  final double subtotal;
  final double deliveryFee;
  final String status;
  final List<OrderLineItem> items;

  const OrderHistory({
    required this.orderId,
    required this.itemName,
    required this.sellerName,
    required this.sellerPhoto,
    required this.sellerAddress,
    required this.sellerRating,
    required this.sellerReviews,
    required this.sellerLocation,
    required this.buyerLocation,
    required this.dateTime,
    required this.subtotal,
    required this.deliveryFee,
    required this.status,
    required this.items,
  });

  double get total => subtotal + deliveryFee;
}

class OrderLineItem {
  final String name;
  final int qty;
  final double price;
  const OrderLineItem({required this.name, required this.qty, required this.price});
}


// ─── Orders Page ─────────────────────────────────────────────────────────────
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  OrderHistory _fromFirestore(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    double totalPrice = data['totalPrice'] is num ? (data['totalPrice'] as num).toDouble() : 0.0;
    String rawItemName = data['productName'] ?? 'Items';

    return OrderHistory(
      orderId: doc.id,
      itemName: rawItemName,
      sellerName: data['sellerName'] ?? 'UMART Store',
      sellerPhoto: 'https://images.unsplash.com/photo-1607631568010-a87245c0daf7?w=200', 
      sellerAddress: 'UiTM Campus',
      sellerRating: 5.0,
      sellerReviews: 12,
      sellerLocation: 'UiTM Perlis',
      buyerLocation: data['buyerLocation'] ?? 'Kolej Dahlia 3',
      dateTime: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subtotal: totalPrice,
      deliveryFee: 0.0, 
      status: data['status'] ?? 'Pending',
      items: [
        OrderLineItem(name: rawItemName, qty: 1, price: totalPrice),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false, 
          title: const Text('My Orders', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 24, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.search_rounded, color: Colors.black87), onPressed: () {}),
          ],
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
                ),
              ),
            ),
          ),
        ),
        
        // 🚨 MAGIK CORAK BACKGROUND BERMULA DI SINI 🚨
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_pattern.jpg'), // Corak UiTM 
              repeat: ImageRepeat.repeat,
              opacity: 0.05, 
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('buyerId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimary));
              }

              List<OrderHistory> allOrders = [];
              if (snapshot.hasData) {
                allOrders = snapshot.data!.docs.map((doc) => _fromFirestore(doc)).toList();
              }

              final activeOrders = allOrders.where((o) => o.status == 'Pending' || o.status == 'Processing').toList();
              final completedOrders = allOrders.where((o) => o.status == 'Delivered' || o.status == 'Rejected' || o.status == 'Completed').toList();

              activeOrders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
              completedOrders.sort((a, b) => b.dateTime.compareTo(a.dateTime));

              return TabBarView(
                children: [
                  // ─── TAB 1: ACTIVE ORDERS ───
                  activeOrders.isEmpty
                    ? _buildEmptyState('No active orders', 'Your ongoing orders will appear here.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) => _buildLiveActiveCard(activeOrders[index], context),
                      ),

                  // ─── TAB 2: COMPLETED ORDERS ───
                  completedOrders.isEmpty
                    ? _buildEmptyState('No past orders', 'Order your favourite meal now!')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: completedOrders.length,
                        itemBuilder: (context, index) {
                          final order = completedOrders[index];
                          return _OrderHistoryCard(
                            order: order,
                            formatDate: _formatDate,
                            formatTime: _formatTime,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order))),
                          );
                        },
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLiveActiveCard(OrderHistory order, BuildContext context) {
    bool isPending = order.status == 'Pending';
    String displayId = '#UM-${order.orderId.substring(0, 5).toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.fastfood_rounded, color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(order.itemName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      isPending ? '● Awaiting Seller...' : '● Preparing your order...', 
                      style: TextStyle(color: isPending ? Colors.orange : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              Text(displayId, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14, 
                    backgroundColor: isPending ? Colors.grey.shade400 : kPrimary, 
                    child: Icon(isPending ? Icons.hourglass_empty_rounded : Icons.moped_rounded, size: 16, color: kWhite)
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPending ? 'Waiting for seller...' : 'Runner: ${order.sellerName}', 
                    style: TextStyle(
                      color: isPending ? Colors.grey.shade500 : const Color(0xFF1A1A2E), 
                      fontSize: 13, 
                      fontWeight: FontWeight.w700
                    )
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)));
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('View Details', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderHistory order;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;

  const _OrderHistoryCard({required this.order, required this.formatDate, required this.formatTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor = order.status == 'Rejected' ? Colors.red : kPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: kBg),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                order.sellerPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.1), child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 28)),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.itemName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(order.sellerName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: kPrimary),
                      const SizedBox(width: 4),
                      Text(formatDate(order.dateTime), style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 11, color: kAccent),
                      const SizedBox(width: 4),
                      Text(formatTime(order.dateTime), style: const TextStyle(fontSize: 11, color: kAccent, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RM ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(order.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BBCB), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}