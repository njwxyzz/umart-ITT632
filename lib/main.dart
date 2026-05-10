// ============================================================================
// IMPORTS & MAIN ENTRY POINT
// ============================================================================
import 'dart:ui'; 
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Pages Imports
import 'screens/admin_web/admin_dashboard_page.dart';

import 'screens/buyer/profile_page.dart';
import 'screens/buyer/all_products_page.dart';
import 'screens/buyer/cart_page.dart';
import 'screens/buyer/product_detail_page.dart';
import 'screens/buyer/tracking_page.dart';
import 'screens/buyer/orders_page.dart';
import 'screens/buyer/inbox_page.dart'; 
import 'screens/buyer/chat_page.dart';
import 'screens/auth/onboarding_screen.dart'; 
import 'screens/seller/seller_registration_page.dart';
import 'screens/buyer/store_profile_page.dart';
import 'screens/buyer/cart_manager.dart';
import 'screens/buyer/notifications_page.dart';
import 'screens/seller/seller_dashboard.dart'; 
import 'utils/store_status.dart';
import 'utils/product_status.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await CartManager.instance.restore();

  var firstAuthEvent = true;
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (firstAuthEvent) {
      firstAuthEvent = false;
      await CartManager.instance.onAuthEvent(user, isInitial: true);
    } else {
      await CartManager.instance.onAuthEvent(user, isInitial: false);
    }
  });

  runApp(const UMartApp()); 
}

class UMartApp extends StatelessWidget { 
  const UMartApp({super.key});

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMART',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // CCTV PINTU PAGAR (Auth Gate)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Tengah loading tunggu jawapan dari Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          
          // 2. Kalau user DAH LOGIN
          if (snapshot.hasData) {
            final user = snapshot.data!;

            // debug
            print("🚀 User logged in: ${user.email} (UID: ${user.uid})");


            
            // LOGIK VIP: Check kalau yang login tu e-mel admin
            if (user.email?.trim().toLowerCase() == 'admin@umart.com') {
              return const AdminDashboardPage(); 
            } 
            // Kalau e-mel budak student atau seller biasa
            else {
              return const HomeScreen(); 
            }
          }
          
          // 3. Kalau user BELUM LOGIN (atau baru je tekan Logout)
          return const OnboardingScreen(); 
        },
      ),
    );
  }
}

// ============================================================================
// GLOBAL COLOR CONSTANTS (NEW GREEN THEME!)
// ============================================================================
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

Widget _iconAsset(String path, {double radius = 12}) => ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(path, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
    );

// ============================================================================
// HOME SCREEN (Main Wrapper)
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  // 🚨 KOTAK MEMORI UNTUK CARIAN 🚨
  String _searchQuery = ''; 

  List<_FoodItem> _allProducts = []; 
  List<_FoodItem> _foodItems = []; 
  List<_FoodItem> _prelovedItems = []; 
  List<_FoodItem> _printingItems = []; 
  List<_FoodItem> _otherItems = []; 

  bool _isLoadingProducts = true;
  bool _productsLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchProductsData(); 
  }

  Future<void> _fetchProductsData() async {
    if (mounted) {
      setState(() {
        _isLoadingProducts = true;
        _productsLoadFailed = false;
      });
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
      
      List<_FoodItem> tempAll = [];
      List<_FoodItem> tempFood = [];
      List<_FoodItem> tempPreloved = [];
      List<_FoodItem> tempPrinting = [];
      List<_FoodItem> tempOther = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (!productIsApproved(data)) continue;

        double harga = data['price'] is num ? (data['price'] as num).toDouble() : double.tryParse(data['price'].toString()) ?? 0.0;
        int soldCount = 0;
        final soldRaw = data['sold'] ?? data['soldCount'] ?? data['totalSold'];
        if (soldRaw is num) {
          soldCount = soldRaw.toInt();
        } else {
          soldCount = int.tryParse(soldRaw?.toString() ?? '0') ?? 0;
        }

        String productCategory = data['category'] ?? 'Others';

        _FoodItem item = _FoodItem(
          productId: doc.id,
          label: data['name'] ?? 'Unknown Item', 
          badge: data['badge'], 
          badgeColor: data['badge'] != null ? kAccent : null, 
          imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
          price: harga,
          soldCount: soldCount,
          sellerName: data['sellerName'] ?? 'Unknown Seller',
          sellerId: (data['sellerId'] ?? data['ownerId'] ?? '').toString(),
          category: productCategory, 
          description: data['description'] ?? 'No description available.', 
        );

        tempAll.add(item);

        if (productCategory == 'Food & Beverages') {
          tempFood.add(item);
        } else if (productCategory == 'Preloved Items') {
          tempPreloved.add(item);
        } else if (productCategory == 'Printing Services') {
          tempPrinting.add(item);
        } else {
          tempOther.add(item); 
        }
      }

      if (mounted) {
        setState(() {
          _allProducts = tempAll;
          _foodItems = tempFood;
          _prelovedItems = tempPreloved;
          _printingItems = tempPrinting;
          _otherItems = tempOther;
          _isLoadingProducts = false;
          _productsLoadFailed = false;
        });
      }
    } catch (e) {
      print("🚨 CRITICAL ERROR: Failed to fetch products -> $e");
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _productsLoadFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not load products. Check your connection and try again.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _fetchProductsData(),
          ),
        ),
      );
    }
  }

  Widget _buildProductsLoadErrorPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Material(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Products unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                'We could not reach the product catalog. Check Wi‑Fi or mobile data, then try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingProducts ? null : () => _fetchProductsData(),
                  icon: const Icon(Icons.refresh_rounded, color: kWhite),
                  label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (currentIndex) {
      case 1: return const OrdersPage();
      case 2: return const InboxPage();   
      case 3: return const ProfilePage(); 
      default: return _buildHomeContent();
    }
  }

  void _openAllProductPage() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AllProductPage(title: 'All Campus Items', items: _allProducts)));
  }

  // 🚨 UI HASIL CARIAN LIVE 🚨
  Widget _buildSearchResults() {
    // Mesin penapis live
    var results = _allProducts.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.label.toLowerCase().contains(query) ||
             item.sellerName.toLowerCase().contains(query) ||
             item.category.toLowerCase().contains(query);
    }).toList();

    // Kalau cari tapi tak jumpa
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('No items found for "$_searchQuery"', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    // Kalau jumpa, susun macam grid
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text('Search Results (${results.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Scroll ikut page luar
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) => _FoodCard(item: results[index]),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 160 + bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚨 HEADER SEKARANG BOLEH DENGAR APA USER TAIP 🚨
          _GradientHeader(
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
          const SizedBox(height: 20),
          
          if (_isLoadingProducts) 
            const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: kPrimary)))
          else if (_productsLoadFailed)
            _buildProductsLoadErrorPanel()
          else if (_searchQuery.isNotEmpty) 
            // KALAU ADA TAIP SESUATU, TUNJUK HASIL CARIAN
            _buildSearchResults()
          else 
            // KALAU KOTAK SEARCH KOSONG, TUNJUK BENTO & PROMO MACAM BIASA
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16), 
                  child: _BentoGrid(
                    foodItems: _foodItems,
                    prelovedItems: _prelovedItems,
                    printingItems: _printingItems,
                    otherItems: _otherItems,
                  )
                ),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _PromoBanner()),
                const SizedBox(height: 20),
                _FoodCarousel(items: _foodItems, onSeeAll: _openAllProductPage),
              ],
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'), 
            repeat: ImageRepeat.repeat, 
            opacity: 0.05, 
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
                    if (currentIndex == 0) ...[
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: const _HomeLiveTrackingBanner()),
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

// ============================================================================
// GRADIENT HEADER 
// ============================================================================
class _GradientHeader extends StatefulWidget {
  final ValueChanged<String>? onSearch; // 🚨 WAYAR UNTUK SEARCH 🚨

  const _GradientHeader({this.onSearch});

  @override
  State<_GradientHeader> createState() => _GradientHeaderState();
}

class _GradientHeaderState extends State<_GradientHeader> {
  String _userName = "Student"; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData(); 
  }

  Future<void> _fetchProfileData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            String fullName = userDoc['fullName'] ?? 'Student';
            _userName = fullName.split(' ')[0]; 
            _isLoading = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _userName = "User"; 
              _isLoading = false; 
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userName = "Guest";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Oops, error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildHomeNotificationButton(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        ),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: kWhite.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.notifications_outlined, color: kWhite, size: 20),
        ),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        var unread = 0;
        if (snapshot.hasData) {
          for (final d in snapshot.data!.docs) {
            if (d.data()['read'] != true) unread++;
          }
        }
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: kWhite.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.notifications_outlined, color: kWhite, size: 20),
              ),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimary, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kWhite, fontSize: 9, fontWeight: FontWeight.bold, height: 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoading ? 'Loading...' : 'Hi, $_userName! 👋', 
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  const Row(children: [Icon(Icons.location_on, color: kWhite, size: 14), SizedBox(width: 4), Text('UiTM Perlis, Kolej Dahlia', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                ],
              ),
              Row(
                children: [
                  _buildHomeNotificationButton(context),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartPage())),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: kWhite.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_cart_outlined, color: kWhite, size: 20),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: CartManager.instance.cartItemCount, 
                          builder: (context, count, child) {
                            if (count == 0) return const SizedBox.shrink(); 
                            
                            return Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kAccent, 
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kPrimary, width: 2), 
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
            child: TextField(
              onChanged: widget.onSearch, // 🚨 SENSOR DIPASANG 🚨
              decoration: const InputDecoration(hintText: 'Search for food, parcel...', border: InputBorder.none, icon: Icon(Icons.search, color: Colors.grey))
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CATEGORY BENTO GRID 
// ============================================================================
class _BentoGrid extends StatelessWidget {
  final List<_FoodItem> foodItems; 
  final List<_FoodItem> prelovedItems; 
  final List<_FoodItem> printingItems; 
  final List<_FoodItem> otherItems; 

  const _BentoGrid({
    required this.foodItems,
    required this.prelovedItems,
    required this.printingItems,
    required this.otherItems,
  });

  void _showMoreCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              const SizedBox(height: 24),
              const Text('All Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.purple.shade100, child: const Icon(Icons.electrical_services_rounded, color: Colors.purple)),
                title: const Text('Electronics & Gadgets', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProductPage(title: 'Electronics', items: [])));
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.design_services_rounded, color: Colors.blue)),
                title: const Text('Design Services', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const AllProductPage(title: 'Services', items: [])));
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.category_rounded, color: Colors.grey)),
                title: const Text('Others / Miscellaneous', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductPage(title: 'Others', items: otherItems))); 
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

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
                  bgColor: Colors.green.shade50,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductPage(title: 'Food & Beverages', items: foodItems))),
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
                      bgColor: Colors.orange.shade50,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductPage(title: 'Parcel', items: otherItems))), 
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
                      bgColor: Colors.brown.shade50,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductPage(title: 'Printing', items: printingItems))),
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
                bgColor: Colors.teal.shade50,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllProductPage(title: 'Preloved', items: prelovedItems))),
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
                onTap: () => _showMoreCategories(context), 
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
// PREMIUM PROMOTIONAL BANNER (CAROUSEL)
// ============================================================================
class _PromoBanner extends StatefulWidget {
  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Senarai URL gambar banner (Boleh tukar nanti)
  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800', // Gambar makanan sedap
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800', // Baju preloved
    'https://images.unsplash.com/photo-1621804105073-455b5d8ef732?w=800', // Bungkusan parcel
  ];

  // Senarai tajuk untuk banner
  final List<Map<String, String>> _bannerTexts = [
    {
      'badge': 'MIDNIGHT CRAVINGS',
      'title': 'Order from your\nfavorite campus sellers!',
    },
    {
      'badge': 'PRELOVED FASHION',
      'title': 'Find hidden gems\nfrom your peers!',
    },
    {
      'badge': 'PARCEL SERVICES',
      'title': 'Too lazy to walk?\nLet us pick it up.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── CAROUSEL SLIDER ───
        SizedBox(
          height: 170, // Tinggi banner
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  // Magik sikit untuk buat effect zoom in/out masa slide
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4), // Jarak sikit antara banner
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                    image: DecorationImage(
                      image: NetworkImage(_bannerImages[index]),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken), // Gelapkan sikit supaya teks nampak jelas
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kAccent.withOpacity(0.9), 
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                child: Text(
                                  _bannerTexts[index]['badge']!, 
                                  style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
                                )
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _bannerTexts[index]['title']!, 
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kWhite, height: 1.3)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ─── DOT INDICATOR ───
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              // Lebarkan dot kalau tengah selected
              width: _currentPage == index ? 24 : 6, 
              decoration: BoxDecoration(
                color: _currentPage == index ? kPrimary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HORIZONTAL FOOD CAROUSEL
// ============================================================================
class _FoodItem {
  final String productId;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final String imageUrl;
  final double price;
  final int soldCount;
  final String sellerName;
  final String sellerId;
  final String category;
  final String description;

  const _FoodItem({
    required this.productId,
    required this.label, 
    required this.badge, 
    required this.badgeColor, 
    required this.imageUrl, 
    required this.price, 
    required this.soldCount, 
    required this.sellerName,
    required this.sellerId,
    required this.category, 
    required this.description,
  });
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
    void openProductDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            productId: item.productId,
            name: item.label,
            price: item.price,
            imageUrl: item.imageUrl,
            sellerId: item.sellerId,
            sellerName: item.sellerName,
            description: item.description,
          ),
        ),
      );
    }

    Future<void> openChatSeller() async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first to start chat.')),
        );
        return;
      }
      String targetSellerId = item.sellerId;

      if (targetSellerId.isEmpty) {
        final storeQuery = await FirebaseFirestore.instance
            .collection('stores')
            .where('storeName', isEqualTo: item.sellerName)
            .limit(1)
            .get();
        if (storeQuery.docs.isNotEmpty) {
          targetSellerId = storeQuery.docs.first.id; 
        }
      }

      if (targetSellerId.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller account not found. Please try another product.'),
          ),
        );
        return;
      }

      if (targetSellerId == currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own product.')),
        );
        return;
      }

      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final existing = await chatsRef
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String? chatId;
      for (final doc in existing.docs) {
        final data = doc.data();
        final participantsRaw = (data['participants'] as List?) ?? [];
        final participants = participantsRaw.whereType<String>().toList();
        if (participants.contains(targetSellerId)) {
          chatId = doc.id;
          break;
        }
      }

      if (chatId == null) {
        final newDoc = await chatsRef.add({
          'participants': [currentUser.uid, targetSellerId],
          'participantNames': {
            currentUser.uid: currentUser.displayName ?? 'Buyer',
            targetSellerId: item.sellerName,
          },
          'participantRoles': {
            currentUser.uid: 'Buyer',
            targetSellerId: 'Seller',
          },
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            currentUser.uid: 0,
            targetSellerId: 0,
          },
        });
        chatId = newDoc.id;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            runnerName: item.sellerName,
            chatId: chatId,
            otherUserId: targetSellerId,
          ),
        ),
      );
    }

    return GestureDetector( 
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (sheetContext) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sold by ${item.sellerName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            openProductDetail();
                          },
                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                          label: const Text('View Product'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimary,
                            side: const BorderSide(color: kPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            openChatSeller();
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat Seller'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: kWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container( 
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RM${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: kAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${item.soldCount} sold',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StoreProfilePage(sellerId: item.sellerId)));
                        },
                        behavior: HitTestBehavior.opaque, 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0), 
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 12, color: Colors.grey[500]), 
                              const SizedBox(width: 4), 
                              Expanded(child: Text(item.sellerName, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))
                            ]
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
            Positioned(bottom: 10, right: 10, child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle), child: const Icon(Icons.add, color: kWhite, size: 18))),
          ],
        ),
      ),
    ); 
  }
}
// ============================================================================
// LIVE TRACKING BANNER (Firestore — active order + live ETA / arrived)
// ============================================================================

bool _bannerLatLngValid(double lat, double lng) {
  final latOk = lat.isFinite && !lat.isNaN && lat >= -90 && lat <= 90;
  final lngOk = lng.isFinite && !lng.isNaN && lng >= -180 && lng <= 180;
  return latOk && lngOk;
}

/// Same pace assumption as [TrackingPage] (_calculateEta → minutes).
int _bannerEtaMinutes(LatLng from, LatLng to) {
  const Distance distance = Distance();
  final metres = distance.as(LengthUnit.Meter, from, to);
  if (metres.isNaN || !metres.isFinite) return 1;
  final minutes = (metres / 300 * 3).ceil();
  return minutes.clamp(1, 24 * 60);
}

/// Active = pending/processing/shipped (case-insensitive).
/// Pick the newest active order for the banner.
QueryDocumentSnapshot<Map<String, dynamic>>? _pickLiveTrackingOrder(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  const activeStatuses = {'pending', 'processing', 'shipped'};
  final activeDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  for (final doc in docs) {
    final data = doc.data();
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    if (!activeStatuses.contains(status)) continue;
    activeDocs.add(doc);
  }
  if (activeDocs.isEmpty) return null;

  activeDocs.sort((a, b) {
    final ta = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
    final tb = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
    return tb.compareTo(ta);
  });
  return activeDocs.first;
}

class _HomeLiveTrackingBanner extends StatelessWidget {
  const _HomeLiveTrackingBanner();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').where('buyerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        // Firestore / rules errors: fail silently so home layout stays clean (optional banner).
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final picked = _pickLiveTrackingOrder(snapshot.data!.docs);
        if (picked == null) return const SizedBox.shrink();

        final data = picked.data();
        final buyerLoc = (data['buyerLocation'] ?? '').toString().trim();
        final sellerArrived = data['sellerArrived'] == true;

        late final String titleText;
        late final String subtitleText;

        if (sellerArrived) {
          titleText = 'Seller has arrived!';
          subtitleText = buyerLoc.isNotEmpty ? buyerLoc : 'Head to your pickup point';
        } else {
          final status = (data['status'] ?? '').toString().trim().toLowerCase();
          final sharing = data['sellerSharing'] == true;
          final lat = (data['sellerLat'] as num?)?.toDouble();
          final lng = (data['sellerLng'] as num?)?.toDouble();
          final blat = (data['buyerLat'] as num?)?.toDouble();
          final blng = (data['buyerLng'] as num?)?.toDouble();
          final canComputeEta = sharing &&
              lat != null &&
              lng != null &&
              blat != null &&
              blng != null &&
              _bannerLatLngValid(lat, lng) &&
              _bannerLatLngValid(blat, blng);

          if (canComputeEta) {
            final mins = _bannerEtaMinutes(LatLng(lat, lng), LatLng(blat, blng));
            final arrivesAt = DateTime.now().add(Duration(minutes: mins));
            titleText = 'Arrives by ${DateFormat('h:mm a').format(arrivesAt)}';
            subtitleText = buyerLoc.isNotEmpty ? buyerLoc : 'Live delivery • ~$mins min';
          } else {
            if (status == 'pending') {
              titleText = 'Order received';
              subtitleText = 'Waiting for seller to accept your order';
            } else if (status == 'processing') {
              titleText = 'Preparing your order';
              subtitleText = 'Seller will share live tracking once on the way';
            } else {
              titleText = 'Order is on the way';
              subtitleText = buyerLoc.isNotEmpty ? buyerLoc : 'Tap Track for latest status';
            }
          }
        }

        return _TrackingBanner(orderId: picked.id, titleText: titleText, subtitleText: subtitleText);
      },
    );
  }
}

class _TrackingBanner extends StatelessWidget {
  final String orderId;
  final String titleText;
  final String subtitleText;

  const _TrackingBanner({
    required this.orderId,
    required this.titleText,
    required this.subtitleText,
  });

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitleText, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrackingPage(orderId: orderId)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
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
// BOTTOM NAVIGATION BAR (FLOATING PILL DESIGN)
// ============================================================================
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.receipt_long_rounded, label: 'Orders', index: 1),
              const SizedBox(width: 60), 
              _buildInboxNavItem(index: 2),
              _buildNavItem(icon: Icons.person_rounded, label: 'Profile', index: 3),
            ],
          ),
          
          Positioned(
            top: -20, 
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: kAccent)),
                );

                try {
                User? currentUser = FirebaseAuth.instance.currentUser;
                
                if (currentUser == null) {
                  if (context.mounted) Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sila login dahulu!')));
                  return;
                }

                String accountID = currentUser.uid;

                  var storeDoc = await FirebaseFirestore.instance.collection('stores').doc(accountID).get();

                  if (context.mounted) Navigator.pop(context);

                  if (storeDoc.exists) {
                    final storeData = storeDoc.data();
                    if (storeIsPending(storeData)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Your seller application is pending. You will get a notification when an admin approves it.',
                            ),
                          ),
                        );
                      }
                    } else if (storeIsRejected(storeData)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Your seller application was not approved. Check Notifications for details.',
                            ),
                          ),
                        );
                      }
                    } else if (storeIsApproved(storeData)) {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerDashboard(
                              storeName: storeDoc['storeName'],
                              storeLocation: storeDoc['storeLocation'],
                            ),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerDashboard(
                              storeName: storeDoc['storeName'],
                              storeLocation: storeDoc['storeLocation'],
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      _showSellActionModal(context);
                    }
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context); 
                  print("Bouncer pening: $e");
                }
              },
              child: Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kAccent.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                    border: Border.all(color: kBg, width: 4), 
                  ),
                  child: const Icon(Icons.add_rounded, color: kWhite, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? kPrimary : Colors.grey.shade400,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? kPrimary : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxNavItem({required int index}) {
    final isSelected = selectedIndex == index;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.chat_bubble_rounded,
                  color: isSelected ? kPrimary : Colors.grey.shade400,
                  size: isSelected ? 26 : 24,
                ),
                if (currentUserId != null)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('participants', arrayContains: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const SizedBox.shrink();
                        }
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        int totalUnread = 0;
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data();
                          final unreadRaw = (data['unreadCount'] as Map?) ?? {};
                          final rawValue = unreadRaw[currentUserId];
                          final count = rawValue is int
                              ? rawValue
                              : int.tryParse(rawValue?.toString() ?? '0') ?? 0;
                          totalUnread += count;
                        }
                        if (totalUnread <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: const BoxDecoration(
                            color: kAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            totalUnread > 99 ? '99+' : totalUnread.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kWhite,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Inbox',
              style: TextStyle(
                color: isSelected ? kPrimary : Colors.grey.shade400,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellActionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              const SizedBox(height: 24),
              const Icon(Icons.storefront_rounded, color: kPrimary, size: 50),
              const SizedBox(height: 16),
              const Text('Start Selling!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text('Turn your dorm into a store. Join as a seller to list your food or preloved items.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerRegistrationPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Join UMART Sellers', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }
}