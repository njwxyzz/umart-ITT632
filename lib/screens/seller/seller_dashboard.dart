import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'add_product_page.dart';
import 'seller_orders_page.dart';

// ─── Color Constants (TEMA UMART) ──────────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryDark  = Color(0xFF2C3E24); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

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
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: kBg,
      // ─── FLOATING ACTION BUTTON ───
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductPage(storeName: storeName)),
          );
        },
        backgroundColor: kAccent,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: kWhite, size: 28),
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. HEADER SELLER DENGAN BACK BUTTON ───
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Butang Back
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WED, 15 APRIL', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 2),
                            Text('Hi, $storeName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1A1A2E)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersPage())),
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kPrimary.withOpacity(0.3), width: 2),
                            image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200'), fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // ─── 2. KOTAK ANALYTICS (2 KOTAK SEIMBANG) ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
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
                stream: FirebaseFirestore.instance.collection('orders').where('sellerId', isEqualTo: currentUserId).snapshots(),
                builder: (context, orderSnapshot) {
                  double totalSales = 0.0;
                  int activeOrders = 0;
                  int completedOrders = 0;

                  if (orderSnapshot.hasData) {
                    for (var doc in orderSnapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      String status = data['status'] ?? 'Pending';
                      
                      if (status == 'Pending' || status == 'Processing') {
                        activeOrders++;
                      } else if (status == 'Delivered' || status == 'Completed') {
                        completedOrders++;
                        double price = data['totalPrice'] is num ? (data['totalPrice'] as num).toDouble() : double.tryParse(data['totalPrice'].toString()) ?? 0.0;
                        totalSales += price;
                      }
                    }
                  }

                  return Column(
                    children: [
                      // 2 Kotak Balance Kiri Kanan
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildAnalyticCard(
                                title: 'Active Orders',
                                value: '$activeOrders',
                                subtitle: 'Pending action',
                                bgColor: kPrimaryDark,
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
                                bgColor: kPrimary,
                                iconData: Icons.check_circle_outline_rounded,
                                isUp: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // ─── 3. EARNINGS & CHART SECTION ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total balance', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13)),
                                      const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('RM ${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                                  
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
                                              const Text('Earning in ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                                              Text('April', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary.withOpacity(0.8))),
                                              const Icon(Icons.arrow_drop_down, size: 16, color: kPrimary),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('RM ${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('+ 12%', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                      // Dummy Mini Chart
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _buildBar(30, kPrimary.withOpacity(0.3)),
                                          _buildBar(45, kPrimary.withOpacity(0.5)),
                                          _buildBar(25, kPrimary.withOpacity(0.3)),
                                          _buildBar(55, kPrimary), // Highest
                                          _buildBar(40, kPrimary.withOpacity(0.5)),
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

              // ─── 4. MY PRODUCTS SECTION (GRID) ───
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').where('sellerName', isEqualTo: storeName).snapshots(),
                builder: (context, productSnapshot) {
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
                                const Text('My Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                Text('Overview for your $totalProducts products', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            Text('$totalProducts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
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
  }

  // ─── WIDGET BANTUAN ────────────────────────────────────────────────────────

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
              Icon(iconData, color: kWhite.withOpacity(0.8), size: 20),
              Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: isUp ? Colors.greenAccent : Colors.redAccent, size: 16),
            ],
          ),
          const SizedBox(height: 16), // Tambah sikit gap
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(color: kWhite.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(height: 2, width: double.infinity, color: kWhite.withOpacity(0.2)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: kWhite.withOpacity(0.6), fontSize: 10)),
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
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: kPrimary)));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20)),
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
          color: kWhite,
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
                    ? Container(color: kPrimary.withOpacity(0.05), child: Icon(Icons.image_outlined, color: kPrimary.withOpacity(0.3), size: 40))
                    : Image.network(item['imageUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.05))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RM ${price.toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 14)),
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

  void _showProductOptions(BuildContext context, QueryDocumentSnapshot doc, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(item['name'] ?? 'Product Options', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove_red_eye_rounded, color: kPrimary)),
                title: const Text('View Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Function view coming soon!')));
                },
              ),
              
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, color: Colors.blue)),
                title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Function edit coming soon!')));
                },
              ),

              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_rounded, color: Colors.red)),
                title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); 
                  _showDeleteConfirmation(context, doc.id, item['name'] ?? 'this item'); 
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  void _showDeleteConfirmation(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kWhite,
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
                Navigator.pop(dialogContext); 
                try {
                  await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$productName" deleted successfully.'), backgroundColor: kPrimary));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting product: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Yes, Delete', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }
}