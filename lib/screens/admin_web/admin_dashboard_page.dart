import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../auth/login_page.dart';
// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kBg = Color(0xFFF5F7F2); 
const kCardText = Color(0xFF1A1A2E);
const kAccent = Color(0xFF8AAF63);
const kSecondaryAccent = Color(0xFF6D8BEA);

enum _AdminSection { dashboard, users, stores, orders }

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
  int _orderPage = 0;
  static const int _pageSize = 10;

  String _userSortBy = 'name';
  String _storeSortBy = 'store';
  String _orderSortBy = 'id';
  bool _userSortAsc = true;
  bool _storeSortAsc = true;
  bool _orderSortAsc = true;
  final Random _random = Random();

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
                _buildNavItem(Icons.storefront_rounded, 'Manage Stores', _AdminSection.stores),
                _buildNavItem(Icons.receipt_long_rounded, 'All Orders', _AdminSection.orders),
                
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
                hintText: 'Search users, stores or orders...',
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
    if (_selectedSection == _AdminSection.orders) {
      return const ['All', 'Pending', 'Processing', 'Delivered', 'Rejected'];
    }
    return const ['All'];
  }

  void _resetPagination() {
    _userPage = 0;
    _storePage = 0;
    _orderPage = 0;
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

  Widget _buildNavItem(IconData icon, String title, _AdminSection section) {
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
        title: Text(title, style: TextStyle(
          color: isSelected ? kPrimary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        )),
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
              : _selectedSection == _AdminSection.orders
                  ? _buildOrdersTable()
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
                          'Daily command center: review activity, approve stores, and manage user operations.',
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
                    _buildQuickActionButton(Icons.receipt_long_rounded, 'Monitor Orders', _AdminSection.orders),
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
              stream: FirebaseFirestore.instance.collection('orders').limit(8).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No recent activities yet.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final status = (data['status'] ?? 'Pending').toString();
                    final buyerName = (data['buyerName'] ?? 'Unknown Buyer').toString();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Order from $buyerName is currently $status.',
                            style: const TextStyle(fontSize: 13.5, height: 1.35, color: kCardText),
                          ),
                        ),
                      ],
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
        const SnackBar(content: Text('Switch to Users, Stores or Orders to export CSV.')),
      );
      return;
    }

    try {
      late final List<QueryDocumentSnapshot> docs;
      if (_selectedSection == _AdminSection.users) {
        docs = (await FirebaseFirestore.instance.collection('users').get()).docs;
      } else if (_selectedSection == _AdminSection.stores) {
        docs = (await FirebaseFirestore.instance.collection('stores').get()).docs;
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
    } else {
      headers = ['id', 'buyerName', 'productName', 'totalPrice', 'status'];
    }

    final rows = <String>[
      headers.join(','),
      ...docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return headers.map((header) {
          final raw = header == 'id' ? doc.id : (data[header] ?? '');
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

      await storeRef.update({
        'status': newStatus,
      });

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