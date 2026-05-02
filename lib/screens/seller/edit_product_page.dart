import 'package:flutter/material.dart';
import 'dart:typed_data'; // WAJIB untuk handle gambar kat Web
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F);
const kBg = Color(0xFFF5F7F2);
const kWhite = Colors.white;

class EditProductPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditProductPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _variationController = TextEditingController();

  List<String> _variations = [];
  late String _selectedCategory;

  // --- Image State (same approach as add_product_page.dart) ---
  Uint8List? _newImageBytes;      // bytes of newly picked image
  String? _existingImageUrl;      // URL loaded from Firestore

  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Food & Beverages',
    'Preloved Items',
    'Books & Notes',
    'Gadgets & Accessories',
    'Others',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        widget.productData['name'] ?? widget.productData['productName'] ?? '';
    _priceController.text = widget.productData['price']?.toString() ?? '';
    _stockController.text = widget.productData['stock']?.toString() ?? '10';
    _descController.text = widget.productData['description'] ?? '';

    if (widget.productData['variations'] != null) {
      _variations = List<String>.from(widget.productData['variations']);
    }

    String currentCat = widget.productData['category'] ?? 'Others';
    _selectedCategory =
        _categories.contains(currentCat) ? currentCat : 'Others';

    _existingImageUrl = widget.productData['imageUrl'] as String?;
  }

  // --- Pick Image (Web-safe, same as add_product_page) ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- Upload to Firebase Storage using putData (Web-safe) ---
  Future<String?> _uploadImageToStorage() async {
    if (_newImageBytes == null) return null;

    try {
      String fileName =
          'products/${widget.productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = storageRef.putData(_newImageBytes!);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload image: $e'),
              backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  // --- Update Product ---
  Future<void> _updateProduct() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in product name and price.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload new image if seller picked one
      String? newImageUrl;
      if (_newImageBytes != null) {
        newImageUrl = await _uploadImageToStorage();
        if (newImageUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Build update map
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'variations': _variations,
      };

      // 3. Decide imageUrl:
      //    New image picked     -> save new URL
      //    No change            -> keep existing (don't touch field)
      //    User removed image   -> delete field from Firestore
      if (newImageUrl != null) {
        updateData['imageUrl'] = newImageUrl;
      } else if (_existingImageUrl == null) {
        updateData['imageUrl'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: kWhite),
                SizedBox(width: 10),
                Text('Product updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: kPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating product: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Add Variation ---
  void _addVariation() {
    String newVal = _variationController.text.trim();
    if (newVal.isNotEmpty && !_variations.contains(newVal)) {
      setState(() {
        _variations.add(newVal);
        _variationController.clear();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _variationController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Edit Product',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PRODUCT PHOTO ---
            _buildLabel('PRODUCT PHOTO'),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: kPrimary.withOpacity(0.3),
                      width: 1.5,
                      style: BorderStyle.solid),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildImagePreview(),
              ),
            ),

            const SizedBox(height: 16),

            // --- 2. PRODUCT NAME ---
            _buildLabel('PRODUCT NAME'),
            _buildTextField(
                hint: 'e.g. Chocojar Viral',
                controller: _nameController,
                icon: Icons.fastfood_outlined),
            const SizedBox(height: 16),

            // --- 3. PRICE & STOCK ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('PRICE (RM)'),
                      _buildTextField(
                          hint: '0.00',
                          controller: _priceController,
                          icon: Icons.attach_money_rounded,
                          isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('AVAILABLE STOCK'),
                      _buildTextField(
                          hint: 'e.g. 10',
                          controller: _stockController,
                          icon: Icons.inventory_2_outlined,
                          isNumber: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 4. VARIATIONS ---
            _buildLabel('VARIATIONS / FLAVORS (OPTIONAL)'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      hint: 'e.g. White Choc, Matcha...',
                      controller: _variationController,
                      icon: Icons.style_outlined),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addVariation,
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: kPrimary, size: 28),
                  ),
                ),
              ],
            ),
            if (_variations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _variations
                    .map((v) => Chip(
                          label: Text(v,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary)),
                          backgroundColor: kPrimary.withOpacity(0.1),
                          deleteIcon:
                              const Icon(Icons.close_rounded, size: 16),
                          deleteIconColor: kPrimary,
                          onDeleted: () =>
                              setState(() => _variations.remove(v)),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),

            // --- 5. CATEGORY ---
            _buildLabel('CATEGORY'),
            Container(
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded,
                      color: Colors.grey.shade400, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
                initialValue: _selectedCategory,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey),
                dropdownColor: kWhite,
                borderRadius: BorderRadius.circular(16),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            ),
            const SizedBox(height: 16),

            // --- 6. DESCRIPTION ---
            _buildLabel('DESCRIPTION'),
            _buildTextField(
                hint:
                    'Describe your product... (ingredients, condition, size, etc.)',
                controller: _descController,
                icon: Icons.edit_note_rounded,
                maxLines: 4),

            const SizedBox(height: 40),

            // --- UPDATE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: kPrimary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: kWhite, strokeWidth: 3))
                    : const Text('Update Product',
                        style: TextStyle(
                            color: kWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Image Preview ---
  Widget _buildImagePreview() {
    if (_newImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_newImageBytes!, fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: kWhite, size: 14),
                  SizedBox(width: 4),
                  Text('Change',
                      style: TextStyle(color: kWhite, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: kPrimary)),
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: kWhite, size: 14),
                  SizedBox(width: 4),
                  Text('Change',
                      style: TextStyle(color: kWhite, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined,
            size: 40, color: kPrimary.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text('Tap to upload image',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.8)),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding:
                EdgeInsets.only(bottom: maxLines > 1 ? (maxLines * 8.0) : 0),
            child: Icon(icon, color: Colors.grey.shade400, size: 22),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}