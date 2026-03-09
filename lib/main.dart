// ============================================================================
// IMPORTS & MAIN ENTRY POINT
// ============================================================================
import 'dart:ui'; 
import 'package:flutter/material.dart'; 
import 'activity_page.dart';
import 'profile_page.dart';
import 'all_products_page.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import 'tracking_page.dart';
import 'orders_page.dart';
import 'chat_page.dart';
import 'onboarding_screen.dart'; 
// <--- Tambah ni
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
        scaffoldBackgroundColor: const Color(0xFFF5F7F2), // Off-white dengan tone hijau sikit
      ),
      home: const OnboardingScreen(), // <---  
    );
  }
}

// ============================================================================
// GLOBAL COLOR CONSTANTS (TEMA HIJAU BARU!)
// ============================================================================
const kPrimary      = Color(0xFF4C6B3F); // Olive Green (Hijau utama)
const kPrimaryLight = Color(0xFF799B61); // Lighter Olive (Untuk gradient)
const kAccent       = Color(0xFFF27B35); // Oren (Untuk butang/badge supaya menonjol)
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

Widget _iconAsset(String path, {double radius = 12}) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
    );

// ============================================================================
// HOME SCREEN
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  bool hasActiveOrder = true;

  final List<_FoodItem> _foodItems = const [
    _FoodItem(label: 'Mak Cik Nasi Lemak', badge: '20% OFF', badgeColor: kAccent, imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400', price: 8.50, rating: 4.8, sellerName: 'Mak Cik Nasi Lemak'),
    _FoodItem(label: 'Ramen House', badge: null, badgeColor: null, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400', price: 15.90, rating: 4.7, sellerName: 'Ramen House'),
    _FoodItem(label: 'Bake P...', badge: 'Free deli', badgeColor: kPrimary, imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400', price: 6.20, rating: 4.6, sellerName: 'Bake P Bakery'),
    _FoodItem(label: 'Burger Lab', badge: '10% OFF', badgeColor: kAccent, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400', price: 10.50, rating: 4.9, sellerName: 'Burger Lab'),
  ];

  Widget _buildBody() {
    switch (currentIndex) {
      case 1: return const OrdersPage();
      case 2: return const ActivityPage();
      case 3: return const ProfilePage();
      default: return _buildHomeContent();
    }
  }

  void _openAllProductPage() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AllProductPage(title: 'All Products', items: _foodItems)));
  }

  Widget _buildHomeContent() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 160 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GradientHeader(),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _BentoGrid(foodItems: _foodItems)),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _PromoBanner()),
          const SizedBox(height: 20),
          _FoodCarousel(items: _foodItems, onSeeAll: _openAllProductPage),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
      // BACKGROUND PATTERN 
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'), // Nama fail Canva kau
            repeat: ImageRepeat.repeat, // Jadikan dia corak berulang
            opacity: 0.05, // 5% pudar supaya tak serabut mata
          ),
        ),
        child: Stack(
          children: [
            _buildBody(),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentIndex == 0 && hasActiveOrder) ...[
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _TrackingBanner()),
                      const SizedBox(height: 10),
                    ],
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad > 0 ? bottomPad : 16),
                      child: _BottomNav(selectedIndex: currentIndex, onTap: (i) => setState(() => currentIndex = i)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override Widget build(BuildContext context) => Center(child: Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)));
}

// ============================================================================
// GRADIENT HEADER (Olive Green)
// ============================================================================
class _GradientHeader extends StatelessWidget {
  const _GradientHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kPrimary, kPrimaryLight], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Location', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Row(children: [Icon(Icons.location_on, color: kWhite, size: 16), SizedBox(width: 4), Text('UiTM Perlis, Kolej Dahlia', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 14))]),
                ],
              ),
              Row(
                children: [
                  // --- BUTANG CHAT YANG DAH DITAMBAH GESTURE DETECTOR ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline_rounded, color: kWhite, size: 20)),
                        Positioned(top: -2, right: -2, child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle), child: const Center(child: Text('3', style: TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.bold))))),
                      ],
                    ),
                  ),
                  // -------------------------------------------------------
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartPage())),
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, color: kWhite, size: 20)),
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(radius: 20, backgroundColor: kWhite, child: Text('U', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
            child: const TextField(decoration: InputDecoration(hintText: 'Search for food, parcel...', border: InputBorder.none, icon: Icon(Icons.search, color: Colors.grey))),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CATEGORY BENTO GRID (Warna Pastel Earth Tone)
// ============================================================================
class _BentoGrid extends StatelessWidget {
  final List<_FoodItem> foodItems; 
  const _BentoGrid({required this.foodItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoCard(
                  minHeight: 170,
                  bgColor: Colors.green.shade50, // Pastel Green
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductPage(title: 'Food', items: foodItems))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 80, height: 80, decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.1), blurRadius: 10)]), child: _iconAsset('assets/icons/food_icons.png', radius: 18)),
                      const SizedBox(height: 12),
                      const Text('Food', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Order meals nearby', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _BentoCard(
                      bgColor: Colors.orange.shade50, // Pastel Orange
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProductPage(title: 'Parcel', items: []))),
                      child: Row(
                        children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)), child: _iconAsset('assets/icons/parcel_icons.png', radius: 12)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Parcel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('Send & receive', style: TextStyle(color: Colors.grey[600], fontSize: 11))])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _BentoCard(
                      bgColor: Colors.brown.shade50, // Pastel Brown
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProductPage(title: 'Printing', items: []))),
                      child: Row(
                        children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)), child: _iconAsset('assets/icons/printing_icons.png', radius: 12)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Printing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('Print & copy', style: TextStyle(color: Colors.grey[600], fontSize: 11))])),
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
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _BentoCard(
                bgColor: Colors.teal.shade50, // Pastel Teal
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProductPage(title: 'Preloved', items: []))),
                child: Row(
                  children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)), child: _iconAsset('assets/icons/preloved_icons.png', radius: 12)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Preloved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text('Buy & sell items', style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BentoCard(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.more_horiz_rounded, color: Colors.grey[600], size: 28), const SizedBox(height: 4), Text('More', style: TextStyle(color: Colors.grey[600], fontSize: 13))],
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
  final Color bgColor;
  final VoidCallback? onTap;

  const _BentoCard({required this.child, this.minHeight = 72, this.bgColor = Colors.white, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        width: double.infinity,
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.9), bgColor]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
            BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ============================================================================
// PROMOTIONAL BANNER (Earthy Dark Tone)
// ============================================================================
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3B22), // Dark Forest Green
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: kAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Text('EARN EXTRA INCOME', style: TextStyle(color: kAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
                const SizedBox(height: 12),
                const Text('Turn Your Dorm\nInto a Store!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kWhite, height: 1.3)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: kAccent, foregroundColor: kWhite, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('Start Earning', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const Icon(Icons.storefront_rounded, size: 80, color: Colors.white24),
        ],
      ),
    );
  }
}

// ============================================================================
// HORIZONTAL FOOD CAROUSEL
// ============================================================================
class _FoodItem {
  final String label;
  final String? badge;
  final Color? badgeColor;
  final String imageUrl;
  final double price;
  final double rating;
  final String sellerName;

  const _FoodItem({required this.label, required this.badge, required this.badgeColor, required this.imageUrl, required this.price, required this.rating, required this.sellerName});
}

class _FoodCarousel extends StatelessWidget {
  final List<_FoodItem> items;
  final VoidCallback onSeeAll;
  const _FoodCarousel({required this.items, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order dinner from', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              TextButton(onPressed: onSeeAll, child: const Text('See all', style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        SizedBox(
          height: 235,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _FoodCard(item: items[index])),
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
    return GestureDetector( // <--- TAMBAH INI
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductDetailPage()));
      },
      child: Container( // <--- GANTI "return Container" JADI "child: Container"
        width: 170,
        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(height: 120, width: double.infinity, child: Image.network(item.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey)))),
                    if (item.badge != null) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: item.badgeColor, borderRadius: BorderRadius.circular(8)), child: Text(item.badge!, style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w700)))),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RM${item.price.toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 12)), Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star_rounded, color: kAccent, size: 12), const SizedBox(width: 2), Text(item.rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey[700], fontSize: 10))])]),
                      const SizedBox(height: 4),
                      Row(children: [Icon(Icons.storefront_rounded, size: 12, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text(item.sellerName, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(bottom: 10, right: 10, child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle), child: const Icon(Icons.add, color: kWhite, size: 18))),
          ],
        ),
      ),
    ); // <--- TUTUP GESTURE DETECTOR KAT SINI
  }
}

// ============================================================================
// LIVE TRACKING BANNER
// ============================================================================
class _TrackingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: kWhite.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: kWhite.withOpacity(0.6), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))]),
          child: Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.pedal_bike_rounded, color: kPrimary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Arriving in 5 mins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('To Dahlia 3', style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
              ElevatedButton(
                onPressed: () {
                  // MAGIK: Lompat ke Tracking Page bila tekan!
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent, // Warna oren
                  foregroundColor: kWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Track', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM NAVIGATION BAR
// ============================================================================
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _icons = [Icons.home_rounded, Icons.list_alt_rounded, Icons.show_chart_rounded, Icons.person_outline_rounded];
  static const _labels = ['Home', 'Orders', 'Activity', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 6))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_icons.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: selected ? kPrimary : Colors.transparent, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Icon(_icons[i], color: selected ? kWhite : Colors.grey[700], size: 22),
                  if (selected) ...[const SizedBox(width: 6), Text(_labels[i], style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600, fontSize: 13))],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}