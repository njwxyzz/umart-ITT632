import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart'; // To link Manage Profile
import '../auth/login_page.dart'; // To link Logout

// --- Color Constants ---
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCheckingStatus = true;
  bool _isSeller = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsSeller();
  }

  // Check if the current user has an active store in the database
  Future<void> _checkIfUserIsSeller() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var storeDoc = await FirebaseFirestore.instance.collection('stores').doc(user.uid).get();
        if (mounted) {
          setState(() {
            _isSeller = storeDoc.exists;
            _isCheckingStatus = false;
          });
        }
      }
    } catch (e) {
      print("Error checking seller status: $e");
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  // --- CORE LOGIC: REMOVE STORE ---
  Future<void> _processStoreDeletion() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String uid = user.uid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      // SAFETY CHECK: Find any active orders
      var ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .get();

      bool hasActiveOrders = false;
      for (var doc in ordersQuery.docs) {
        var status = doc.data()['status'];
        if (status == 'Pending' || status == 'Processing') {
          hasActiveOrders = true;
          break;
        }
      }

      if (hasActiveOrders) {
        if (context.mounted) Navigator.pop(context); // Close loading indicator
        if (context.mounted) {
          _showErrorDialog(
            "Action Blocked", 
            "You cannot close your store because you still have active orders (Pending or Processing). Please fulfill or cancel them first."
          );
        }
        return; 
      }

      // 3. SAFE TO DELETE: Remove all ghost products first
      // Kita panggil DUA-DUA nama label (ownerId & sellerId) sebab takut kau pakai salah satu
      var queryByOwner = await FirebaseFirestore.instance.collection('products').where('ownerId', isEqualTo: uid).get();
      var queryBySeller = await FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: uid).get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      // Sapu yang label ownerId
      for (var doc in queryByOwner.docs) {
        batch.delete(doc.reference);
      }
      // Sapu yang label sellerId
      for (var doc in queryBySeller.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();

      // 4. Finally, remove the store document itself
      await FirebaseFirestore.instance.collection('stores').doc(uid).delete();

      if (context.mounted) Navigator.pop(context); // Close loading indicator

      // 5. Navigate back with Success Message
      if (context.mounted) {
        Navigator.pop(context); // Go back to Profile Page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your store has been successfully permanently closed.'),
            backgroundColor: kPrimary,
          ),
        );
      }

    } catch (e) {
      if (context.mounted) Navigator.pop(context); 
      print("Error deleting store: $e");
      if (context.mounted) {
        _showErrorDialog("System Error", "Failed to close store: $e");
      }
    }
  }

  // --- UI DIALOGS ---

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Close Store?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently close your store? All your active product listings will be deleted.\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _processStoreDeletion(); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Close Store', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
        content: Text(message, style: const TextStyle(color: Colors.black87, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Understood', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isCheckingStatus 
        ? const Center(child: CircularProgressIndicator(color: kPrimary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION: ACCOUNT ---
                _buildSectionTitle('Account'),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Manage Profile',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Password & Security',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // --- SECTION: PREFERENCES ---
                _buildSectionTitle('Preferences'),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      trailingText: 'English', 
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      trailingText: 'Light', 
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.calendar_today_rounded,
                      title: 'My Schedule', 
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- SECTION: SUPPORT ---
                _buildSectionTitle('Support'),
                _buildSettingsCard(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.headset_mic_outlined,
                      title: 'Contact Us',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About UMART',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- SECTION: STORE MANAGEMENT (DYNAMIC) ---
                if (_isSeller) ...[
                  _buildSectionTitle('Store Management'),
                  _buildSettingsCard(
                    children: [
                      ListTile(
                        onTap: _showConfirmationDialog,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1), 
                            borderRadius: BorderRadius.circular(10)
                          ),
                          child: const Icon(Icons.remove_shopping_cart_rounded, color: Colors.red, size: 20),
                        ),
                        title: const Text(
                          'Close & Delete My Store', 
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // --- LOGOUT BUTTON (Clean iOS Style) ---
                _buildSettingsCard(
                  children: [
                    ListTile(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.black54, size: 20),
                      ),
                      title: const Text(
                        'Log Out', 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  // HELPER WIDGET: Section Title (e.g., Account, Preferences)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.8),
      ),
    );
  }

  // HELPER WIDGET: White Card Container for grouping tiles
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // HELPER WIDGET: Individual Setting Row
  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    String? trailingText, 
    required VoidCallback onTap
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
        ],
      ),
    );
  }

  // HELPER WIDGET: Subtle divider between tiles inside the card
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 60, // Indent so it doesn't go under the icon
      endIndent: 20,
    );
  }
}