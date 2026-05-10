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
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();

  // 🚨 TUKAR DARI FILE KE UINT8LIST UNTUK WEB 🚨
  final List<Uint8List> _selectedImageBytesList = [];
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false; 

  // --- 1. FUNCTION: PICK IMAGE (WEB SAFE) ---
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);

      if (pickedFiles.isNotEmpty) {
        final bytesList = <Uint8List>[];
        for (final file in pickedFiles) {
          bytesList.add(await file.readAsBytes());
        }
        setState(() {
          _selectedImageBytesList.addAll(bytesList);
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
  final Map<String, TextEditingController> _variationPriceControllers = {};

  void _addVariation() {
    final variationName = _variantController.text.trim();
    if (variationName.isNotEmpty && !_variations.contains(variationName)) {
      setState(() {
        _variations.add(variationName);
        _variationPriceControllers[variationName] = TextEditingController();
        _variantController.clear();
      });
    }
  }

  void _moveImage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _selectedImageBytesList.length) return;
    if (newIndex < 0 || newIndex >= _selectedImageBytesList.length) return;
    setState(() {
      final item = _selectedImageBytesList.removeAt(oldIndex);
      _selectedImageBytesList.insert(newIndex, item);
    });
  }

  // --- 2. FUNCTION: UPLOAD KE STORAGE & FIRESTORE ---
  Future<void> _uploadProduct() async {
    if (_nameController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Product Name and Price! 🛑')),
      );
      return;
    }

    if (_selectedImageBytesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image first! 📸')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = <String>[];

      // A. Upload semua gambar dulu ke Firebase Storage
      for (int i = 0; i < _selectedImageBytesList.length; i++) {
        final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = storageRef.putData(_selectedImageBytesList[i]);
        final snapshot = await uploadTask;
        imageUrls.add(await snapshot.ref.getDownloadURL());
      }

      final variationPrices = <String, double>{};
      for (final variation in _variations) {
        final priceText = _variationPriceControllers[variation]?.text.trim() ?? '';
        final parsed = double.tryParse(priceText);
        if (parsed != null) variationPrices[variation] = parsed;
      }

      // B. HANTAR INFO KE FIRESTORE (Database)
      final sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'deliveryFee': double.tryParse(_deliveryFeeController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descController.text.trim().isEmpty ? 'No description' : _descController.text.trim(),
        'category': _selectedCategory ?? 'Others',
        'variations': _variations, 
        'variationPrices': variationPrices,
        'sellerName': widget.storeName, 
        'sellerId': sellerId,
        'imageUrl': imageUrls.first, // Backward compatibility
        'imageUrls': imageUrls,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: kWhite),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Product submitted. It will appear in the marketplace after an admin approves it.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
    _deliveryFeeController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _variantController.dispose();
    for (final c in _variationPriceControllers.values) {
      c.dispose();
    }
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
              onTap: _pickImages, 
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimary.withOpacity(0.3), width: 1.5, style: BorderStyle.solid),
                ),
                clipBehavior: Clip.hardEdge, 
                child: _selectedImageBytesList.isNotEmpty
                    ? Image.memory(
                        _selectedImageBytesList.first,
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
            if (_selectedImageBytesList.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImageBytesList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _selectedImageBytesList[index],
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImageBytesList.removeAt(index)),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                        if (_selectedImageBytesList.length > 1)
                          Positioned(
                            left: 2,
                            bottom: 2,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: index > 0 ? () => _moveImage(index, index - 1) : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: index > 0 ? Colors.black54 : Colors.black26,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chevron_left, size: 14, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: index < _selectedImageBytesList.length - 1
                                      ? () => _moveImage(index, index + 1)
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: index < _selectedImageBytesList.length - 1
                                          ? Colors.black54
                                          : Colors.black26,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chevron_right, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tip: First image becomes cover image. Use arrows to reorder.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
            
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
            _buildInputLabel('DELIVERY FEE (RM)'),
            _buildCleanTextField(
              hint: '0.00 (Enter 0 for Free Delivery)',
              icon: Icons.local_shipping_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: _deliveryFeeController,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                'Enter 0 if you want to offer Free Delivery.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
              Column(
                children: _variations.map((variant) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              variant,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: _buildCleanTextField(
                            hint: 'Price',
                            icon: Icons.payments_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            controller: _variationPriceControllers[variant],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _variationPriceControllers[variant]?.dispose();
                              _variationPriceControllers.remove(variant);
                              _variations.remove(variant);
                            });
                          },
                          icon: const Icon(Icons.close_rounded, color: kPrimary),
                        ),
                      ],
                    ),
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