import 'dart:ui';
import 'package:flutter/material.dart';
import 'activity_page.dart';
import 'profile_page.dart';
import 'all_products_page.dart';
import 'cart_page.dart';

void main() {
  runApp(const UMartApp());
}

class UMartApp extends StatelessWidget {
  const UMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMART',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFFF2F3F5),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Color Constants ──────────────────────────────────────────────────────────

const kBlue   = Color(0xFF0052FF);
const kOrange = Color(0xFFFF6B00);
const kBg     = Color(0xFFF2F3F5);
const kWhite  = Colors.white;

// ─── Icon Asset Helper ────────────────────────────────────────────────────────
// Uses ClipRRect + BoxFit.cover so the image always fills the container fully,
// even if the PNG still has slight transparent borders after cropping.

Widget _iconAsset(String path, {double radius = 12}) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  bool hasActiveOrder = true;

  final List<_FoodItem> _foodItems = const [
    _FoodItem(
      label: 'Mak Cik Nasi Lemak',
      badge: '20% OFF',
      badgeColor: kOrange,
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
      price: 8.50,
      rating: 4.8,
      sellerName: 'Mak Cik Nasi Lemak',
    ),
    _FoodItem(
      label: 'Ramen House',
      badge: null,
      badgeColor: null,
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
      price: 15.90,
      rating: 4.7,
      sellerName: 'Ramen House',
    ),
    _FoodItem(
      label: 'Bake P...',
      badge: 'Free deli',
      badgeColor: kBlue,
      imageUrl:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
      price: 6.20,
      rating: 4.6,
      sellerName: 'Bake P Bakery',
    ),
    _FoodItem(
      label: 'Burger Lab',
      badge: '10% OFF',
      badgeColor: kOrange,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
      price: 10.50,
      rating: 4.9,
      sellerName: 'Burger Lab',
    ),
  ];

  /// Navigation: 0 Home, 1 Orders, 2 Activity, 3 Profile. Only the active tab is built.
  Widget _buildBody() {
    switch (currentIndex) {
      case 1:
        return const _PlaceholderScreen(title: 'Orders Page');
      case 2:
        return const ActivityPage();
      case 3:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  void _openAllProductsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllProductsPage(items: _foodItems),
      ),
    );
  }

  Widget _buildHomeContent() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 160 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TopBar(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BentoGrid(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PromoBanner(),
          ),
          const SizedBox(height: 20),
          _FoodCarousel(
            items: _foodItems,
            onSeeAll: _openAllProductsPage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Current tab content ───────────────────────────────────────
          _buildBody(),

          // ── Floating bottom layer: glassmorphism banner (Home only) + pill nav ─
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentIndex == 0 && hasActiveOrder) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _TrackingBanner(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        24, 0, 24, bottomPad > 0 ? bottomPad : 16),
                    child: _BottomNav(
                      selectedIndex: currentIndex,
                      onTap: (i) => setState(() => currentIndex = i),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder screens for Orders, Activity, Profile ────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search UMART...',
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 22, color: Colors.black87),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                    color: kOrange, shape: BoxShape.circle),
                child: const Center(
                  child: Text('3',
                      style: TextStyle(
                          color: kWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CartPage(),
              ),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 22, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFD0D8FF),
          child: const Text('U',
              style: TextStyle(
                  color: kBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ),
      ],
    );
  }
}

// ─── Bento Grid ───────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top row: Food (large) + Parcel/Printing (stacked) ────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Food – large square card
              Expanded(
                child: _BentoCard(
                  minHeight: 170,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        // No padding — ClipRRect inside _iconAsset handles edges
                        child: _iconAsset(
                          'assets/icons/food_icons.png',
                          radius: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Food',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Order meals nearby',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Parcel + Printing stacked
              Expanded(
                child: Column(
                  children: [
                    _BentoCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _iconAsset(
                              'assets/icons/parcel_icons.png',
                              radius: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Parcel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text('Send & receive',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BentoCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _iconAsset(
                              'assets/icons/printing_icons.png',
                              radius: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Printing',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Text('Print & copy',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11)),
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
        ),

        const SizedBox(height: 10),

        // ── Bottom row: Preloved (wide) + More (small) ───────────────────
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _BentoCard(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _iconAsset(
                        'assets/icons/preloved_icons.png',
                        radius: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preloved',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text('Buy & sell items',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BentoCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.more_horiz_rounded,
                        color: Colors.grey[600], size: 28),
                    const SizedBox(height: 4),
                    Text('More',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Bento Card ──────────────────────────────────────────────────────────────

class _BentoCard extends StatelessWidget {
  final Widget child;
  final double minHeight;

  const _BentoCard({required this.child, this.minHeight = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.all(16), // ← FIXED: was missing padding
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
      child: child,
    );
  }
}

// ─── Promo Banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), // ← FIXED: was missing padding
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: kOrange, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'LIMITED TIME',
                      style: TextStyle(
                        color: kOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Free Delivery Week',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoy free delivery on all food orders this week!',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Order Now',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
          // Decorative icon cluster
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E0FF).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Positioned(
                top: 8,
                right: 4,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8C6FF).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Image.asset(
                'assets/icons/promo_icon.png',
                width: 60,
                height: 60,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.restaurant_rounded,
                  color: Color(0xFF8099FF),
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Food Carousel ────────────────────────────────────────────────────────────

class _FoodItem {
  final String label;
  final String? badge;
  final Color? badgeColor;
  final String imageUrl;
  final double price;
  final double rating;
  final String sellerName;

  const _FoodItem({
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.sellerName,
  });
}

class _FoodCarousel extends StatelessWidget {
  final List<_FoodItem> items;
  final VoidCallback onSeeAll;

  const _FoodCarousel({
    required this.items,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order dinner from',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See all',
                    style: TextStyle(color: kBlue, fontSize: 14)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 235,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _FoodCard(item: items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodCard extends StatelessWidget {
  final _FoodItem item;

  const _FoodCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
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
              // Top image section
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      item.imageUrl,
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
                  if (item.badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badge!,
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
              // Bottom details section
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price + Rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: kOrange,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Seller row
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.sellerName,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Quick add button
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


// ─── Tracking Banner (Glassmorphism) ─────────────────────────────────────────

class _TrackingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kWhite.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: kWhite.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pedal_bike_rounded,
                    color: kBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arriving in 5 mins',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('To Dahlia 3',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: kWhite,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text('Track',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Bottom Nav ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _icons = [
    Icons.home_rounded,
    Icons.list_alt_rounded,
    Icons.show_chart_rounded,
    Icons.person_outline_rounded,
  ];

  static const _labels = ['Home', 'Orders', 'Activity', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_icons.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    _icons[i],
                    color: selected ? kWhite : Colors.grey[700],
                    size: 22,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 6),
                    Text(
                      _labels[i],
                      style: const TextStyle(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}