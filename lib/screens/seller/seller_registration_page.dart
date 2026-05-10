import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class SellerRegistrationPage extends StatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  State<SellerRegistrationPage> createState() => _SellerRegistrationPageState();
}

class _SellerRegistrationPageState extends State<SellerRegistrationPage> {
  // --- TEXT CONTROLLERS (Pockets to catch user input) ---
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController(); 

  String? _selectedCategory;
  final List<String> _categories = [
    'Food & Beverages', 
    'Preloved Items', 
    'Printing Services', 
    'Others'
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, 
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05, 
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ICON ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 36),
                ),
                const SizedBox(height: 24),
                
                // --- TITLE & SUBTITLE ---
                const Text(
                  'Set up your\nStore Profile',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E), height: 1.2, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your store. An admin will review your application—you will get an in-app notification when it is approved.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 40),

                // --- FORM FIELDS ---
                // 🚨 TUKAR LABEL JADI OPTIONAL 🚨
                _buildInputLabel('STORE NAME (OPTIONAL)'),
                _buildCleanTextField(
                  hint: 'Leave blank to use your real name', 
                  icon: Icons.store_rounded,
                  controller: _storeNameController,
                ),

                _buildInputLabel('WHAT ARE YOU SELLING?'),
                _buildDropdownField(),

                _buildInputLabel('LOCATION / COLLEGE BLOCK'),
                _buildCleanTextField(
                  hint: 'e.g. Kolej Dahlia 3, Bilik 204', 
                  icon: Icons.location_on_rounded,
                  controller: _locationController,
                ),

                _buildInputLabel('SHORT DESCRIPTION'),
                _buildCleanTextField(
                  hint: 'e.g. Selling hot nasi lemak every morning!', 
                  icon: Icons.edit_note_rounded, 
                  maxLines: 3,
                  controller: _descController,
                ),

                const SizedBox(height: 50),

                // --- SUBMIT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Tunjuk loading pusing-pusing
                        showDialog(
                          context: context, 
                          barrierDismissible: false, 
                          builder: (_) => const Center(child: CircularProgressIndicator(color: kPrimary)),
                        );

                        User? currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) throw Exception("Tiada user login!");
                        
                        String uid = currentUser.uid;
                        String inputName = _storeNameController.text.trim();
                        String finalStoreName = inputName;

                        // 🚨 LOGIK MAGIK OPTIONAL 🚨
                        if (inputName.isEmpty) {
                          var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                          if (userDoc.exists && userDoc.data()?['fullName'] != null && userDoc.data()!['fullName'].toString().isNotEmpty) {
                            finalStoreName = userDoc.data()!['fullName'];
                          } else {
                            finalStoreName = currentUser.email?.split('@')[0].toUpperCase() ?? "Student Store";
                          }
                        }

                        String finalLocation = _locationController.text.trim().isEmpty 
                            ? "UiTM Campus" 
                            : _locationController.text.trim();

                        String ownerName = currentUser.email?.split('@')[0] ?? 'Student';
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                        if (userDoc.exists) {
                          final u = userDoc.data();
                          final fn = u?['fullName']?.toString().trim();
                          if (fn != null && fn.isNotEmpty) ownerName = fn;
                        }

                        // Simpan data kedai dalam Firebase — tunggu kelulusan admin
                        await FirebaseFirestore.instance.collection('stores').doc(uid).set({
                          'storeName': finalStoreName,
                          'storeLocation': finalLocation,
                          'category': _selectedCategory ?? 'Others',
                          'description': _descController.text.trim(),
                          'ownerId': uid,
                          'ownerName': ownerName,
                          'status': 'Pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) Navigator.pop(context); // Tutup loading indicator

                        if (context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context).pop(); // Leave registration page
                          Navigator.of(context).maybePop(); // Close "Start Selling" bottom sheet if still open
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Application submitted. You will be notified when an admin approves your store.',
                              ),
                              backgroundColor: kPrimary,
                            ),
                          );
                        }

                      } catch (e) {
                        if (context.mounted) Navigator.pop(context); // Tutup loading kalau error
                        print("Error saving store: $e");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create store: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: kPrimary.withOpacity(0.4), 
                    ),
                    child: const Text('Submit application', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HELPER WIDGET: Input Field Label
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        label, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), letterSpacing: 0.8)
      ),
    );
  }

  // HELPER WIDGET: Clean Text Field
  Widget _buildCleanTextField({required String hint, required IconData icon, int maxLines = 1, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 0), 
            child: Icon(icon, color: Colors.grey.shade400, size: 22),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // HELPER WIDGET: Category Dropdown
  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.category_rounded, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        hint: Text('Select category', style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400)),
        initialValue: _selectedCategory,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        dropdownColor: kWhite,
        borderRadius: BorderRadius.circular(16),
        items: _categories.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)))).toList(),
        onChanged: (val) => setState(() => _selectedCategory = val),
      ),
    );
  }
}