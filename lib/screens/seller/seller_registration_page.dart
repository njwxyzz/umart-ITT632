import 'package:flutter/material.dart';
import 'seller_dashboard.dart';

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
  String? _selectedCategory;
  final List<String> _categories = [
    'Food & Beverages', 
    'Preloved Items', 
    'Printing Services', 
    'Others'
  ];

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
      extendBodyBehindAppBar: true, // Extend background to the top of the screen
      body: Container(
        // BACKGROUND PATTERN (For a premium look)
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
                  'Tell us a bit about what you are selling. You can always change this later.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 40),

                // --- FORM FIELDS ---
                _buildInputLabel('STORE NAME'),
                _buildCleanTextField(hint: 'e.g. Mak Cik Siti Nasi Lemak', icon: Icons.store_rounded),

                _buildInputLabel('WHAT ARE YOU SELLING?'),
                _buildDropdownField(),

                _buildInputLabel('LOCATION / COLLEGE BLOCK'),
                _buildCleanTextField(hint: 'e.g. Kolej Dahlia 3, Bilik 204', icon: Icons.location_on_rounded),

                _buildInputLabel('SHORT DESCRIPTION'),
                _buildCleanTextField(hint: 'e.g. Selling hot nasi lemak every morning!', icon: Icons.edit_note_rounded, maxLines: 3),

                const SizedBox(height: 50),

                // --- SUBMIT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to Seller Dashboard and replace the current page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SellerDashboard()),
                      );
                      
                      // TODO: Add Firebase Firestore saving logic here later
                      
                      // Show Success SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: kWhite),
                              SizedBox(width: 10),
                              Expanded(child: Text('Store created successfully! Welcome to UMART Sellers.', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          backgroundColor: kPrimary,
                          behavior: SnackBarBehavior.floating, // Floating pop-up style
                          margin: EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: kPrimary.withOpacity(0.4), // Button shadow
                    ),
                    child: const Text('Create My Store', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

  // HELPER WIDGET: Clean Text Field (iOS Style)
  Widget _buildCleanTextField({required String hint, required IconData icon, int maxLines = 1}) {
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