import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- PENTING: Wajib import untuk CCTV Firebase
import 'add_product_page.dart';
import 'seller_orders_page.dart';

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
            icon: const Icon(Icons.settings_outlined, color: kWhite),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersPage()));
            },
          )
        ],
      ),
      // --- BUTANG TAMBAH BARANG (FLOATING) ---
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
      body: Container(
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
                  
                  // Kotak Statistik (Akan datang kita kasi hidup)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Sales', 'RM 0.00', Icons.account_balance_wallet_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Active Orders', '0', Icons.receipt_long_rounded)),
                    ],
                  ),
                ],
              ),
            ),

            // ─── CCTV FIREBASE (STREAMBUILDER) ───
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Dia cari barang yang 'sellerName' dia sama dengan nama kedai kau!
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('sellerName', isEqualTo: storeName)
                    .snapshots(),
                builder: (context, snapshot) {
                  // 1. Kalau tengah loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimary));
                  }

                  // 2. Kalau database tak jumpa apa-apa (Kosong)
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // 3. Kalau ada barang! Kita tayang guna GridView
                  var products = snapshot.data!.docs;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75, // Adjust tinggi kotak
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var item = products[index].data() as Map<String, dynamic>;
                      return _buildProductCard(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN: KOTAK KOSONG (Patung yang lama tu)
  Widget _buildEmptyState(BuildContext context) {
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
          Text(
            'Click the Add Product button below to list your first item.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  // WIDGET BANTUAN: KOTAK BARANG
  Widget _buildProductCard(Map<String, dynamic> item) {
    double price = item['price'] is num ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0.0;
    
    return Container(
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
              child: Image.network(
                item['imageUrl'] ?? 'https://via.placeholder.com/150', 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
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
}