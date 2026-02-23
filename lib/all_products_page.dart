import 'package:flutter/material.dart';
import 'cart_page.dart';

// Local copies of core colors so we don't create circular imports.
const kBlue = Color(0xFF0052FF);
const kOrange = Color(0xFFFF6B00);
const kBg = Color(0xFFF2F3F5);
const kWhite = Colors.white;

class AllProductsPage extends StatelessWidget {
  final List items; // Expecting list of _FoodItem from main.dart

  const AllProductsPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'All products',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 24),
            color: const Color(0xFF1A1A2E),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CartPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
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
    required this.badge,
    required this.badgeColor,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Image with promo badge
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? kOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: kWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Price + Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: kOrange,
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Seller name
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sellerName,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: kBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: kWhite,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

