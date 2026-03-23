import 'package:flutter/material.dart';
import 'product_detail_page.dart'; // Make sure this matches your file name

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class StoreProfilePage extends StatelessWidget {
  const StoreProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Dummy Products for this specific store ---
    final List<Map<String, dynamic>> storeProducts = [
      {'name': 'Nasi Lemak Ayam Goreng', 'price': 8.50, 'rating': 4.8, 'image': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400'},
      {'name': 'Nasi Lemak Biasa', 'price': 4.00, 'rating': 4.7, 'image': 'https://images.unsplash.com/photo-1607631568010-a87245c0daf7?w=400'},
      {'name': 'Teh Tarik Ikat Tepi', 'price': 3.00, 'rating': 4.9, 'image': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400'},
      {'name': 'Karipap Pusing (3pcs)', 'price': 2.00, 'rating': 4.5, 'image': 'https://images.unsplash.com/photo-1626804475297-41609ea004eb?w=400'},
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // --- COLLAPSING BANNER (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: kPrimary,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(Icons.share_rounded, color: kWhite, size: 18),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Store Banner Image
                  Image.network(
                    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800', 
                    fit: BoxFit.cover,
                  ),
                  // Dark gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- STORE INFO SECTION ---
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -20.0, 0.0), // Pull it up over the banner
              decoration: const BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mak Cik Siti Nasi Lemak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E), height: 1.2)),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: kAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text('Kolej Dahlia 3, Bilik 204', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                          child: const Column(
                            children: [
                              Row(children: [Icon(Icons.star_rounded, color: Colors.orange, size: 16), SizedBox(width: 4), Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                              SizedBox(height: 2),
                              Text('120+ Ratings', style: TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Student-cooked hot nasi lemak prepared fresh every morning. Add-ons available!', style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 20),
                    const Text('All Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // --- PRODUCT GRID ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                mainAxisSpacing: 16, 
                crossAxisSpacing: 16, 
                childAspectRatio: 0.72, // Adjusts the height of the product cards
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = storeProducts[index];
                  return _buildProductCard(context, product);
                },
                childCount: storeProducts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELPER WIDGET: Product Card
  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        // Navigate to the existing Product Detail Page
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetailPage()));
      },
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
            // Product Image
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.network(product['image'], fit: BoxFit.cover),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('RM ${product['price'].toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                          const SizedBox(width: 2),
                          Text(product['rating'].toString(), style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
}