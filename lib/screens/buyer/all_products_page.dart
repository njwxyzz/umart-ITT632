import 'package:flutter/material.dart'; 
import 'cart_page.dart'; 
import 'product_detail_page.dart'; // <--- JANGAN LUPA IMPORT NI!

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); // Olive Green
const kPrimaryLight = Color(0xFF799B61); // Lighter Olive
const kAccent       = Color(0xFFF27B35); // Oren
const kBg           = Color(0xFFF5F7F2); // Off-white hijau
const kWhite        = Colors.white;

class AllProductPage extends StatelessWidget {
  final String title; 
  final List items;  

  const AllProductPage({super.key, required this.title, required this.items}); 

  @override
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: kBg, 
      appBar: AppBar( 
        backgroundColor: kBg,
        elevation: 0, 
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)), // Warna butang back
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 24),
            color: const Color(0xFF1A1A2E),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),
      // MAGIK BACKGROUND PATTERN .JPG KAT SINI!
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'), // Pastikan guna .jpg macam fail kau
            repeat: ImageRepeat.repeat,
            opacity: 0.05, // Pudar 5%
          ),
        ),
        // ---- IF LIST EMPTY SHOW THIS -----
        child: items.isEmpty 
            ? Center( 
                child: Column( 
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [ 
                    Icon(Icons.inventory_2_outlined, size: 60, color: kPrimary.withOpacity(0.3)), 
                    const SizedBox(height: 16), 
                    Text('No products available for $title', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)), 
                  ],
                ),
              )
            // ---- IF LIST HAS ITEMS SHOW GRID -----
            : Padding( 
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), 
                child: GridView.builder (
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( 
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,  
                    crossAxisSpacing: 12,   
                    childAspectRatio: 0.76, // Adjust sikit supaya tak terpotong bawah   
                  ),
                  itemCount: items.length,    
                  itemBuilder: (context, index) {   
                    final item = items[index];  
                    return _ProductCard(   
                      title: item.label,  
                      price: item.price,
                      rating: item.rating,
                      sellerName: item.sellerName,
                      badge: item.badge,
                      badgeColor: item.badgeColor,
                      imageUrl: item.imageUrl,
                    );
                  },
                )
              ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget { 
  final String title; 
  final double price; 
  final double rating; 
  final String sellerName; 
  final String? badge; 
  final Color? badgeColor; 
  final String imageUrl; 

  const _ProductCard({
    required this.title, 
    required this.price, 
    required this.rating, 
    required this.sellerName, 
    this.badge, 
    this.badgeColor, 
    required this.imageUrl
  }); 

  @override
  Widget build(BuildContext context) { 
    return GestureDetector( // <--- GESTURE DETECTOR DITAMBAH DI SINI
      onTap: () {
        // PERGI KE PRODUCT DETAIL BILA KLIK!
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetailPage()));
      },
      child: Container( 
        decoration: BoxDecoration( 
          color: kWhite,
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [ 
            BoxShadow(
              color: Colors.black.withOpacity(0.06), 
              blurRadius: 10, 
              offset: const Offset(0, 3), 
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge, 
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 120,
                      width: double.infinity, 
                      child: Image.network( 
                        imageUrl, 
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container( 
                          color: kPrimary.withOpacity(0.1), // Guna hijau lembut kalau gambar error
                          child: const Icon(Icons.shopping_bag_outlined, size: 40, color: kPrimary),
                        ),
                      ),
                    ),
                    if (badge != null) 
                      Positioned( 
                        top: 8,
                        left: 8,
                        child: Container( 
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                          decoration: BoxDecoration(
                            color: badgeColor ?? kAccent, // Fallback ke warna Oren kalau takde warna spesifik
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('RM${price.toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w800, fontSize: 13)), // Tukar ke Oren
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: kAccent, size: 14), // Bintang Oren
                              const SizedBox(width: 3),
                              Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.storefront_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(sellerName, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Butang Add (+)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(
                  color: kPrimary, // Tukar dari Biru ke Hijau
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ]
                ),
                child: const Icon(Icons.add, color: kWhite, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}