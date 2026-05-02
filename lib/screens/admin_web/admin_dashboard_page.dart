import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_page.dart';
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
                  // ─── MAIN CONTENT AREA (DATA TABLE) ───
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
                      child: _selectedIndex == 1 
                          ? _buildUsersTable() 
                          : _selectedIndex == 2
                              ? _buildStoresTable()
                              : _selectedIndex == 3
                                  ? _buildOrdersTable() // Tunjuk jadual Orders kalau pilih menu ke-3
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
              headingRowColor: WidgetStateProperty.all(kBg),
              columns: const [
                DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(users.length, (index) {
                var userData = users[index].data() as Map<String, dynamic>;
                String docId = users[index].id; // we take docId for delete action
                
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
                          _deleteUser(docId, name);
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
      // Assuming your Firebase collection for stores is named 'stores'
      await FirebaseFirestore.instance.collection('stores').doc(docId).update({
        'status': newStatus,
      });
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

        var stores = snapshot.data!.docs;

        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(kBg),
              columns: const [
                DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Store Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(stores.length, (index) {
                var storeData = stores[index].data() as Map<String, dynamic>;
                String docId = stores[index].id;
                
                String storeName = storeData['storeName'] ?? 'Unnamed Store';
                String ownerName = storeData['ownerName'] ?? storeData['sellerName'] ?? storeData['name'] ?? storeData['owner'] ?? 'Unknown Owner';
                String status = storeData['status'] ?? 'Pending'; 

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(storeName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    
                    // --- KITA TUKAR SEL OWNER JADI FUTUREBUILDER ---
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
                                // Tarik nama dari koleksi users
                                String realName = userData['name'] ?? userData['username'] ?? userData['fullName'] ?? 'No Name';
                                return Text(realName);
                              }
                              return const Text('User Deleted', style: TextStyle(color: Colors.red, fontSize: 12));
                            },
                          )
                        : const Text('No ID', style: TextStyle(color: Colors.grey)),
                    ),
                    // ------------------------------------------------

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
                      status == 'Pending' ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                        ],
                      ) : Text(
                        status == 'Approved' ? 'Done' : 'Closed', 
                        style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)
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

        var orders = snapshot.data!.docs;

        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(kBg),
              columns: const [
                DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Buyer', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total (RM)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(orders.length, (index) {
                var orderData = orders[index].data() as Map<String, dynamic>;
                String docId = orders[index].id;
                
                // Format ID biar nampak lawa sikit (contoh: #UM-A1B2C)
                String displayId = '#UM-${docId.substring(0, 5).toUpperCase()}';
                
                // Fallbacks
                String buyerName = orderData['buyerName'] ?? 'Unknown Buyer';
                String itemName = orderData['productName'] ?? 'Item';
                String status = orderData['status'] ?? 'Pending';
                
                // Safe parsing for total price
                double total = 0.0;
                if (orderData['totalPrice'] != null) {
                  total = (orderData['totalPrice'] as num).toDouble();
                }

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
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
        );
      },
    );
  }
}