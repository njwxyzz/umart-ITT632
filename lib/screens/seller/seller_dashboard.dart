import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'add_product_page.dart';
import 'seller_orders_page.dart';
// PASTIKAN IMPORT NI BETUL IKUT FOLDER KAU UNTUK VIEW PRODUCT
// import '../buyer/product_detail_page.dart'; 

// ─── Color Constants ─────────────────────────────────────────────────────────
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

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
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: kWhite, size: 24),
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text('My Store', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: kWhite),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersPage()));
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProductPage(storeName: storeName)),
          );
        },
        backgroundColor: kAccent,
        icon: const Icon(Icons.add, color: kWhite),
        label: const Text('Add Product', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerName', isEqualTo: storeName)
            .snapshots(),
        builder: (context, productSnapshot) {
          
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_pattern.jpg'),
                repeat: ImageRepeat.repeat,
                opacity: 0.05, 
              ),
            ),
            child: Column(
              children: [
                // ─── HEADER (Store Info & Stats) ───
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(storeName, style: const TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('📍 $storeLocation', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            .where('sellerId', isEqualTo: currentUserId) 
                            .snapshots(),
                        builder: (context, orderSnapshot) {
                          
                          double totalSales = 0.0;
                          int activeOrders = 0;

                          if (orderSnapshot.hasData) {
                            for (var doc in orderSnapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              String status = data['status'] ?? 'Pending';
                              
                              if (status == 'Pending' || status == 'Processing') {
                                activeOrders++;
                              }
                              
                              if (status == 'Delivered' || status == 'Completed') {
                                double price = data['totalPrice'] is num ? (data['totalPrice'] as num).toDouble() : double.tryParse(data['totalPrice'].toString()) ?? 0.0;
                                totalSales += price;
                              }
                            }
                          }

                          return Row(
                            children: [
                              Expanded(child: _buildStatCard('Total Sales', 'RM ${totalSales.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Active Orders', '$activeOrders', Icons.receipt_long_rounded)),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),

                // ─── SENARAI BARANG / EMPTY STATE ───
                Expanded(
                  child: _buildProductContent(productSnapshot),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return _buildEmptyState();
    }

    var products = snapshot.data!.docs;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, 
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        // 🚨 KITA HANTAR DOCUMENT PENUH KE DALAM KAD SUPAYA KITA TAHU ID DIA 🚨
        return _buildProductCard(context, products[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 80, color: kPrimary.withOpacity(0.3)),
          ),
          const SizedBox(height: 24),
          const Text('Your store is empty!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          const Text(
            'Click the Add Product button below to list your first item.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  // 🚨 KAD PRODUK SEKARANG TERIMA 'context' DAN 'DocumentSnapshot' 🚨
  Widget _buildProductCard(BuildContext context, QueryDocumentSnapshot doc) {
    var item = doc.data() as Map<String, dynamic>;
    double price = item['price'] is num ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0.0;
    
    return GestureDetector(
      onTap: () => _showProductOptions(context, doc, item), // Buka menu bila klik
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: (item['imageUrl'] == null || item['imageUrl'].toString().isEmpty)
                    ? Container(
                        color: kPrimary.withOpacity(0.05),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined, color: kPrimary.withOpacity(0.4), size: 40),
                            const SizedBox(height: 8),
                            Text('No Image', style: TextStyle(color: kPrimary.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : Image.network(
                        item['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: kPrimary.withOpacity(0.05),
                          child: Icon(Icons.broken_image, color: kPrimary.withOpacity(0.4), size: 40),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('RM ${price.toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimary, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ─── MAGIK BOTTOM SHEET TIGA MENU ──────────────────────────────────────────
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
              
              // 1. VIEW PRODUCT
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove_red_eye_rounded, color: kPrimary)),
                title: const Text('View Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Tutup menu
                  // TODO: Buka ProductDetailPage
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Function view coming soon!')));
                },
              ),
              
              // 2. EDIT PRODUCT
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, color: Colors.blue)),
                title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Tutup menu
                  // TODO: Buat EditProductPage lepas ni
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Function edit coming soon!')));
                },
              ),

              // 3. DELETE PRODUCT
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_rounded, color: Colors.red)),
                title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // Tutup menu bawah
                  _showDeleteConfirmation(context, doc.id, item['name'] ?? 'this item'); // Panggil Dialog Warning
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  // ─── AMARAN SEBELUM PADAM (DOUBLE CONFIRMATION) ────────────────────────────
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
          content: Text(
            'Are you sure you want to delete "$productName"? This action cannot be undone.',
            style: const TextStyle(color: Colors.black87, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Tutup popup amaran
                
                // Tembak kod delete ke Firebase!
                try {
                  await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$productName" deleted successfully.'), backgroundColor: kPrimary),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting product: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Yes, Delete', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }
}