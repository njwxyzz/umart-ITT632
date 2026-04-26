import 'package:flutter/material.dart';

// --- Color Constants (UMART THEME) ---
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class ViewProductPage extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ViewProductPage({
    super.key, 
    required this.productId, 
    required this.productData,
  });

  @override
  Widget build(BuildContext context) {
    // Safely parse data with fallbacks to prevent null errors
    final String name = productData['name'] ?? productData['productName'] ?? 'Unknown Product';
    final String description = productData['description'] ?? 'No description provided for this product.';
    final String category = productData['category'] ?? 'Uncategorized';
    final String imageUrl = productData['imageUrl'] ?? '';
    
    // Safely parse numbers
    final double price = productData['price'] is num 
        ? (productData['price'] as num).toDouble() 
        : double.tryParse(productData['price'].toString()) ?? 0.0;
        
    final double rating = productData['rating'] is num 
        ? (productData['rating'] as num).toDouble() 
        : double.tryParse(productData['rating'].toString()) ?? 0.0;

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // --- 1. COLLAPSING IMAGE HEADER (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: kPrimary,
            iconTheme: const IconThemeData(color: kWhite),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_image_$productId', // Good practice for future animations
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
          ),

          // --- 2. PRODUCT DETAILS SECTION ---
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              // We use a negative transform to make the white container overlap the image slightly
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Category Tag & Rating ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : 'New',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- Product Name ---
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // --- Price ---
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kAccent,
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Divider(color: Color(0xFFEEEEEE), height: 1),
                    ),

                    // --- Description ---
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Note for Seller
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is how buyers will see your product.',
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for missing images
  Widget _buildImagePlaceholder() {
    return Container(
      color: kPrimary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 60, color: kPrimary.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text('No Image', style: TextStyle(color: kPrimary.withOpacity(0.5), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}