import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kBg = Color(0xFFF5F7F2); 

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Row(
        children: [
          // ─── 1. SIDEBAR MENU (LEFT) ───
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text('UMART ADMIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kPrimary)),
                const SizedBox(height: 40),
                
                _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _buildNavItem(Icons.people_alt_rounded, 'Manage Users', 1),
                _buildNavItem(Icons.storefront_rounded, 'Manage Stores', 2),
                _buildNavItem(Icons.receipt_long_rounded, 'All Orders', 3),
                
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    // TODO: Add Firebase sign out function here
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
                  const Text('Dashboard Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
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
                          return _buildStatCard('Total Users', userCount, Icons.people_outline_rounded, Colors.blue);
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
                          return _buildStatCard('Active Orders', activeOrders, Icons.shopping_bag_outlined, Colors.orange);
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
                          return _buildStatCard('Total Revenue', 'RM ${totalRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined, kPrimary);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // ─── MAIN CONTENT AREA (DATA TABLE) ───
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      // Logic: Show table only if menu 1 (Manage Users) is selected.
                      child: _selectedIndex == 1 
                          ? _buildUsersTable() 
                          : Center(
                              child: Text(
                                _getPlaceholderText(_selectedIndex), 
                                style: const TextStyle(color: Colors.grey, fontSize: 18)
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Sidebar Menu Item ---
  Widget _buildNavItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimary : Colors.grey.shade600),
      title: Text(title, style: TextStyle(
        color: isSelected ? kPrimary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      selectedTileColor: kPrimary.withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  // --- WIDGET HELPER: Statistic Cards ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ],
        ),
      ),
    );
  }

  String _getPlaceholderText(int index) {
    switch (index) {
      case 0: return 'Data Table / Charts will be here';
      case 1: return 'List of all registered students & sellers';
      case 2: return 'List of stores waiting for approval';
      case 3: return 'History of all UMART transactions';
      default: return 'Content missing';
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

        var users = snapshot.data!.docs;

        return SingleChildScrollView(
          // KITA BUANG SCROLL MENDATAR, GANTI DENGAN SIZEDBOX
          child: SizedBox(
            width: double.infinity, // Paksa jadual kembang penuh
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(kBg),
              columns: const [
                DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(users.length, (index) {
                var userData = users[index].data() as Map<String, dynamic>;
                
                // Tambah lebih banyak kemungkinan ejaan untuk tarik nama dari Firebase
                String name = userData['name'] ?? userData['username'] ?? userData['fullName'] ?? userData['displayName'] ?? 'No Name';
                String email = userData['email'] ?? 'No Email';
                String role = userData['role'] ?? 'Student'; // Default to student

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
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
                            color: role.toLowerCase() == 'seller' ? Colors.orange.shade700 : Colors.blue.shade700
                          )
                        ),
                      )
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () {
                          // TODO: Add delete user from Firestore logic here
                        },
                      ),
                    ),
                  ]
                );
              }),
            ),
          ),
        );
      },
    );
  }
}