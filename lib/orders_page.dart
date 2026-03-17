import 'package:flutter/material.dart';
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

// ─── Sample Data ──────────────────────────────────────────────────────────────
final List<OrderHistory> _sampleOrders = [
  OrderHistory(
    orderId: 'UM-20241201-0042',
    itemName: 'Nasi Lemak Special + Teh Tarik',
    sellerName: 'Mak Cik Siti',
    sellerPhoto: 'https://images.unsplash.com/photo-1607631568010-a87245c0daf7?w=200',
    sellerAddress: 'Kolej Delima, UiTM Shah Alam',
    sellerRating: 4.8,
    sellerReviews: 234,
    sellerLocation: 'Kolej Delima',
    buyerLocation: 'Kolej Dahlia 3',
    dateTime: DateTime(2024, 12, 1, 12, 35),
    subtotal: 8.50,
    deliveryFee: 1.50,
    status: 'Delivered',
    items: [
      OrderLineItem(name: 'Nasi Lemak Special', qty: 1, price: 6.50),
      OrderLineItem(name: 'Teh Tarik', qty: 1, price: 2.00),
    ],
  ),
  OrderHistory(
    orderId: 'UM-20241128-0031',
    itemName: 'Ramen Tonkotsu',
    sellerName: 'Ramen House',
    sellerPhoto: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200',
    sellerAddress: 'Dataran Cendekia, UiTM Shah Alam',
    sellerRating: 4.6,
    sellerReviews: 187,
    sellerLocation: 'Dataran Cendekia',
    buyerLocation: 'Kolej Dahlia 3',
    dateTime: DateTime(2024, 11, 28, 19, 10),
    subtotal: 12.00,
    deliveryFee: 2.00,
    status: 'Delivered',
    items: [
      OrderLineItem(name: 'Ramen Tonkotsu', qty: 1, price: 12.00),
    ],
  ),
  OrderHistory(
    orderId: 'UM-20241125-0018',
    itemName: 'Croissant × 2 + Americano',
    sellerName: 'Bake & Brew',
    sellerPhoto: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=200',
    sellerAddress: 'Pusat Perdagangan, UiTM Shah Alam',
    sellerRating: 4.9,
    sellerReviews: 312,
    sellerLocation: 'Pusat Perdagangan',
    buyerLocation: 'Kolej Dahlia 3',
    dateTime: DateTime(2024, 11, 25, 9, 5),
    subtotal: 14.00,
    deliveryFee: 1.50,
    status: 'Delivered',
    items: [
      OrderLineItem(name: 'Butter Croissant', qty: 2, price: 5.00),
      OrderLineItem(name: 'Americano', qty: 1, price: 4.00),
    ],
  ),
];

// ─── Orders Page ─────────────────────────────────────────────────────────────
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
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
        body: TabBarView(
          children: [
            // ─── TAB 1: ACTIVE ORDERS ───
            _buildActiveTab(),

            // ─── TAB 2: COMPLETED ORDERS (Guna Data Asal Kau!) ───
            _buildCompletedTab(context),
          ],
        ),
      ),
    );
  }

  // WIDGET: Tab Active (Order tengah jalan)
  Widget _buildActiveTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
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
                        const Text('Burgers & Wings Co.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Crispy Chicken Burger...', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('● Preparing your food...', style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text('#UM-8291', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 14, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 16, color: kWhite)),
                      const SizedBox(width: 8),
                      Text('Ahmad', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: kPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('Track Order', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET: Tab Completed (Order History List Asal Kau)
  Widget _buildCompletedTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _sampleOrders.length,
      itemBuilder: (context, index) {
        final order = _sampleOrders[index];
        return _OrderHistoryCard(
          order: order,
          formatDate: _formatDate,
          formatTime: _formatTime,
          // BILA TEKAN, LOMPAT KE ORDER DETAIL DENGAN DATA!
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order))),
        );
      },
    );
  }
}

// ─── Order History Card (Guna design asal kau) ───────────────────────────────
class _OrderHistoryCard extends StatelessWidget {
  final OrderHistory order;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;

  const _OrderHistoryCard({required this.order, required this.formatDate, required this.formatTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            // ── Seller photo ────────────────────────────────────────
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

            // ── Order info ──────────────────────────────────────────
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

            // ── Price + chevron ────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RM ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Delivered', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700)),
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