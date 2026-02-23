import 'package:flutter/material.dart';

// ─── Color Constants (same as main.dart) ─────────────────────────────────────
const kBlue   = Color(0xFF0052FF);
const kOrange = Color(0xFFFF6B00);
const kBg     = Color(0xFFF2F3F5);
const kWhite  = Colors.white;
const kGreen  = Color(0xFF00C48C);

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
  const OrderLineItem(
      {required this.name, required this.qty, required this.price});
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

final List<OrderHistory> _sampleOrders = [
  OrderHistory(
    orderId: 'UM-20241201-0042',
    itemName: 'Nasi Lemak Special + Teh Tarik',
    sellerName: 'Mak Cik Siti',
    sellerPhoto:
        'https://images.unsplash.com/photo-1607631568010-a87245c0daf7?w=200',
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
    sellerPhoto:
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200',
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
    sellerPhoto:
        'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=200',
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
  OrderHistory(
    orderId: 'UM-20241120-0009',
    itemName: 'Burger Double Patty',
    sellerName: 'Burger Lab',
    sellerPhoto:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
    sellerAddress: 'Kolej Meranti, UiTM Shah Alam',
    sellerRating: 4.5,
    sellerReviews: 98,
    sellerLocation: 'Kolej Meranti',
    buyerLocation: 'Kolej Dahlia 3',
    dateTime: DateTime(2024, 11, 20, 13, 45),
    subtotal: 11.00,
    deliveryFee: 2.00,
    status: 'Delivered',
    items: [
      OrderLineItem(name: 'Double Patty Burger', qty: 1, price: 9.00),
      OrderLineItem(name: 'Fries (M)', qty: 1, price: 2.00),
    ],
  ),
];

// ─── Activity Page (Order History List) ──────────────────────────────────────

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Activity',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_sampleOrders.length} orders',
                        style: const TextStyle(
                          color: kBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your complete order history',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Order List ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _sampleOrders.length,
              itemBuilder: (context, index) {
                final order = _sampleOrders[index];
                return _OrderHistoryCard(
                  order: order,
                  formatDate: _formatDate,
                  formatTime: _formatTime,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(order: order),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order History Card ───────────────────────────────────────────────────────

class _OrderHistoryCard extends StatelessWidget {
  final OrderHistory order;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;

  const _OrderHistoryCard({
    required this.order,
    required this.formatDate,
    required this.formatTime,
    required this.onTap,
  });

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Seller photo ────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: kBg,
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                order.sellerPhoto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE8EEFF),
                  child: const Icon(Icons.storefront_rounded,
                      color: kBlue, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Order info ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Text(
                    order.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Seller name
                  Text(
                    order.sellerName,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Date + time row
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: kBlue),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(order.dateTime),
                        style: const TextStyle(
                            fontSize: 11, color: kBlue,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: kOrange),
                      const SizedBox(width: 4),
                      Text(
                        formatTime(order.dateTime),
                        style: const TextStyle(
                            fontSize: 11, color: kOrange,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Price + chevron ────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Delivered',
                    style: TextStyle(
                      color: kGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFB0BBCB), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Order Detail Page ────────────────────────────────────────────────────────

class OrderDetailPage extends StatelessWidget {
  final OrderHistory order;

  const OrderDetailPage({super.key, required this.order});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100 + bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero header with back button ────────────────────
                _buildHeroHeader(context, topPad),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Order meta (date / time / ID) ───────────
                      _buildOrderMeta(),

                      const SizedBox(height: 14),

                      // ── Seller card ─────────────────────────────
                      _buildSellerCard(),

                      const SizedBox(height: 14),

                      // ── Route card ──────────────────────────────
                      _buildRouteCard(),

                      const SizedBox(height: 14),

                      // ── Order summary ───────────────────────────
                      _buildOrderSummary(),

                      const SizedBox(height: 14),

                      // ── Price breakdown ─────────────────────────
                      _buildPriceBreakdown(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Floating Contact Button ─────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad > 0 ? bottomPad : 16,
            child: _buildContactButton(context),
          ),
        ],
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, double topPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Color(0xFF1A1A2E)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Order Detail',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        color: kGreen, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Delivered',
                      style: TextStyle(
                        color: kGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Order name + seller
          Text(
            order.itemName,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'from ${order.sellerName}',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Order Meta ─────────────────────────────────────────────────────────────
  Widget _buildOrderMeta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _MetaChip(
            icon: Icons.tag_rounded,
            label: 'Order ID',
            value: order.orderId,
            color: kBlue,
          ),
          const SizedBox(width: 10),
          _MetaChip(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(order.dateTime),
            color: kOrange,
          ),
          const SizedBox(width: 10),
          _MetaChip(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _formatTime(order.dateTime),
            color: kGreen,
          ),
        ],
      ),
    );
  }

  // ── Seller Card ────────────────────────────────────────────────────────────
  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const _SectionTitle(title: 'Seller Info', icon: Icons.storefront_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              // Seller photo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: kBg,
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  order.sellerPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE8EEFF),
                    child: const Icon(Icons.person_rounded,
                        color: kBlue, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.sellerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: kOrange),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            order.sellerAddress,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: kOrange, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                order.sellerRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: kOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${order.sellerReviews} reviews)',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Route Card ─────────────────────────────────────────────────────────────
  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              title: 'Delivery Route',
              icon: Icons.route_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              // Timeline dots
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: kBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kBlue, kOrange],
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: kOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 14, color: kBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('From',
                                    style: TextStyle(
                                        color: kBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  order.sellerLocation,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // To
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_rounded,
                              size: 14, color: kOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('To',
                                    style: TextStyle(
                                        color: kOrange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  order.buyerLocation,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A2E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Order Summary ──────────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              title: 'Order Summary',
              icon: Icons.receipt_long_rounded),
          const SizedBox(height: 14),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Qty badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '×${item.qty}',
                          style: const TextStyle(
                            color: kBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'RM ${(item.price * item.qty).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Price Breakdown ────────────────────────────────────────────────────────
  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SectionTitle(
              title: 'Payment Summary',
              icon: Icons.payments_rounded),
          const SizedBox(height: 14),
          _PriceRow(label: 'Subtotal', value: order.subtotal),
          const SizedBox(height: 8),
          _PriceRow(
              label: 'Delivery Fee', value: order.deliveryFee,
              valueColor: kOrange),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.withOpacity(0.2),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'RM ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contact Button ─────────────────────────────────────────────────────────
  Widget _buildContactButton(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kBlue, Color(0xFF003FCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.chat_bubble_rounded,
                  color: kWhite, size: 18),
              SizedBox(width: 10),
              Text(
                'Contact Seller',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small Reusable Widgets ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: kBlue),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(
          'RM ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: valueColor ?? const Color(0xFF1A1A2E),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}