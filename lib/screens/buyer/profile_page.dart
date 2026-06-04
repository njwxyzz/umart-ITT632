import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import '../auth/login_page.dart';
import '../../utils/store_status.dart';
import '../../utils/campus_scope.dart';

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

enum _SellerBadgeKind { buyer, verified, pending, rejected }

// ─── Profile Page ─────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _fullName = "Student";
  String _matricNo = "No Matric ID";
  String _initial = "S";
  String _college = "UiTM Campus";
  String _campusName = kCampusDisplayName;
  String? _profileImageUrl;
  _SellerBadgeKind _sellerBadge = _SellerBadgeKind.buyer;
  
  double _totalSpent = 0.0;
  int _totalOrders = 0;
  double _avgPerOrder = 0.0;

  List<_MonthSpend> _monthlySpendData = [];
  List<_FavRestaurant> _favouritesData = [];

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      String uid = currentUser.uid;

      // 1. Tarik Data Profil (Nama, Matrik, Kolej)
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        var data = userDoc.data()!;
        _fullName = data['fullName'] ?? currentUser.email?.split('@')[0] ?? 'Student';
        _matricNo = data['studentId'] ?? 'Unknown Matric';
        _college = data['college'] ?? 'UiTM Campus';
        _campusName = campusLabelFromData(data);
        final rawImage = (data['profileImage'] ?? data['photoUrl'] ?? data['imageUrl'] ?? '')
            .toString()
            .trim();
        _profileImageUrl = rawImage.isEmpty ? null : rawImage;
        _initial = _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'S';
      } else {
        _fullName = currentUser.email?.split('@')[0].toUpperCase() ?? 'Student';
        _initial = _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'S';
      }

      // 2. Seller badge (approved / pending / rejected)
      _sellerBadge = _SellerBadgeKind.buyer;
      var storeDoc = await FirebaseFirestore.instance.collection('stores').doc(uid).get();
      void applyStoreData(Map<String, dynamic> d) {
        if (storeIsApproved(d)) {
          _sellerBadge = _SellerBadgeKind.verified;
        } else if (storeIsPending(d)) {
          _sellerBadge = _SellerBadgeKind.pending;
        } else if (storeIsRejected(d)) {
          _sellerBadge = _SellerBadgeKind.rejected;
        }
      }

      if (storeDoc.exists) {
        applyStoreData(storeDoc.data()!);
      } else {
        final storeByOwner = await FirebaseFirestore.instance
            .collection('stores')
            .where('ownerId', isEqualTo: uid)
            .limit(1)
            .get();
        if (storeByOwner.docs.isNotEmpty) {
          applyStoreData(storeByOwner.docs.first.data());
        }
      }

      // 3. Kira Semua Stats
      var ordersQuery = await FirebaseFirestore.instance.collection('orders').where('buyerId', isEqualTo: uid).get();
      
      int orderCount = 0;
      double spent = 0.0;
      
      DateTime now = DateTime.now();
      Map<int, double> monthlyTotals = {};
      for (int i = 0; i < 4; i++) {
        int targetMonth = now.month - i;
        if (targetMonth <= 0) targetMonth += 12; 
        monthlyTotals[targetMonth] = 0.0; 
      }

      Map<String, Map<String, dynamic>> sellerStats = {};

      for (var doc in ordersQuery.docs) {
        var data = doc.data();

        final status = (data['status'] ?? '').toString();
        final shouldCountInSpending =
            status != 'Rejected' && status != 'Cancelled';

        if (shouldCountInSpending) {
          double price = data['totalPrice'] is num ? (data['totalPrice'] as num).toDouble() : 0.0;
          orderCount++;
          spent += price;

          if (data['createdAt'] != null) {
            DateTime orderDate = (data['createdAt'] as Timestamp).toDate();
            for (int i = 0; i < 4; i++) {
              int targetMonth = now.month - i;
              int targetYear = now.year;
              if (targetMonth <= 0) {
                targetMonth += 12;
                targetYear -= 1;
              }
              if (orderDate.month == targetMonth && orderDate.year == targetYear) {
                monthlyTotals[targetMonth] = (monthlyTotals[targetMonth] ?? 0.0) + price;
                break;
              }
            }
          }

          final String sName = (data['sellerName'] ?? 'Unknown Store').toString();
          final String sId = (data['sellerId'] ?? '').toString();
          final String sellerKey = sId.isNotEmpty ? sId : sName;
          if (!sellerStats.containsKey(sellerKey)) {
            sellerStats[sellerKey] = {
              'name': sName,
              'sellerId': sId,
              'orders': 0,
              'totalSpent': 0.0,
            };
          }
          sellerStats[sellerKey]!['orders'] += 1;
          sellerStats[sellerKey]!['totalSpent'] += price;
        }
      }

      _totalOrders = orderCount;
      _totalSpent = spent;
      _avgPerOrder = _totalOrders > 0 ? (_totalSpent / _totalOrders) : 0.0;

      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      List<_MonthSpend> tempMonths = [];
      for (int i = 3; i >= 0; i--) {
        int targetMonth = now.month - i;
        if (targetMonth <= 0) targetMonth += 12;
        tempMonths.add(_MonthSpend(monthNames[targetMonth - 1], monthlyTotals[targetMonth] ?? 0.0));
      }
      _monthlySpendData = tempMonths;

      List<MapEntry<String, Map<String, dynamic>>> sortedSellers = sellerStats.entries.toList();
      sortedSellers.sort((a, b) {
         int orderDiff = b.value['orders'].compareTo(a.value['orders']);
         if (orderDiff != 0) return orderDiff;
         return b.value['totalSpent'].compareTo(a.value['totalSpent']);
      });

      List<_FavRestaurant> tempFavs = [];
      for (int i = 0; i < sortedSellers.length && i < 3; i++) {
        var s = sortedSellers[i];
        final sellerData = s.value;
        final sellerId = (sellerData['sellerId'] ?? '').toString();
        final sellerName = (sellerData['name'] ?? s.key).toString();
        final sellerMeta = await _resolveStoreMeta(
          sellerId: sellerId,
          sellerName: sellerName,
        );

        tempFavs.add(_FavRestaurant(
          name: (sellerMeta['storeName'] ?? sellerName).toString(),
          category: (sellerMeta['category'] ?? 'Store').toString(),
          orders: s.value['orders'],
          totalSpent: s.value['totalSpent'],
          photo: (sellerMeta['photoUrl'] ?? '').toString(),
        ));
      }
      _favouritesData = tempFavs;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      print("Error fetching profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _resolveStoreMeta({
    required String sellerId,
    required String sellerName,
  }) async {
    final fallback = <String, String>{
      'storeName': sellerName,
      'category': 'Store',
      'photoUrl': '',
    };

    try {
      if (sellerId.isNotEmpty) {
        final storeByDoc = await FirebaseFirestore.instance.collection('stores').doc(sellerId).get();
        if (storeByDoc.exists) {
          final data = storeByDoc.data() ?? <String, dynamic>{};
          return _toStoreMeta(data, fallbackName: sellerName);
        }

        final storeByOwner = await FirebaseFirestore.instance
            .collection('stores')
            .where('ownerId', isEqualTo: sellerId)
            .limit(1)
            .get();
        if (storeByOwner.docs.isNotEmpty) {
          final data = storeByOwner.docs.first.data();
          return _toStoreMeta(data, fallbackName: sellerName);
        }
      }

      if (sellerName.isNotEmpty) {
        final byName = await FirebaseFirestore.instance
            .collection('stores')
            .where('storeName', isEqualTo: sellerName)
            .limit(1)
            .get();
        if (byName.docs.isNotEmpty) {
          final data = byName.docs.first.data();
          return _toStoreMeta(data, fallbackName: sellerName);
        }
      }
    } catch (_) {}

    return fallback;
  }

  Map<String, String> _toStoreMeta(
    Map<String, dynamic> data, {
    required String fallbackName,
  }) {
    final photo = (data['storePhotoUrl'] ??
            data['storePhoto'] ??
            data['logoUrl'] ??
            data['profileImage'] ??
            data['imageUrl'] ??
            '')
        .toString()
        .trim();
    final category = (data['category'] ?? 'Store').toString().trim();
    final storeName = (data['storeName'] ?? fallbackName).toString().trim();

    return <String, String>{
      'storeName': storeName.isEmpty ? fallbackName : storeName,
      'category': category.isEmpty ? 'Store' : category,
      'photoUrl': photo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return const Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/bg_pattern.jpg'), repeat: ImageRepeat.repeat, opacity: 0.05),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: topPad + 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Profile', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF1A1A2E)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Profile Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), 
                child: _ProfileCard(
                  fullName: _fullName, 
                  matricNo: _matricNo, 
                  initial: _initial,
                  profileImageUrl: _profileImageUrl,
                  college: _college,
                  campusName: _campusName,
                  sellerBadge: _sellerBadge,
                  onEditTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                    setState(() => _isLoading = true);
                    _fetchProfileData();
                  }
                )
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), 
                child: _StatsRow(
                  totalSpent: _totalSpent, 
                  totalOrders: _totalOrders, 
                  avgPerOrder: _avgPerOrder
                )
              ),

              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), 
                child: _SpendingCard(monthlySpend: _monthlySpendData)
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Favourite Places', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 17, fontWeight: FontWeight.w700)),
                    Text('Based on your orders', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              
              if (_favouritesData.isEmpty)
                 Padding(
                   padding: const EdgeInsets.all(20),
                   child: Center(
                     child: Text('No orders yet. Start exploring!', style: TextStyle(color: Colors.grey.shade500)),
                   ),
                 )
              else
                ..._favouritesData.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _FavouriteCard(restaurant: e.value, rank: e.key + 1),
                    )),

              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.08),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
                    ),
                    title: Text(
                      'Log out',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade700,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Sign out of your account',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile Card ──────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String fullName;
  final String matricNo;
  final String initial;
  final String? profileImageUrl;
  final String college;
  final String campusName;
  final _SellerBadgeKind sellerBadge;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.fullName, 
    required this.matricNo, 
    required this.initial,
    this.profileImageUrl,
    required this.college,
    required this.campusName,
    required this.sellerBadge,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimary, Color(0xFF3A5230)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kWhite.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                        ? Image.network(
                            profileImageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: kWhite,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: kWhite,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(width: 14, height: 14, decoration: BoxDecoration(color: kAccent, shape: BoxShape.circle, border: Border.all(color: kPrimary, width: 2))),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: const TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: kWhite.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text(matricNo, style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            campusName,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(college, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        late final String label;
                        late final IconData icon;
                        late final Color fg;
                        late final Color bg;
                        late final Color border;
                        switch (sellerBadge) {
                          case _SellerBadgeKind.verified:
                            label = 'Verified Seller';
                            icon = Icons.verified_rounded;
                            fg = kAccent;
                            bg = kAccent.withOpacity(0.2);
                            border = kAccent;
                            break;
                          case _SellerBadgeKind.pending:
                            label = 'Seller application pending';
                            icon = Icons.hourglass_top_rounded;
                            fg = const Color(0xFFE6A23C);
                            bg = const Color(0xFFE6A23C).withOpacity(0.2);
                            border = const Color(0xFFE6A23C);
                            break;
                          case _SellerBadgeKind.rejected:
                            label = 'Seller application not approved';
                            icon = Icons.info_outline_rounded;
                            fg = Colors.red.shade300;
                            bg = Colors.red.withOpacity(0.15);
                            border = Colors.red.shade200;
                            break;
                          case _SellerBadgeKind.buyer:
                            label = 'Student Buyer';
                            icon = Icons.person_rounded;
                            fg = kWhite;
                            bg = kPrimaryLight.withOpacity(0.3);
                            border = kPrimaryLight;
                            break;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 12, color: fg),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onEditTap, 
            child: Container(
              width: double.infinity, height: 42,
              decoration: BoxDecoration(color: kWhite.withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: kWhite.withOpacity(0.3), width: 1)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_rounded, color: kWhite, size: 15),
                  SizedBox(width: 8),
                  Text('Edit Profile', style: TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ──────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final double totalSpent;
  final int totalOrders;
  final double avgPerOrder;

  const _StatsRow({required this.totalSpent, required this.totalOrders, required this.avgPerOrder});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'Total Spent', value: 'RM ${totalSpent.toStringAsFixed(2)}', icon: Icons.account_balance_wallet_rounded, color: kPrimary, bgColor: kPrimary.withOpacity(0.1)),
        const SizedBox(width: 10),
        _StatCard(label: 'Orders', value: '$totalOrders', icon: Icons.shopping_bag_rounded, color: kAccent, bgColor: kAccent.withOpacity(0.1)),
        const SizedBox(width: 10),
        _StatCard(label: 'Avg / Order', value: 'RM ${avgPerOrder.toStringAsFixed(2)}', icon: Icons.trending_up_rounded, color: kPrimaryLight, bgColor: kPrimaryLight.withOpacity(0.1)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: color)),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Spending Chart Card ──────────────────────────────────────────────────────
class _SpendingCard extends StatelessWidget {
  final List<_MonthSpend> monthlySpend;
  const _SpendingCard({required this.monthlySpend});
  @override
  Widget build(BuildContext context) {
    final maxVal = monthlySpend.isNotEmpty ? monthlySpend.map((e) => e.amount).reduce((a, b) => a > b ? a : b) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bar_chart_rounded, size: 15, color: kPrimary)),
                  const SizedBox(width: 8),
                  const Text('My Spending', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              Text('Last 4 months', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: monthlySpend.map((item) {
                final ratio = maxVal > 0 ? item.amount / maxVal : 0.0;
                final isHighest = maxVal > 0 && item.amount == maxVal;
                return _BarColumn(month: item.month, amount: item.amount, ratio: ratio, isHighest: isHighest);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String month;
  final double amount;
  final double ratio;
  final bool isHighest;
  const _BarColumn({required this.month, required this.amount, required this.ratio, required this.isHighest});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount > 0)
          Text('RM${amount.toStringAsFixed(0)}', style: TextStyle(color: isHighest ? kPrimary : Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600), curve: Curves.easeOut, width: 36, height: ratio * 64,
          decoration: BoxDecoration(color: isHighest ? kPrimary : kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 6),
        Text(month, style: TextStyle(color: isHighest ? const Color(0xFF1A1A2E) : Colors.grey[400], fontSize: 11, fontWeight: isHighest ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }
}

// ─── Favourite Restaurant Card ────────────────────────────────────────────────
class _FavouriteCard extends StatelessWidget {
  final _FavRestaurant restaurant;
  final int rank;
  const _FavouriteCard({required this.restaurant, required this.rank});
  @override
  Widget build(BuildContext context) {
    final themeColor = rank == 1 ? kAccent : rank == 2 ? kPrimaryLight : kPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(
        children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text('#$rank', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w800)))),
          const SizedBox(width: 12),
          Container(width: 52, height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: kBg), clipBehavior: Clip.hardEdge, child: Image.network(restaurant.photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.1), child: const Icon(Icons.storefront_rounded, color: kPrimary)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(restaurant.category, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const SizedBox(height: 6),
                Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${restaurant.orders} orders', style: TextStyle(color: themeColor, fontSize: 10, fontWeight: FontWeight.w700)))]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM ${restaurant.totalSpent.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('total spent', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────
class _MonthSpend {
  final String month;
  final double amount;
  const _MonthSpend(this.month, this.amount);
}
class _FavRestaurant {
  final String name;
  final String category;
  final int orders;
  final double totalSpent;
  final String photo;
  const _FavRestaurant({required this.name, required this.category, required this.orders, required this.totalSpent, required this.photo});
}