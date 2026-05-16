import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../auth/login_page.dart';
import '../../utils/product_status.dart';
// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kBg = Color(0xFFF5F7F2); 
const kCardText = Color(0xFF1A1A2E);
const kAccent = Color(0xFF8AAF63);
const kSecondaryAccent = Color(0xFF6D8BEA);

enum _AdminSection { dashboard, users, stores, products, orders, reports }

class _ActivityFeedItem {
  const _ActivityFeedItem({
    required this.when,
    required this.text,
    required this.dotColor,
  });

  final DateTime? when;
  final String text;
  final Color dotColor;
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  _AdminSection _selectedSection = _AdminSection.dashboard;
  String _searchQuery = '';
  String _statusFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  int _userPage = 0;
  int _storePage = 0;
  int _productPage = 0;
  int _orderPage = 0;
  int _reportPage = 0;
  static const int _pageSize = 10;

  String _userSortBy = 'name';
  String _storeSortBy = 'store';
  String _productSortBy = 'name';
  String _orderSortBy = 'id';
  bool _userSortAsc = true;
  bool _storeSortAsc = true;
  bool _productSortAsc = true;
  bool _orderSortAsc = true;
  final Random _random = Random();

  /// Real-time pending counts for sidebar badges (one Firestore listener each).
  final Stream<int> _pendingStoresCountStream = FirebaseFirestore.instance
      .collection('stores')
      .where('status', isEqualTo: 'Pending')
      .snapshots()
      .map((s) => s.docs.length);

  final Stream<int> _pendingProductsCountStream = FirebaseFirestore.instance
      .collection('products')
      .where('status', isEqualTo: 'Pending')
      .snapshots()
      .map((s) => s.docs.length);

  final Stream<int> _pendingReportsCountStream = FirebaseFirestore.instance
      .collection('reports')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FAF3), Color(0xFFEAF2FF)],
          ),
        ),
        child: Row(
          children: [
          // ─── 1. SIDEBAR MENU (LEFT) ───
          Container(
            width: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.green.shade50.withOpacity(0.7)],
              ),
              border: Border(right: BorderSide(color: Colors.green.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(8, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'UMART ADMIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildNavItem(Icons.dashboard_rounded, 'Dashboard', _AdminSection.dashboard),
                _buildNavItem(Icons.people_alt_rounded, 'Manage Users', _AdminSection.users),
                _buildNavItem(
                  Icons.storefront_rounded,
                  'Manage Stores',
                  _AdminSection.stores,
                  pendingCountStream: _pendingStoresCountStream,
                ),
                _buildNavItem(
                  Icons.inventory_2_rounded,
                  'Manage Products',
                  _AdminSection.products,
                  pendingCountStream: _pendingProductsCountStream,
                ),
                _buildNavItem(Icons.receipt_long_rounded, 'All Orders', _AdminSection.orders),
                _buildNavItem(
                  Icons.flag_rounded,
                  'Reported Cases',
                  _AdminSection.reports,
                  pendingCountStream: _pendingReportsCountStream,
                ),
                
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    // 1. Tunjuk kotak pengesahan (optional tapi bagus untuk UX)
                    bool confirmLogout = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to sign out from Admin Panel?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ) ?? false;

                    // 2. Kalau admin confirm nak logout
                    if (confirmLogout) {
                      try {
                        await FirebaseAuth.instance.signOut();

                        // ─── KITA TAMBAH ARAHAN PATAH BALIK KE LOGIN SCREEN ───
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (Route<dynamic> route) => false, // Padam semua history skrin admin
                          );
                        }


                        // Selepas ini, StreamBuilder kat main.dart akan automatik bawa kau ke skrin Login
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error logging out: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ─── 2. MAIN CONTENT AREA (RIGHT) ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  const Text('Dashboard Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kCardText)),
                  const SizedBox(height: 8),
                  const Text('Welcome back, Super Admin!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 32),
                  
                  // ─── STATISTIC CARDS (LIVE FIREBASE) ───
                  Row(
                    children: [
                      // 1. CALCULATE TOTAL USERS
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          String userCount = "0";
                          if (snapshot.hasData) {
                            userCount = snapshot.data!.docs.length.toString();
                          }
                          return _buildStatCard(
                            'Total Users',
                            userCount,
                            Icons.people_outline_rounded,
                            Colors.blue,
                            trendLabel: '+8% this month',
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      
                      // 2. CALCULATE ACTIVE ORDERS (E.g., Pending or Processing)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('orders')
                            .where('status', whereIn: ['Pending', 'Processing']).snapshots(),
                        builder: (context, snapshot) {
                          String activeOrders = "0";
                          if (snapshot.hasData) {
                            activeOrders = snapshot.data!.docs.length.toString();
                          }
                          return _buildStatCard(
                            'Active Orders',
                            activeOrders,
                            Icons.shopping_bag_outlined,
                            Colors.orange,
                            trendLabel: 'Needs attention',
                            trendPositive: false,
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      
                      // 3. CALCULATE TOTAL REVENUE (All Delivered orders)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('orders')
                            .where('status', isEqualTo: 'Delivered').snapshots(),
                        builder: (context, snapshot) {
                          double totalRevenue = 0.0;
                          if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              // Check if totalPrice field exists and sum them up
                              if (data.containsKey('totalPrice') && data['totalPrice'] != null) {
                                totalRevenue += (data['totalPrice'] as num).toDouble();
                              }
                            }
                          }
                          return _buildStatCard(
                            'Total Revenue',
                            'RM ${totalRevenue.toStringAsFixed(2)}',
                            Icons.account_balance_wallet_outlined,
                            kPrimary,
                            trendLabel: '+12% vs last week',
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Expanded(
                    child: _selectedSection == _AdminSection.dashboard
                        ? Row(
                            children: [
                              Expanded(flex: 3, child: _buildMainPanel()),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: _buildRecentActivitiesPanel()),
                            ],
                          )
                        : _buildMainPanel(),
                  )
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF5FAFF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search users, stores, products or orders...',
                prefixIcon: Icon(Icons.search_rounded),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            side: BorderSide(color: Colors.green.shade100),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 12),
        _buildStatusFilter(),
        const SizedBox(width: 12),
        _buildDateFilterButton(
          label: _fromDate == null ? 'From date' : _formatDate(_fromDate!),
          onTap: () => _pickDate(isFrom: true),
        ),
        const SizedBox(width: 8),
        _buildDateFilterButton(
          label: _toDate == null ? 'To date' : _formatDate(_toDate!),
          onTap: () => _pickDate(isFrom: false),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Clear date filters',
          onPressed: () => setState(() {
            _fromDate = null;
            _toDate = null;
            _resetPagination();
          }),
          icon: const Icon(Icons.clear_rounded),
        ),
        const SizedBox(width: 4),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            side: BorderSide(color: Colors.green.shade100),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _exportCurrentSectionAsCsv,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Export CSV'),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF0FAF2)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: kPrimary,
                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 16),
              ),
              SizedBox(width: 8),
              Text('Super Admin', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final options = _statusOptionsForCurrentSection();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          items: options
              .map((status) => DropdownMenuItem<String>(value: status, child: Text(status)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _statusFilter = value;
              _resetPagination();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateFilterButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: Colors.green.shade100),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }

  List<String> _statusOptionsForCurrentSection() {
    if (_selectedSection == _AdminSection.stores) {
      return const ['All', 'Pending', 'Approved', 'Rejected'];
    }
    if (_selectedSection == _AdminSection.products) {
      return const ['All', 'Pending', 'Approved', 'Rejected'];
    }
    if (_selectedSection == _AdminSection.orders) {
      return const ['All', 'Pending', 'Processing', 'Delivered', 'Rejected'];
    }
    return const ['All'];
  }

  void _resetPagination() {
    _userPage = 0;
    _storePage = 0;
    _productPage = 0;
    _orderPage = 0;
    _reportPage = 0;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
      _resetPagination();
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  bool _matchesDateFilter(Map<String, dynamic> data) {
    if (_fromDate == null && _toDate == null) return true;
    final candidate = data['createdAt'] ?? data['timestamp'] ?? data['orderDate'];
    DateTime? createdAt;
    if (candidate is Timestamp) {
      createdAt = candidate.toDate();
    } else if (candidate is DateTime) {
      createdAt = candidate;
    }
    if (createdAt == null) return true;
    if (_fromDate != null && createdAt.isBefore(_fromDate!)) return false;
    if (_toDate != null && createdAt.isAfter(_toDate!)) return false;
    return true;
  }

  Widget _buildNavItem(
    IconData icon,
    String title,
    _AdminSection section, {
    Stream<int>? pendingCountStream,
  }) {
    bool isSelected = _selectedSection == section;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(colors: [Color(0x1F4C6B3F), Color(0x224C6B3F)])
            : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: isSelected ? kPrimary : Colors.grey.shade600),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? kPrimary : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (pendingCountStream != null) ...[
              const SizedBox(width: 8),
              _buildSidebarPendingBadge(pendingCountStream),
            ],
          ],
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedSection = section;
            if (!_statusOptionsForCurrentSection().contains(_statusFilter)) {
              _statusFilter = 'All';
            }
            _resetPagination();
          });
        },
      ),
    );
  }

  Widget _buildSidebarPendingBadge(Stream<int> countStream) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox(width: 22, height: 22);
        }
        final n = snapshot.data ?? 0;
        if (n <= 0) return const SizedBox.shrink();
        final label = n > 99 ? '99+' : '$n';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: const BoxConstraints(minWidth: 22),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET HELPER: Statistic Cards ---
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String trendLabel = '',
    bool trendPositive = true,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.16), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.12), color.withOpacity(0.2)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kCardText)),
            if (trendLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    trendPositive ? Icons.trending_up_rounded : Icons.warning_amber_rounded,
                    size: 16,
                    color: trendPositive ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trendLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trendPositive ? Colors.green.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFCFEFB)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedSection == _AdminSection.users
          ? _buildUsersTable()
          : _selectedSection == _AdminSection.stores
              ? _buildStoresTable()
              : _selectedSection == _AdminSection.products
                  ? _buildProductsTable()
                  : _selectedSection == _AdminSection.orders
                      ? _buildOrdersTable()
                      : _selectedSection == _AdminSection.reports
                          ? _buildReportedCasesPanel()
                          : _buildDashboardOverviewPanel(),
    );
  }

  Widget _buildDashboardOverviewPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kPrimary, kSecondaryAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kSecondaryAccent.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Daily command center: review activity, approve stores and product listings, and manage user operations.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kCardText)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildQuickActionButton(Icons.people_alt_rounded, 'Review Users', _AdminSection.users),
                    _buildQuickActionButton(Icons.storefront_rounded, 'Review Stores', _AdminSection.stores),
                    _buildQuickActionButton(Icons.inventory_2_rounded, 'Review Products', _AdminSection.products),
                    _buildQuickActionButton(Icons.receipt_long_rounded, 'Monitor Orders', _AdminSection.orders),
                    _buildQuickActionButton(Icons.flag_rounded, 'Reported Cases', _AdminSection.reports),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        side: BorderSide(color: Colors.green.shade200),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _seedDemoProducts,
                      icon: const Icon(Icons.auto_awesome_rounded, color: kPrimary),
                      label: const Text('Seed Demo Products', style: TextStyle(color: kCardText)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        side: BorderSide(color: Colors.red.shade200),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _clearDemoProducts,
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                      label: const Text('Clear Demo Products', style: TextStyle(color: kCardText)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text('Operational Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kCardText)),
                const SizedBox(height: 16),
                _buildInfoTile(
                  title: 'Peak demand expected at lunch hour',
                  subtitle: 'Prepare store moderation coverage between 12:00 PM - 2:00 PM.',
                  icon: Icons.schedule_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                _buildInfoTile(
                  title: 'Pending store approvals require review',
                  subtitle: 'Prioritize verification requests to shorten seller onboarding time.',
                  icon: Icons.assignment_late_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: 10),
                _buildInfoTile(
                  title: 'No major incidents reported',
                  subtitle: 'System operations are stable over the past 24 hours.',
                  icon: Icons.verified_rounded,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, _AdminSection section) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.green.shade200),
        ),
      ),
      onPressed: () => setState(() {
        _selectedSection = section;
        if (!_statusOptionsForCurrentSection().contains(_statusFilter)) {
          _statusFilter = 'All';
        }
        _resetPagination();
      }),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF3F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSecondaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: kSecondaryAccent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kCardText)),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').limit(24).snapshots(),
              builder: (context, orderSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('stores').limit(250).snapshots(),
                  builder: (context, storeSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('status', isEqualTo: 'Pending')
                          .limit(30)
                          .snapshots(),
                      builder: (context, productSnap) {
                        final allWaiting = orderSnap.connectionState == ConnectionState.waiting &&
                            storeSnap.connectionState == ConnectionState.waiting &&
                            productSnap.connectionState == ConnectionState.waiting &&
                            !orderSnap.hasData &&
                            !storeSnap.hasData &&
                            !productSnap.hasData;

                        if (allWaiting) {
                          return const Center(child: CircularProgressIndicator(color: kPrimary));
                        }

                        final items = _compileAdminActivityFeed(
                          orders: orderSnap.data,
                          stores: storeSnap.data,
                          pendingProducts: productSnap.data,
                        );

                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No recent activities yet.', style: TextStyle(color: Colors.grey)),
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: BoxDecoration(color: item.dotColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.text,
                                    style: const TextStyle(fontSize: 13.5, height: 1.35, color: kCardText),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _activityTimestamp(Map<String, dynamic> data, [List<String> keys = const ['createdAt', 'timestamp', 'orderDate', 'approvedAt']]) {
    for (final k in keys) {
      final v = data[k];
      if (v is Timestamp) return v.toDate();
    }
    return null;
  }

  List<_ActivityFeedItem> _compileAdminActivityFeed({
    QuerySnapshot? orders,
    QuerySnapshot? stores,
    QuerySnapshot? pendingProducts,
  }) {
    final out = <_ActivityFeedItem>[];
    final approvedSellerIds = <String>{};

    if (stores != null) {
      for (final d in stores.docs) {
        final data = d.data() as Map<String, dynamic>;
        final st = (data['status'] ?? '').toString();
        if (st == 'Approved') {
          approvedSellerIds.add(d.id);
          final oid = data['ownerId']?.toString();
          if (oid != null && oid.isNotEmpty) approvedSellerIds.add(oid);
        }
      }

      for (final d in stores.docs) {
        final data = d.data() as Map<String, dynamic>;
        final st = (data['status'] ?? '').toString();
        final name = (data['storeName'] ?? 'Store').toString();
        final owner = (data['ownerName'] ?? 'Seller').toString();

        if (st == 'Pending') {
          out.add(
            _ActivityFeedItem(
              when: _activityTimestamp(data),
              dotColor: Colors.deepOrange,
              text: 'New seller application: "$name" ($owner) — awaiting your approval.',
            ),
          );
        } else if (st == 'Approved') {
          final approvedAt = data['approvedAt'];
          if (approvedAt is Timestamp) {
            out.add(
              _ActivityFeedItem(
                when: approvedAt.toDate(),
                dotColor: Colors.green,
                text: 'Store "$name" is approved — seller can add products.',
              ),
            );
          }
        }
      }
    }

    if (pendingProducts != null) {
      for (final d in pendingProducts.docs) {
        final data = d.data() as Map<String, dynamic>;
        final name = (data['name'] ?? 'Product').toString();
        final sellerName = (data['sellerName'] ?? 'Seller').toString();
        final sellerId = (data['sellerId'] ?? '').toString();
        final sellerApproved = sellerId.isNotEmpty && approvedSellerIds.contains(sellerId);

        out.add(
          _ActivityFeedItem(
            when: _activityTimestamp(data),
            dotColor: sellerApproved ? const Color(0xFF6B4FB7) : Colors.amber.shade800,
            text: sellerApproved
                ? 'Approved seller "$sellerName" submitted product "$name" for review.'
                : 'Product "$name" from "$sellerName" is pending review (approve the store first if needed).',
          ),
        );
      }
    }

    if (orders != null && orders.docs.isNotEmpty) {
      final docs = List<QueryDocumentSnapshot>.from(orders.docs);
      docs.sort((a, b) {
        final ta = _activityTimestamp(a.data() as Map<String, dynamic>) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = _activityTimestamp(b.data() as Map<String, dynamic>) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      for (final d in docs.take(8)) {
        final data = d.data() as Map<String, dynamic>;
        final status = (data['status'] ?? 'Pending').toString();
        final buyerName = (data['buyerName'] ?? 'Unknown Buyer').toString();
        out.add(
          _ActivityFeedItem(
            when: _activityTimestamp(data),
            dotColor: _statusColor(status),
            text: 'Order from $buyerName is $status.',
          ),
        );
      }
    }

    out.sort((a, b) {
      final ta = a.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    return out.take(14).toList();
  }

  Widget _buildPaginationControls({
    required int currentPage,
    required int totalItems,
    required void Function(int) onPageChanged,
  }) {
    final totalPages = (totalItems / _pageSize).ceil().clamp(1, 9999);
    final canGoBack = currentPage > 0;
    final canGoNext = currentPage < totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Text(
            'Showing ${totalItems == 0 ? 0 : (currentPage * _pageSize) + 1} - '
            '${((currentPage + 1) * _pageSize).clamp(0, totalItems)} of $totalItems',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Page ${currentPage + 1} / $totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            onPressed: canGoNext ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _sliceForPage(List<QueryDocumentSnapshot> docs, int page) {
    final start = page * _pageSize;
    if (start >= docs.length) return <QueryDocumentSnapshot>[];
    final end = (start + _pageSize).clamp(0, docs.length);
    return docs.sublist(start, end);
  }

  Future<void> _exportCurrentSectionAsCsv() async {
    if (_selectedSection == _AdminSection.dashboard) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switch to Users, Stores, Products, Orders, or Reports to export CSV.')),
      );
      return;
    }

    try {
      late final List<QueryDocumentSnapshot> docs;
      if (_selectedSection == _AdminSection.users) {
        docs = (await FirebaseFirestore.instance.collection('users').get()).docs;
      } else if (_selectedSection == _AdminSection.stores) {
        docs = (await FirebaseFirestore.instance.collection('stores').get()).docs;
      } else if (_selectedSection == _AdminSection.products) {
        docs = (await FirebaseFirestore.instance.collection('products').get()).docs;
      } else if (_selectedSection == _AdminSection.reports) {
        docs = (await FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'pending')
            .get()).docs;
      } else {
        docs = (await FirebaseFirestore.instance.collection('orders').get()).docs;
      }

      final csv = _buildCsvFromDocs(docs);
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copied to clipboard. You can paste into Excel/Sheets.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    }
  }

  String _buildCsvFromDocs(List<QueryDocumentSnapshot> docs) {
    List<String> headers;
    if (_selectedSection == _AdminSection.users) {
      headers = ['id', 'name', 'email', 'role'];
    } else if (_selectedSection == _AdminSection.stores) {
      headers = ['id', 'storeName', 'ownerId', 'status'];
    } else if (_selectedSection == _AdminSection.products) {
      headers = ['id', 'name', 'sellerId', 'sellerName', 'category', 'status'];
    } else if (_selectedSection == _AdminSection.reports) {
      headers = ['id', 'reason', 'productId', 'reportedSellerId', 'reporterId', 'status'];
    } else {
      headers = ['id', 'buyerName', 'productName', 'totalPrice', 'status'];
    }

    final rows = <String>[
      headers.join(','),
      ...docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return headers.map((header) {
          dynamic raw;
          if (header == 'id') {
            raw = doc.id;
          } else if (header == 'status' && _selectedSection == _AdminSection.products) {
            raw = productStatusLabel(data);
          } else {
            raw = data[header] ?? '';
          }
          final value = raw.toString().replaceAll('"', '""');
          return '"$value"';
        }).join(',');
      }),
    ];
    return rows.join('\n');
  }

  Future<void> _seedDemoProducts() async {
    final shouldSeed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seed demo products?'),
          content: const Text(
            'This will add 100 demo products with realistic names, prices, and dates. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Seed'),
            ),
          ],
        );
      },
    );

    if (shouldSeed != true) return;

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null || currentUid.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to seed demo products.')),
        );
        return;
      }

      String sellerName = 'UMART Demo Store';
      final ownStore = await FirebaseFirestore.instance
          .collection('stores')
          .where('ownerId', isEqualTo: currentUid)
          .limit(1)
          .get();
      if (ownStore.docs.isNotEmpty) {
        final data = ownStore.docs.first.data();
        sellerName = (data['storeName'] ?? sellerName).toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeding demo products... please wait.')),
        );
      }

      final now = DateTime.now();
      final categories = <String>[
        'Food & Beverages',
        'Preloved Items',
        'Books & Notes',
        'Gadgets & Accessories',
        'Others',
      ];

      final productsByCategory = <String, List<String>>{
        'Food & Beverages': ['Choco Jar', 'Iced Coffee', 'Spicy Macaroni', 'Pasta Bowl', 'Fruit Sandwich'],
        'Preloved Items': ['Hoodie Bundle', 'Campus Backpack', 'Desk Lamp', 'Sports Shoes', 'Water Flask'],
        'Books & Notes': ['Math Notes Set', 'Final Exam Spot', 'Reference Book', 'Printed Slides', 'Lab Report Template'],
        'Gadgets & Accessories': ['Type-C Cable', 'Wireless Mouse', 'Phone Holder', 'Laptop Stand', 'Earbuds Case'],
        'Others': ['Study Planner', 'Mini Whiteboard', 'Sticky Notes Pack', 'Pen Bundle', 'Gift Set'],
      };

      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('products');

      for (int i = 0; i < 100; i++) {
        final category = categories[_random.nextInt(categories.length)];
        final pool = productsByCategory[category] ?? const ['Campus Item'];
        final baseName = pool[_random.nextInt(pool.length)];
        final createdAt = now.subtract(
          Duration(
            days: _random.nextInt(90),
            hours: _random.nextInt(24),
            minutes: _random.nextInt(60),
          ),
        );
        final price = 2.5 + (_random.nextInt(600) / 10.0);
        final deliveryFee = _random.nextBool() ? 0.0 : (1 + _random.nextInt(4)).toDouble();
        final stock = 4 + _random.nextInt(60);
        final imageSeed = 'umart_${category.replaceAll(' ', '_')}_$i';
        final imageUrls = <String>[
          'https://picsum.photos/seed/${imageSeed}a/720/720',
          'https://picsum.photos/seed/${imageSeed}b/720/720',
        ];

        final docRef = collection.doc();
        batch.set(docRef, {
          'name': '$baseName ${100 + i}',
          'price': double.parse(price.toStringAsFixed(2)),
          'deliveryFee': deliveryFee,
          'stock': stock,
          'description': 'Popular among UMART users. Fresh listing for campus community.',
          'category': category,
          'variations': <String>[],
          'variationPrices': <String, double>{},
          'sellerName': sellerName,
          'sellerId': currentUid,
          'imageUrl': imageUrls.first,
          'imageUrls': imageUrls,
          'createdAt': Timestamp.fromDate(createdAt),
          'isDemo': true,
          'status': 'Approved',
        });
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo seeding completed: 100 products added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo seeding failed: $e')),
      );
    }
  }

  Future<void> _clearDemoProducts() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear demo products?'),
          content: const Text('This only deletes products where isDemo = true.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    try {
      int totalDeleted = 0;

      while (true) {
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('isDemo', isEqualTo: true)
            .limit(250)
            .get();

        if (snapshot.docs.isEmpty) break;

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        totalDeleted += snapshot.docs.length;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo cleanup completed: $totalDeleted products deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo cleanup failed: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // --- WIDGET HELPER: Users List Table (Manage Users) ---
  Widget _buildUsersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No registered users yet.', style: TextStyle(color: Colors.grey)));
        }

        var users = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final userData = doc.data() as Map<String, dynamic>;
          final content = [
            userData['name'],
            userData['username'],
            userData['fullName'],
            userData['displayName'],
            userData['email'],
            userData['role'],
          ].join(' ').toLowerCase();
          return content.contains(_searchQuery);
        }).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _matchesDateFilter(data);
        }).toList();

        users.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          String left;
          String right;
          switch (_userSortBy) {
            case 'email':
              left = (dataA['email'] ?? '').toString().toLowerCase();
              right = (dataB['email'] ?? '').toString().toLowerCase();
              break;
            case 'role':
              left = (dataA['role'] ?? '').toString().toLowerCase();
              right = (dataB['role'] ?? '').toString().toLowerCase();
              break;
            default:
              left = (dataA['name'] ?? dataA['username'] ?? dataA['fullName'] ?? '').toString().toLowerCase();
              right = (dataB['name'] ?? dataB['username'] ?? dataB['fullName'] ?? '').toString().toLowerCase();
          }
          return _userSortAsc ? left.compareTo(right) : right.compareTo(left);
        });

        if (users.isEmpty) {
          return const Center(
            child: Text('No users match your search.', style: TextStyle(color: Colors.grey)),
          );
        }

        final maxPage = ((users.length - 1) / _pageSize).floor();
        if (_userPage > maxPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _userPage = 0);
          });
        }
        final pagedUsers = _sliceForPage(users, _userPage);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kBg),
                    headingRowHeight: 60,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columnSpacing: 38,
                    horizontalMargin: 22,
                    sortColumnIndex: _userSortBy == 'name' ? 1 : _userSortBy == 'email' ? 2 : 3,
                    sortAscending: _userSortAsc,
                    columns: [
                      const DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_userSortBy == 'name') _userSortAsc = !_userSortAsc;
                          _userSortBy = 'name';
                        }),
                      ),
                      DataColumn(
                        label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_userSortBy == 'email') _userSortAsc = !_userSortAsc;
                          _userSortBy = 'email';
                        }),
                      ),
                      DataColumn(
                        label: const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_userSortBy == 'role') _userSortAsc = !_userSortAsc;
                          _userSortBy = 'role';
                        }),
                      ),
                      const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(pagedUsers.length, (index) {
                      var userData = pagedUsers[index].data() as Map<String, dynamic>;
                      String docId = pagedUsers[index].id;
                      final displayIndex = (_userPage * _pageSize) + index + 1;
                
                      String name = userData['name'] ?? userData['username'] ?? userData['fullName'] ?? userData['displayName'] ?? 'No Name';
                      String email = userData['email'] ?? 'No Email';
                      String role = userData['role'] ?? 'Student';

                      return DataRow(
                        cells: [
                          DataCell(Text('$displayIndex')),
                          DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(email)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: role.toLowerCase() == 'seller' ? Colors.orange.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: role.toLowerCase() == 'seller' ? Colors.orange.shade700 : Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              onPressed: () => _deleteUser(docId, name),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            _buildPaginationControls(
              currentPage: _userPage,
              totalItems: users.length,
              onPageChanged: (nextPage) => setState(() => _userPage = nextPage),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET HELPER: Fungsi Delete User ---
  Future<void> _deleteUser(String docId, String userName) async {
    // Tunjuk kotak pengesahan (Confirmation Dialog)
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "$userName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false; // Kalau user tekan luar kotak, anggap false (cancel)

    // Kalau admin tekan 'Delete', baru kita tembak Firebase
    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userName has been deleted.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --- WIDGET HELPER: Update Store Status Function ---
  Future<void> _updateStoreStatus(String docId, String storeName, String newStatus) async {
    try {
      final storeRef = FirebaseFirestore.instance.collection('stores').doc(docId);
      final storeSnap = await storeRef.get();
      final storeData = storeSnap.data() ?? <String, dynamic>{};
      final ownerId = (storeData['ownerId'] ?? docId).toString();

      final update = <String, dynamic>{'status': newStatus};
      if (newStatus == 'Approved') {
        update['approvedAt'] = FieldValue.serverTimestamp();
      }
      await storeRef.update(update);

      final notif = FirebaseFirestore.instance.collection('users').doc(ownerId).collection('notifications');
      if (newStatus == 'Approved') {
        await notif.add({
          'title': 'Seller application approved',
          'body': 'Your store "$storeName" is approved. Open the app and tap Sell to manage your shop.',
          'type': 'seller_approved',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (newStatus == 'Rejected') {
        await notif.add({
          'title': 'Seller application update',
          'body': 'Your store "$storeName" was not approved. You can update your details and contact support if you need help.',
          'type': 'seller_rejected',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store "$storeName" marked as $newStatus.'),
            backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProductStatus(String docId, String productName, String sellerId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(docId).update({
        'status': newStatus,
      });

      final sid = sellerId.trim();
      if (sid.isNotEmpty) {
        final notif = FirebaseFirestore.instance.collection('users').doc(sid).collection('notifications');
        if (newStatus == 'Approved') {
          await notif.add({
            'title': 'Product approved',
            'body': 'Your product "$productName" is now visible to buyers in the marketplace.',
            'type': 'product_approved',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else if (newStatus == 'Rejected') {
          await notif.add({
            'title': 'Product not approved',
            'body': 'Your product "$productName" was not approved. Edit it from your seller dashboard and resubmit.',
            'type': 'product_rejected',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$productName" marked as $newStatus.'),
            backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resolveReport(String reportId, {required String resolution}) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'status': 'resolved',
      'resolution': resolution,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _banSellerFromReport(
    String reportId,
    String sellerId, {
    String? productId,
    String? productName,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ban seller?'),
        content: const Text(
          'This will set the seller account status to banned. They will not be able to use the app until an admin reverses it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ban seller', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(sellerId).set(
        {
          'status': 'banned',
          'bannedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await FirebaseFirestore.instance.collection('users').doc(sellerId).collection('notifications').add({
        'title': 'Account suspended',
        'body': 'Your account has been suspended following a community report. Contact support if you believe this is a mistake.',
        'type': 'account_banned',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _resolveReport(reportId, resolution: 'seller_banned');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller has been banned.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error banning seller: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takeDownProductFromReport(
    String reportId,
    String productId,
    String sellerId, {
    String? productName,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Take down product?'),
        content: const Text(
          'This will mark the product as Rejected and hide it from buyers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Take down', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final name = productName ?? 'Product';
      await _updateProductStatus(productId, name, sellerId, 'Rejected');
      await _resolveReport(reportId, resolution: 'product_rejected');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking down product: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dismissReport(String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dismiss report?'),
        content: const Text('No action will be taken against the seller or product.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dismiss')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _resolveReport(reportId, resolution: 'dismissed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report dismissed with no action taken.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dismissing report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatReportTimestamp(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  Widget _buildReportedCasesPanel() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load reports: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        var reports = snapshot.data?.docs ?? [];
        reports = reports.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final blob = [
            data['reason'],
            data['description'],
            data['productId'],
            data['productName'],
            data['reportedSellerId'],
            data['reporterId'],
          ].join(' ').toLowerCase();
          return blob.contains(_searchQuery);
        }).toList();

        reports.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'];
          final bTime = bData['createdAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No pending reports.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        final maxPage = ((reports.length - 1) / _pageSize).floor();
        if (_reportPage > maxPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _reportPage = 0);
          });
        }
        final paged = _sliceForPage(reports, _reportPage);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: kPrimary),
                  const SizedBox(width: 10),
                  Text(
                    'Reported Cases (${reports.length} pending)',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kCardText),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                itemCount: paged.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final doc = paged[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final reportId = doc.id;
                  final reason = (data['reason'] ?? '—').toString();
                  final description = (data['description'] ?? '').toString();
                  final productId = (data['productId'] ?? '').toString();
                  final productName = (data['productName'] ?? '').toString();
                  final sellerId = (data['reportedSellerId'] ?? '').toString();
                  final reporterId = (data['reporterId'] ?? '').toString();
                  final createdLabel = _formatReportTimestamp(data['createdAt']);

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                reason.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(createdLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (productName.isNotEmpty)
                          Text(
                            productName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kCardText),
                          ),
                        const SizedBox(height: 6),
                        Text(description, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
                        const SizedBox(height: 12),
                        _buildReportMetaRow('Product ID', productId),
                        _buildReportMetaRow('Seller ID', sellerId),
                        _buildReportMetaRow('Reporter ID', reporterId),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade200),
                              ),
                              onPressed: sellerId.isEmpty
                                  ? null
                                  : () => _banSellerFromReport(
                                        reportId,
                                        sellerId,
                                        productId: productId.isEmpty ? null : productId,
                                        productName: productName.isEmpty ? null : productName,
                                      ),
                              icon: const Icon(Icons.block_rounded, size: 18),
                              label: const Text('Ban Seller'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade800,
                                side: BorderSide(color: Colors.orange.shade200),
                              ),
                              onPressed: productId.isEmpty
                                  ? null
                                  : () => _takeDownProductFromReport(
                                        reportId,
                                        productId,
                                        sellerId,
                                        productName: productName.isEmpty ? null : productName,
                                      ),
                              icon: const Icon(Icons.visibility_off_outlined, size: 18),
                              label: const Text('Take Down Product'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _dismissReport(reportId),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Dismiss / Resolve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildPaginationControls(
              currentPage: _reportPage,
              totalItems: reports.length,
              onPageChanged: (nextPage) => setState(() => _reportPage = nextPage),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 12, color: kCardText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStore(String docId, String storeName, String? ownerId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete store', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Permanently delete "$storeName"? This cannot be undone. Products linked to this store may break if your app expects the document to exist.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmDelete) return;

    try {
      await FirebaseFirestore.instance.collection('stores').doc(docId).delete();

      final oid = ownerId?.trim();
      if (oid != null && oid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(oid).collection('notifications').add({
          'title': 'Store removed',
          'body': 'Your store "$storeName" was removed by an administrator.',
          'type': 'store_removed',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store "$storeName" has been deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- WIDGET HELPER: Stores List Table (Manage Stores) ---
  Widget _buildStoresTable() {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the 'stores' collection
      stream: FirebaseFirestore.instance.collection('stores').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No store applications yet.', style: TextStyle(color: Colors.grey)));
        }

        var stores = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final storeData = doc.data() as Map<String, dynamic>;
          final content = [
            storeData['storeName'],
            storeData['ownerName'],
            storeData['sellerName'],
            storeData['status'],
          ].join(' ').toLowerCase();
          return content.contains(_searchQuery);
        }).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'Pending').toString();
          if (_statusFilter != 'All' && status != _statusFilter) return false;
          return _matchesDateFilter(data);
        }).toList();

        stores.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          String left;
          String right;
          switch (_storeSortBy) {
            case 'status':
              left = (dataA['status'] ?? '').toString().toLowerCase();
              right = (dataB['status'] ?? '').toString().toLowerCase();
              break;
            default:
              left = (dataA['storeName'] ?? '').toString().toLowerCase();
              right = (dataB['storeName'] ?? '').toString().toLowerCase();
          }
          return _storeSortAsc ? left.compareTo(right) : right.compareTo(left);
        });

        if (stores.isEmpty) {
          return const Center(
            child: Text('No stores match your search.', style: TextStyle(color: Colors.grey)),
          );
        }

        final maxPage = ((stores.length - 1) / _pageSize).floor();
        if (_storePage > maxPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _storePage = 0);
          });
        }
        final pagedStores = _sliceForPage(stores, _storePage);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kBg),
                    headingRowHeight: 60,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columnSpacing: 38,
                    horizontalMargin: 22,
                    sortColumnIndex: _storeSortBy == 'store' ? 1 : 3,
                    sortAscending: _storeSortAsc,
                    columns: [
                      const DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: const Text('Store Name', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_storeSortBy == 'store') _storeSortAsc = !_storeSortAsc;
                          _storeSortBy = 'store';
                        }),
                      ),
                      const DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_storeSortBy == 'status') _storeSortAsc = !_storeSortAsc;
                          _storeSortBy = 'status';
                        }),
                      ),
                      const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(pagedStores.length, (index) {
                      var storeData = pagedStores[index].data() as Map<String, dynamic>;
                      String docId = pagedStores[index].id;
                      final displayIndex = (_storePage * _pageSize) + index + 1;
                
                      String storeName = storeData['storeName'] ?? 'Unnamed Store';
                      String status = storeData['status'] ?? 'Pending'; 

                      return DataRow(
                        cells: [
                          DataCell(Text('$displayIndex')),
                          DataCell(Text(storeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    
                          DataCell(
                            storeData['ownerId'] != null 
                              ? FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(storeData['ownerId']).get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Text('Loading...', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic));
                                    }
                                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                      var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                      String realName = userData['name'] ?? userData['username'] ?? userData['fullName'] ?? 'No Name';
                                      return Text(realName);
                                    }
                                    return const Text('User Deleted', style: TextStyle(color: Colors.red, fontSize: 12));
                                  },
                                )
                              : const Text('No ID', style: TextStyle(color: Colors.grey)),
                          ),

                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'Approved' ? Colors.green.shade50 
                                     : status == 'Rejected' ? Colors.red.shade50 
                                     : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(), 
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Approved' ? Colors.green.shade700 
                                       : status == 'Rejected' ? Colors.red.shade700 
                                       : Colors.orange.shade700
                                )
                              ),
                            )
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (status == 'Pending') ...[
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                                    tooltip: 'Approve Store',
                                    onPressed: () => _updateStoreStatus(docId, storeName, 'Approved'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                    tooltip: 'Reject Store',
                                    onPressed: () => _updateStoreStatus(docId, storeName, 'Rejected'),
                                  ),
                                ] else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      status == 'Approved' ? 'Done' : 'Closed',
                                      style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  tooltip: 'Delete store',
                                  onPressed: () => _deleteStore(
                                    docId,
                                    storeName,
                                    storeData['ownerId']?.toString(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      );
                    }),
                  ),
                ),
              ),
            ),
            _buildPaginationControls(
              currentPage: _storePage,
              totalItems: stores.length,
              onPageChanged: (nextPage) => setState(() => _storePage = nextPage),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET HELPER: Products (moderation) ---
  Widget _buildProductsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products yet.', style: TextStyle(color: Colors.grey)));
        }

        var products = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final productData = doc.data() as Map<String, dynamic>;
          final content = [
            productData['name'],
            productData['sellerName'],
            productData['sellerId'],
            productData['category'],
            productStatusLabel(productData),
          ].join(' ').toLowerCase();
          return content.contains(_searchQuery);
        }).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = productStatusLabel(data);
          if (_statusFilter != 'All' && status != _statusFilter) return false;
          return _matchesDateFilter(data);
        }).toList();

        products.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          String left;
          String right;
          switch (_productSortBy) {
            case 'status':
              left = productStatusLabel(dataA).toLowerCase();
              right = productStatusLabel(dataB).toLowerCase();
              break;
            default:
              left = (dataA['name'] ?? '').toString().toLowerCase();
              right = (dataB['name'] ?? '').toString().toLowerCase();
          }
          return _productSortAsc ? left.compareTo(right) : right.compareTo(left);
        });

        if (products.isEmpty) {
          return const Center(
            child: Text('No products match your search.', style: TextStyle(color: Colors.grey)),
          );
        }

        final maxPage = ((products.length - 1) / _pageSize).floor();
        if (_productPage > maxPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _productPage = 0);
          });
        }
        final paged = _sliceForPage(products, _productPage);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kBg),
                    headingRowHeight: 60,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columnSpacing: 28,
                    horizontalMargin: 22,
                    sortColumnIndex: _productSortBy == 'name' ? 1 : 4,
                    sortAscending: _productSortAsc,
                    columns: [
                      const DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: const Text('Product', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_productSortBy == 'name') _productSortAsc = !_productSortAsc;
                          _productSortBy = 'name';
                        }),
                      ),
                      const DataColumn(label: Text('Seller', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_productSortBy == 'status') _productSortAsc = !_productSortAsc;
                          _productSortBy = 'status';
                        }),
                      ),
                      const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(paged.length, (index) {
                      final productData = paged[index].data() as Map<String, dynamic>;
                      final docId = paged[index].id;
                      final displayIndex = (_productPage * _pageSize) + index + 1;
                      final name = productData['name'] ?? 'Unnamed';
                      final sellerName = (productData['sellerName'] ?? '').toString();
                      final sellerId = (productData['sellerId'] ?? productData['ownerId'] ?? '').toString();
                      final category = (productData['category'] ?? '').toString();
                      final status = productStatusLabel(productData);

                      return DataRow(
                        cells: [
                          DataCell(Text('$displayIndex')),
                          DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sellerName.isNotEmpty ? sellerName : '—',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                if (sellerId.isNotEmpty)
                                  Text(
                                    sellerId,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(Text(category.isNotEmpty ? category : '—')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'Approved'
                                    ? Colors.green.shade50
                                    : status == 'Rejected'
                                        ? Colors.red.shade50
                                        : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Approved'
                                      ? Colors.green.shade700
                                      : status == 'Rejected'
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            status == 'Pending'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                                        tooltip: 'Approve product',
                                        onPressed: () => _updateProductStatus(docId, name.toString(), sellerId, 'Approved'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                        tooltip: 'Reject product',
                                        onPressed: () => _updateProductStatus(docId, name.toString(), sellerId, 'Rejected'),
                                      ),
                                    ],
                                  )
                                : Text(
                                    status == 'Approved' ? 'Live' : 'Closed',
                                    style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                                  ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            _buildPaginationControls(
              currentPage: _productPage,
              totalItems: products.length,
              onPageChanged: (nextPage) => setState(() => _productPage = nextPage),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET HELPER: All Orders List Table ---
  Widget _buildOrdersTable() {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the 'orders' collection
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No transaction history yet.', style: TextStyle(color: Colors.grey)));
        }

        var orders = snapshot.data!.docs.where((doc) {
          if (_searchQuery.isEmpty) return true;
          final orderData = doc.data() as Map<String, dynamic>;
          final content = [
            orderData['buyerName'],
            orderData['productName'],
            orderData['status'],
            doc.id,
          ].join(' ').toLowerCase();
          return content.contains(_searchQuery);
        }).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'Pending').toString();
          if (_statusFilter != 'All' && status != _statusFilter) return false;
          return _matchesDateFilter(data);
        }).toList();

        orders.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          int compare;
          switch (_orderSortBy) {
            case 'buyer':
              compare = (dataA['buyerName'] ?? '').toString().toLowerCase().compareTo(
                    (dataB['buyerName'] ?? '').toString().toLowerCase(),
                  );
              break;
            case 'total':
              compare = ((dataA['totalPrice'] ?? 0) as num).toDouble().compareTo(
                ((dataB['totalPrice'] ?? 0) as num).toDouble(),
              );
              break;
            case 'status':
              compare = (dataA['status'] ?? '').toString().toLowerCase().compareTo(
                    (dataB['status'] ?? '').toString().toLowerCase(),
                  );
              break;
            default:
              compare = a.id.toLowerCase().compareTo(b.id.toLowerCase());
          }
          return _orderSortAsc ? compare : -compare;
        });

        if (orders.isEmpty) {
          return const Center(
            child: Text('No orders match your search.', style: TextStyle(color: Colors.grey)),
          );
        }

        final maxPage = ((orders.length - 1) / _pageSize).floor();
        if (_orderPage > maxPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _orderPage = 0);
          });
        }
        final pagedOrders = _sliceForPage(orders, _orderPage);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(kBg),
                    headingRowHeight: 60,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 58,
                    columnSpacing: 32,
                    horizontalMargin: 22,
                    sortColumnIndex: _orderSortBy == 'id'
                        ? 1
                        : _orderSortBy == 'buyer'
                            ? 2
                            : _orderSortBy == 'total'
                                ? 4
                                : 5,
                    sortAscending: _orderSortAsc,
                    columns: [
                      const DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        label: const Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_orderSortBy == 'id') _orderSortAsc = !_orderSortAsc;
                          _orderSortBy = 'id';
                        }),
                      ),
                      DataColumn(
                        label: const Text('Buyer', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_orderSortBy == 'buyer') _orderSortAsc = !_orderSortAsc;
                          _orderSortBy = 'buyer';
                        }),
                      ),
                      const DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                        numeric: true,
                        label: const Text('Total (RM)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_orderSortBy == 'total') _orderSortAsc = !_orderSortAsc;
                          _orderSortBy = 'total';
                        }),
                      ),
                      DataColumn(
                        label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (_, __) => setState(() {
                          if (_orderSortBy == 'status') _orderSortAsc = !_orderSortAsc;
                          _orderSortBy = 'status';
                        }),
                      ),
                    ],
                    rows: List.generate(pagedOrders.length, (index) {
                      var orderData = pagedOrders[index].data() as Map<String, dynamic>;
                      String docId = pagedOrders[index].id;
                      final displayIndex = (_orderPage * _pageSize) + index + 1;
                
                      String shortId = docId.length >= 5 ? docId.substring(0, 5) : docId;
                      String displayId = '#UM-${shortId.toUpperCase()}';
                
                      String buyerName = orderData['buyerName'] ?? 'Unknown Buyer';
                      String itemName = orderData['productName'] ?? 'Item';
                      String status = orderData['status'] ?? 'Pending';
                
                      double total = 0.0;
                      if (orderData['totalPrice'] != null) {
                        total = (orderData['totalPrice'] as num).toDouble();
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text('$displayIndex')),
                          DataCell(Text(displayId, style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary))),
                          DataCell(Text(buyerName)),
                          DataCell(Text('1x $itemName', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'Delivered' ? Colors.green.shade50 
                                     : status == 'Rejected' ? Colors.red.shade50 
                                     : status == 'Processing' ? Colors.blue.shade50
                                     : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(), 
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: status == 'Delivered' ? Colors.green.shade700 
                                       : status == 'Rejected' ? Colors.red.shade700 
                                       : status == 'Processing' ? Colors.blue.shade700
                                       : Colors.orange.shade700
                                )
                              ),
                            )
                          ),
                        ]
                      );
                    }),
                  ),
                ),
              ),
            ),
            _buildPaginationControls(
              currentPage: _orderPage,
              totalItems: orders.length,
              onPageChanged: (nextPage) => setState(() => _orderPage = nextPage),
            ),
          ],
        );
      },
    );
  }
}