import 'package:flutter/material.dart';

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  String? _selectedCategory;
  final List<String> _categories = [
    'Food & Beverages', 
    'Preloved Clothes', 
    'Books & Notes', 
    'Gadgets & Accessories',
    'Others'
  ];

  // 🚨 Controller & List untuk Variations (Perisa/Saiz)
  final TextEditingController _variantController = TextEditingController();
  final List<String> _variations = [];

  // Fungsi tambah perisa
  void _addVariation() {
    if (_variantController.text.trim().isNotEmpty) {
      setState(() {
        _variations.add(_variantController.text.trim());
        _variantController.clear();
      });
    }
  }

  @override
  void dispose() {
    _variantController.dispose();
    super.dispose();
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
        title: const Text('Add New Product', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE UPLOAD SECTION ---
            _buildInputLabel('PRODUCT PHOTO'),
            GestureDetector(
              onTap: () {
                // TODO: Implement image_picker package here later
              },
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withOpacity(0.3), width: 2, style: BorderStyle.solid),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 40, color: kPrimary.withOpacity(0.6)),
                    const SizedBox(height: 12),
                    Text('Tap to upload image', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- FORM FIELDS ---
            _buildInputLabel('PRODUCT NAME'),
            _buildCleanTextField(hint: 'e.g. Chocojar Viral', icon: Icons.fastfood_rounded),

            // --- PRICE & STOCK (Side by side) ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('PRICE (RM)'),
                      _buildCleanTextField(
                        hint: '0.00', 
                        icon: Icons.attach_money_rounded, 
                        keyboardType: const TextInputType.numberWithOptions(decimal: true)
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('AVAILABLE STOCK'),
                      _buildCleanTextField(
                        hint: 'e.g. 10', 
                        icon: Icons.inventory_2_outlined, 
                        keyboardType: TextInputType.number
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- 🚨 VARIATIONS SECTION (FLAVORS/SIZES) ---
            _buildInputLabel('VARIATIONS / FLAVORS (OPTIONAL)'),
            Row(
              children: [
                Expanded(
                  child: _buildCleanTextField(
                    hint: 'e.g. White Choc, Matcha...', 
                    icon: Icons.style_rounded,
                    controller: _variantController, // Pakai controller ni
                  ),
                ),
                const SizedBox(width: 12),
                // Butang tambah (+)
                GestureDetector(
                  onTap: _addVariation,
                  child: Container(
                    height: 54, width: 54, // Kasi sama tinggi dengan TextField
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_rounded, color: kPrimary, size: 28),
                  ),
                ),
              ],
            ),
            // Tempat tag (Chips) akan keluar lepas tambah
            if (_variations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0, // Jarak kiri kanan antara chip
                runSpacing: 8.0, // Jarak atas bawah kalau turun baris
                children: _variations.map((variant) {
                  return Chip(
                    label: Text(variant, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary)),
                    backgroundColor: kPrimary.withOpacity(0.1),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                    deleteIconColor: kPrimary,
                    onDeleted: () {
                      setState(() {
                        _variations.remove(variant);
                      });
                    },
                    side: BorderSide.none, // Buang border hitam
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
            ],

            _buildInputLabel('CATEGORY'),
            _buildDropdownField(),

            _buildInputLabel('DESCRIPTION'),
            _buildCleanTextField(
              hint: 'Describe your product... (ingredients, condition, size, etc.)', 
              icon: Icons.edit_note_rounded, 
              maxLines: 4
            ),

            const SizedBox(height: 40),

            // --- PUBLISH BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save to Firebase Firestore here
                  
                  // Temporary Success Action
                  Navigator.pop(context); // Go back to Dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: kWhite),
                          SizedBox(width: 10),
                          Text('Product published successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      backgroundColor: kPrimary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: kPrimary.withOpacity(0.4),
                ),
                child: const Text('Publish Product', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
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
  Widget _buildCleanTextField({
    required String hint, 
    required IconData icon, 
    int maxLines = 1, 
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller, // Boleh terima controller sekarang
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines * 8.0) : 0), 
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
        value: _selectedCategory,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        dropdownColor: kWhite,
        borderRadius: BorderRadius.circular(16),
        items: _categories.map((String val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)))).toList(),
        onChanged: (val) => setState(() => _selectedCategory = val),
      ),
    );
  }
}