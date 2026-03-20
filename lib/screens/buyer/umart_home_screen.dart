import 'dart:ui';
import 'package:flutter/material.dart';

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

const kBlue = Color(0xFF0052FF);
const kOrange = Color(0xFFFF6B00);
const kBg = Color(0xFFF2F3F5);
const kWhite = Colors.white;

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_FoodItem> _foodItems = const [
    _FoodItem(
      label: 'Mak Cik Nasi Lemak',
      badge: '20% OFF',
      badgeColor: kOrange,
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
    ),
    _FoodItem(
      label: 'Ramen House',
      badge: null,
      badgeColor: null,
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
    ),
    _FoodItem(
      label: 'Bake P...',
      badge: 'Free deli',
      badgeColor: kBlue,
      imageUrl:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
    ),
    _FoodItem(
      label: 'Burger Lab',
      badge: '10% OFF',
      badgeColor: kOrange,
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Scrollable Content ──────────────────────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 160 + bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 12),
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TopBar(),
                ),
                const SizedBox(height: 20),
                // Bento Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BentoGrid(),
                ),
                const SizedBox(height: 20),
                // Promo Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PromoBanner(),
                ),
                const SizedBox(height: 20),
                // Food Carousel
                _FoodCarousel(items: _foodItems),
              ],
            ),
          ),

          // ── Floating Bottom Layer ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active Order Tracking Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TrackingBanner(),
                ),
                const SizedBox(height: 10),
                // Floating Bottom Nav
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      24, 0, 24, bottomPad > 0 ? bottomPad : 16),
                  child: _BottomNav(
                    selectedIndex: _selectedIndex,
                    onTap: (i) => setState(() => _selectedIndex = i),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        // Search Field
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
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
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
        // Message Icon with Badge
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
                  color: kOrange,
                  shape: BoxShape.circle,
                ),
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
        // Avatar
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
        // Top row: Food + (Parcel / Printing)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Food – large square
              Expanded(
                child: _BentoCard(
                  minHeight: 160,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.restaurant_rounded,
                            color: kOrange, size: 32),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: kBlue, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BentoCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.print_outlined,
                                color: kBlue, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
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
        // Bottom row: Preloved + More
        Row(
          children: [
            // Preloved – wide
            Expanded(
              flex: 2,
              child: _BentoCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Color(0xFFE0266F), size: 24),
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
            // More – small square
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

class _BentoCard extends StatelessWidget {
  final Widget child;
  final double minHeight;

  const _BentoCard({required this.child, this.minHeight = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
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
      child: child,
    );
  }
}

// ─── Promo Banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                    const Icon(Icons.trending_up_rounded, color: kOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'EARN EXTRA INCOME',
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
                  '🏪 Turn Your Dorm Into a Store!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    'Why just buy when you can earn? Join the UMART seller community and start making money today. Zero fees to start.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  child: const Text('Start Earning',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
          ),
          // Decorative storefront icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFE0CC).withOpacity(0.7),
                      const Color(0xFFD8E0FF).withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                    color: const Color(0xFFFFB84D).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const Icon(
                Icons.storefront_rounded,
                color: Color(0xFFFF6B00),
                size: 42,
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

  const _FoodItem({
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.imageUrl,
  });
}

class _FoodCarousel extends StatelessWidget {
  final List<_FoodItem> items;

  const _FoodCarousel({required this.items});

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
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all',
                    style: TextStyle(color: kBlue, fontSize: 14)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _FoodCard(item: item),
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
      width: 160,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Badge
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
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              if (item.badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badge!,
                      style: const TextStyle(
                          color: kWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          // Label
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: kOrange, size: 13),
                    const SizedBox(width: 2),
                    Text('4.7',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 11)),
                    const SizedBox(width: 6),
                    Text('20-30 min',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kWhite.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: kWhite.withOpacity(0.6), width: 1),
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
                child:
                    const Icon(Icons.pedal_bike_rounded, color: kBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arriving in 5 mins',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? kBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    _icons[i],
                    color: selected ? kWhite : Colors.grey[400],
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
                  ]
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}