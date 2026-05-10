import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../utils/store_status.dart';
import 'add_product_page.dart';
import 'seller_orders_page.dart';
import 'seller_edit_shop_page.dart';
import 'view_product_page.dart';
import 'edit_product_page.dart';

String? _trimmedOrNull(dynamic v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s;
}

Widget _sellerDashboardStreamErrorNote(String message) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined, color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SellerDashboard extends StatelessWidget {
  final String storeName;
  final String storeLocation;

  const SellerDashboard({
    super.key, 
    required this.storeName, 
    required this.storeLocation,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))),
        body: const Center(child: Text('Please sign in to open Seller Dashboard.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('stores').doc(uid).snapshots(),
      builder: (context, storeSnap) {
        if (storeSnap.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Seller Dashboard'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Could not load shop profile.\n${storeSnap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final storeData = storeSnap.data?.data();
        if (storeData != null && !storeIsApproved(storeData)) {
          final pending = storeIsPending(storeData);
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Seller Dashboard'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  pending
                      ? 'Your store application is waiting for admin approval. You will receive a notification when it is reviewed.'
                      : 'Your seller application was not approved. Check Notifications in your profile for details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          );
        }

        final resolvedStore = _trimmedOrNull(storeData?['storeName']) ?? storeName;
        final resolvedLoc = _trimmedOrNull(storeData?['storeLocation']) ?? storeLocation;
        final storePhotoUrl = _trimmedOrNull(storeData?['storePhotoUrl']);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            if (userSnap.hasError) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.background,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text('Seller Dashboard'),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Could not load profile.\n${userSnap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final fullName = _trimmedOrNull(userSnap.data?.data()?['fullName']);
            final greetingName =
                fullName ?? (resolvedStore.isNotEmpty ? resolvedStore : 'Seller');

            return Scaffold(
              backgroundColor: AppColors.background,
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddProductPage(storeName: resolvedStore)),
                  );
                },
                backgroundColor: AppColors.accent,
                elevation: 4,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 24, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            DateFormat('EEE, d MMM', Localizations.localeOf(context).toString())
                                                .format(DateTime.now())
                                                .toUpperCase(),
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2)),
                                        const SizedBox(height: 2),
                                        Text('Hi, $greetingName',
                                            style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.ink)),
                                        if (resolvedLoc.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(Icons.place_outlined,
                                                    size: 13, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    resolvedLoc,
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey.shade600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (resolvedStore.isNotEmpty &&
                                            resolvedStore.toLowerCase() != greetingName.toLowerCase())
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(Icons.storefront_rounded,
                                                    size: 14, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    resolvedStore,
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey.shade600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
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
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.receipt_long_rounded, color: AppColors.ink),
                          tooltip: 'Orders',
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersPage())),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: AppColors.ink),
                          tooltip: 'Edit shop',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SellerEditShopPage()),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SellerEditShopPage()),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 2),
                              color: Colors.grey.shade100,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: storePhotoUrl != null
                                ? Image.network(
                                    storePhotoUrl,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                                  )
                                : Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // --- 2. ANALYTICS CARDS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Row(
                      children: [
                        Text('Monthly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').where('sellerId', isEqualTo: uid).snapshots(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.hasError) {
                    return _sellerDashboardStreamErrorNote(
                      'Unable to load order analytics. The rest of your dashboard is still available.',
                    );
                  }

                  double totalSales = 0.0;
                  double monthSales = 0.0;
                  double prevMonthSales = 0.0;
                  int activeOrders = 0;
                  int completedOrders = 0;

                  final now = DateTime.now();
                  final curMonthStart = DateTime(now.year, now.month, 1);
                  final nextMonthStart =
                      now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
                  final prevMonthStart =
                      now.month == 1 ? DateTime(now.year - 1, 12, 1) : DateTime(now.year, now.month - 1, 1);

                  bool inHalfOpen(DateTime t, DateTime start, DateTime end) =>
                      !t.isBefore(start) && t.isBefore(end);

                  if (orderSnapshot.hasData) {
                    for (var doc in orderSnapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      String status = data['status'] ?? 'Pending';

                      if (status == 'Pending' || status == 'Processing') {
                        activeOrders++;
                      } else if (status == 'Delivered' || status == 'Completed') {
                        completedOrders++;
                        double price = data['totalPrice'] is num
                            ? (data['totalPrice'] as num).toDouble()
                            : double.tryParse(data['totalPrice'].toString()) ?? 0.0;
                        totalSales += price;
                        final dynamic rawTs = data['createdAt'];
                        DateTime? created;
                        if (rawTs is Timestamp) created = rawTs.toDate();
                        if (created != null) {
                          if (inHalfOpen(created, curMonthStart, nextMonthStart)) monthSales += price;
                          if (inHalfOpen(created, prevMonthStart, curMonthStart)) prevMonthSales += price;
                        }
                      }
                    }
                  }

                  final localeTag = Localizations.localeOf(context).toString();
                  final monthPeriodLabel = DateFormat('MMMM yyyy', localeTag).format(now);

                  String trendText;
                  Color trendBg;
                  Color trendFg;
                  if (prevMonthSales <= 0) {
                    if (monthSales > 0) {
                      trendText = 'NEW';
                      trendBg = Colors.green.shade50;
                      trendFg = Colors.green.shade700;
                    } else {
                      trendText = '—';
                      trendBg = Colors.grey.shade100;
                      trendFg = Colors.grey.shade600;
                    }
                  } else {
                    final pct = (((monthSales - prevMonthSales) / prevMonthSales) * 100).round();
                    if (pct > 0) {
                      trendText = '+$pct%';
                      trendBg = Colors.green.shade50;
                      trendFg = Colors.green.shade700;
                    } else if (pct < 0) {
                      trendText = '$pct%';
                      trendBg = Colors.red.shade50;
                      trendFg = Colors.red.shade700;
                    } else {
                      trendText = '0%';
                      trendBg = Colors.grey.shade100;
                      trendFg = Colors.grey.shade600;
                    }
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildAnalyticCard(
                                title: 'Active Orders',
                                value: '$activeOrders',
                                subtitle: 'Pending action',
                                bgColor: AppColors.primaryDark,
                                iconData: Icons.pending_actions_rounded,
                                isUp: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAnalyticCard(
                                title: 'Completed',
                                value: '$completedOrders',
                                subtitle: 'Success rate',
                                bgColor: AppColors.primary,
                                iconData: Icons.check_circle_outline_rounded,
                                isUp: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // --- 3. EARNINGS & CHART SECTION ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total balance',
                                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(
                                            'Lifetime · delivered & completed',
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('RM ${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
                                  
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(color: Color(0xFFEEEEEE), height: 1),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'This month · ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              Text(
                                                monthPeriodLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary.withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'RM ${monthSales.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration:
                                                    BoxDecoration(color: trendBg, borderRadius: BorderRadius.circular(4)),
                                                child: Text(
                                                  trendText,
                                                  style: TextStyle(
                                                    color: trendFg,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Dummy Mini Chart
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _buildBar(30, AppColors.primary.withOpacity(0.3)),
                                          _buildBar(45, AppColors.primary.withOpacity(0.5)),
                                          _buildBar(25, AppColors.primary.withOpacity(0.3)),
                                          _buildBar(55, AppColors.primary), 
                                          _buildBar(40, AppColors.primary.withOpacity(0.5)),
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),

              const SizedBox(height: 32),

              // --- 4. MY PRODUCTS SECTION (GRID) ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: uid).snapshots(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.hasError) {
                    return _sellerDashboardStreamErrorNote(
                      'Unable to load your products list. Check your connection and try again.',
                    );
                  }

                  int totalProducts = productSnapshot.hasData ? productSnapshot.data!.docs.length : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                const SizedBox(height: 4),
                                Text('Overview for your $totalProducts products', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            Text('$totalProducts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        _buildProductContent(productSnapshot),
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
        ),
      ),
            );
          },
        );
      },
    );
  }

  // --- HELPER WIDGETS --------------------------------------------------------

  Widget _buildAnalyticCard({required String title, required String value, required String subtitle, required Color bgColor, required IconData iconData, required bool isUp}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(iconData, color: Colors.white.withOpacity(0.8), size: 20),
              Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isUp ? Colors.greenAccent : Colors.redAccent, size: 16),
            ],
          ),
          const SizedBox(height: 16), 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(height: 2, width: double.infinity, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 6,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildProductContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No products yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap the + button to add', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    var products = snapshot.data!.docs;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, 
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, products[index]);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, QueryDocumentSnapshot doc) {
    var item = doc.data() as Map<String, dynamic>;
    double price = item['price'] is num ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0.0;
    double rating = item['rating'] is num ? (item['rating'] as num).toDouble() : double.tryParse(item['rating'].toString()) ?? 0.0;
    
    return GestureDetector(
      onTap: () => _showProductOptions(context, doc, item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: (item['imageUrl'] == null || item['imageUrl'].toString().isEmpty)
                    ? Container(color: AppColors.primary.withOpacity(0.05), child: Icon(Icons.image_outlined, color: AppColors.primary.withOpacity(0.3), size: 40))
                    : Image.network(item['imageUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primary.withOpacity(0.05))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RM ${price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET MENU ---
  void _showProductOptions(BuildContext context, QueryDocumentSnapshot doc, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(item['name'] ?? 'Product Options', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 20),
              
              // --- VIEW PRODUCT ---
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.primary)),
                title: const Text('View Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Close bottom sheet
                  
                  // TODO: Uncomment and create this navigation when ViewProductPage is ready
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewProductPage(productId: doc.id, productData: item),
                    ),
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to View Product Page...')));
                },
              ),
              
              // --- EDIT PRODUCT ---
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, color: Colors.blue)),
                title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Close bottom sheet
                  
                  // TODO: Uncomment and create this navigation when EditProductPage is ready
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductPage(productId: doc.id, productData: item),
                    ),
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Edit Product Page...')));
                },
              ),
              
              // --- DELETE PRODUCT ---
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_rounded, color: Colors.red)),
                title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Close bottom sheet
                  
                  // PRO TIP: Call the reusable dialog function here instead of rewriting the logic!
                  String productName = item['name'] ?? 'This item';
                  _showDeleteConfirmation(context, doc.id, productName);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  // --- REUSABLE DELETE CONFIRMATION DIALOG ---
  void _showDeleteConfirmation(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Item?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: Text('Are you sure you want to delete "$productName"? This action cannot be undone.', style: const TextStyle(color: Colors.black87, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close the dialog first
                try {
                  // Execute the deletion using the passed productId
                  await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$productName" deleted successfully.'), backgroundColor: AppColors.primary));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Yes, Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }
}