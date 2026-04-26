import 'package:flutter/material.dart';
import 'dart:typed_data'; // WAJIB untuk handle gambar kat Web
import 'package:image_picker/image_picker.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // WAJIB untuk Firebase Storage

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class AddProductPage extends StatefulWidget {
  final String storeName;
  final String storeLocation;

  const AddProductPage({super.key, this.storeName = '', this.storeLocation = ''}); 

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // --- CONTROLLERS ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();

  // 🚨 TUKAR DARI FILE KE UINT8LIST UNTUK WEB 🚨
  Uint8List? _selectedImageBytes; 
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false; 

  // --- 1. FUNCTION: PICK IMAGE (WEB SAFE) ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 70, 
      );

      if (pickedFile != null) {
        // Baca sebagai memory bytes, bukan File path
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  String? _selectedCategory;
  final List<String> _categories = [
    'Food & Beverages', 
    'Preloved Items', 
    'Books & Notes', 
    'Gadgets & Accessories',
    'Others'
  ];

  final List<String> _variations = [];

  void _addVariation() {
    if (_variantController.text.trim().isNotEmpty) {
      setState(() {
        _variations.add(_variantController.text.trim());
        _variantController.clear();
      });
    }
  }

  // --- 2. FUNCTION: UPLOAD KE STORAGE & FIRESTORE ---
  Future<void> _uploadProduct() async {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Product Name and Price! 🛑')),
      );
      return;
    }

    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first! 📸')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = ""; 
      
      // A. HANTAR GAMBAR KE FIREBASE STORAGE DULU
      String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      
      // Upload bytes ke Storage
      UploadTask uploadTask = storageRef.putData(_selectedImageBytes!);
      TaskSnapshot snapshot = await uploadTask;
      
      // Dapatkan URL rasmi lepas siap upload
      finalImageUrl = await snapshot.ref.getDownloadURL();

      // B. HANTAR INFO KE FIRESTORE (Database)
      final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descController.text.trim().isEmpty ? 'No description' : _descController.text.trim(),
        'category': _selectedCategory ?? 'Others',
        'variations': _variations, 
        'sellerName': widget.storeName, 
        'sellerId': sellerId,
        'imageUrl': finalImageUrl, // Masukkan URL yang dah dapat kat atas
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: kWhite),
                SizedBox(width: 10),
                Text('Product published successfully! 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
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
            // --- PRODUCT PHOTO SECTION ---
            _buildInputLabel('PRODUCT PHOTO'),
            GestureDetector(
              onTap: _pickImage, 
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
                ),
                clipBehavior: Clip.hardEdge, 
                // 🚨 UI CHECK GUNA _selectedImageBytes 🚨
                child: _selectedImageBytes != null 
                    ? Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: kPrimary.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          Text('Tap to upload image', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),

            // --- FORM FIELDS ---
            _buildInputLabel('PRODUCT NAME'),
            _buildCleanTextField(
              hint: 'e.g. Chocojar Viral', 
              icon: Icons.fastfood_rounded,
              controller: _nameController, 
            ),

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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        controller: _priceController, 
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
                        keyboardType: TextInputType.number,
                        controller: _stockController, 
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _buildInputLabel('VARIATIONS / FLAVORS (OPTIONAL)'),
            Row(
              children: [
                Expanded(
                  child: _buildCleanTextField(
                    hint: 'e.g. White Choc, Matcha...', 
                    icon: Icons.style_rounded,
                    controller: _variantController, 
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addVariation,
                  child: Container(
                    height: 54, width: 54, 
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_rounded, color: kPrimary, size: 28),
                  ),
                ),
              ],
            ),
            
            if (_variations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0, 
                runSpacing: 8.0, 
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
                    side: BorderSide.none, 
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
              maxLines: 4,
              controller: _descController, 
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadProduct, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: kPrimary.withOpacity(0.4),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 3))
                  : const Text('Publish Product', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        label, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), letterSpacing: 0.8)
      ),
    );
  }

  Widget _buildCleanTextField({
    required String hint, 
    required IconData icon, 
    int maxLines = 1, 
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller, 
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