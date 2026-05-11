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
  final TextEditingController _deliveryFeeController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _variationController = TextEditingController();

  List<String> _variations = [];
  final Map<String, TextEditingController> _variationPriceControllers = {};
  late String _selectedCategory;

  // --- Multi image state ---
  final List<Uint8List> _newImageBytesList = [];
  List<String> _existingImageUrls = [];

  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Food & Beverages',
    'Preloved Items',
    'Books & Notes',
    'Gadgets & Accessories',
    'Printing Services',
    'Others',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        widget.productData['name'] ?? widget.productData['productName'] ?? '';
    _priceController.text = widget.productData['price']?.toString() ?? '';
    final rawDeliveryFee = widget.productData['deliveryFee'];
    if (rawDeliveryFee is num) {
      _deliveryFeeController.text = rawDeliveryFee.toDouble().toString();
    } else if (rawDeliveryFee != null) {
      _deliveryFeeController.text = rawDeliveryFee.toString();
    }
    _stockController.text = widget.productData['stock']?.toString() ?? '10';
    _descController.text = widget.productData['description'] ?? '';

    if (widget.productData['variations'] != null) {
      _variations = List<String>.from(widget.productData['variations']);
    }

    final rawVariationPrices = widget.productData['variationPrices'];
    final parsedVariationPrices = <String, double>{};
    if (rawVariationPrices is Map) {
      for (final entry in rawVariationPrices.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is num) {
          parsedVariationPrices[key] = value.toDouble();
        } else {
          final parsed = double.tryParse(value?.toString() ?? '');
          if (parsed != null) parsedVariationPrices[key] = parsed;
        }
      }
    }
    for (final variation in _variations) {
      _variationPriceControllers[variation] = TextEditingController(
        text: parsedVariationPrices[variation]?.toString() ?? '',
      );
    }

    String currentCat = widget.productData['category'] ?? 'Others';
    _selectedCategory =
        _categories.contains(currentCat) ? currentCat : 'Others';

    final rawImageUrls = widget.productData['imageUrls'];
    if (rawImageUrls is List) {
      _existingImageUrls = rawImageUrls.whereType<String>().where((e) => e.trim().isNotEmpty).toList();
    }
    if (_existingImageUrls.isEmpty) {
      final fallbackImageUrl = (widget.productData['imageUrl'] ?? '').toString();
      if (fallbackImageUrl.isNotEmpty) _existingImageUrls = [fallbackImageUrl];
    }
  }

  // --- Pick Image (Web-safe, same as add_product_page) ---
  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
      if (pickedFiles.isNotEmpty) {
        final bytesList = <Uint8List>[];
        for (final file in pickedFiles) {
          bytesList.add(await file.readAsBytes());
        }
        setState(() {
          _newImageBytesList.addAll(bytesList);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- Upload to Firebase Storage using putData (Web-safe) ---
  Future<List<String>> _uploadImagesToStorage() async {
    if (_newImageBytesList.isEmpty) return [];

    final urls = <String>[];
    try {
      for (int i = 0; i < _newImageBytesList.length; i++) {
        final fileName = 'products/${widget.productId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = storageRef.putData(_newImageBytesList[i]);
        final snapshot = await uploadTask;
        urls.add(await snapshot.ref.getDownloadURL());
      }
      return urls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
        );
      }
      return [];
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
      // 1. Upload new images if seller picked any
      List<String> newImageUrls = [];
      if (_newImageBytesList.isNotEmpty) {
        newImageUrls = await _uploadImagesToStorage();
        if (newImageUrls.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final variationPrices = <String, double>{};
      for (final variation in _variations) {
        final priceText = _variationPriceControllers[variation]?.text.trim() ?? '';
        final parsed = double.tryParse(priceText);
        if (parsed != null) variationPrices[variation] = parsed;
      }

      final finalImageUrls = [..._existingImageUrls, ...newImageUrls];
      final sellerId = (widget.productData['sellerId'] ?? widget.productData['ownerId'] ?? '').toString().trim();
      String storeLocation =
          (widget.productData['storeLocation'] ?? widget.productData['sellerLocation'] ?? widget.productData['location'] ?? '')
              .toString()
              .trim();
      if (sellerId.isNotEmpty) {
        final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(sellerId).get();
        if (storeDoc.exists) {
          final data = storeDoc.data() ?? {};
          final latestLocation = (data['storeLocation'] ?? data['location'] ?? data['address'] ?? '').toString().trim();
          if (latestLocation.isNotEmpty) {
            storeLocation = latestLocation;
          }
        }
      }

      // 2. Build update map
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'deliveryFee': double.tryParse(_deliveryFeeController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'variations': _variations,
        'variationPrices': variationPrices,
        'storeLocation': storeLocation,
        'location': storeLocation,
        'status': 'Pending',
      };

      // 3. Decide imageUrl:
      //    New image picked     -> save new URL
      //    No change            -> keep existing (don't touch field)
      //    User removed image   -> delete field from Firestore
      if (finalImageUrls.isNotEmpty) {
        updateData['imageUrl'] = finalImageUrls.first;
        updateData['imageUrls'] = finalImageUrls;
      } else {
        updateData['imageUrl'] = FieldValue.delete();
        updateData['imageUrls'] = FieldValue.delete();
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
                Icon(Icons.hourglass_top_rounded, color: kWhite),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes saved. Your product is pending admin review again before buyers can see it.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
        _variationPriceControllers[newVal] = TextEditingController();
        _variationController.clear();
      });
    }
  }

  void _moveExistingImage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _existingImageUrls.length) return;
    if (newIndex < 0 || newIndex >= _existingImageUrls.length) return;
    setState(() {
      final item = _existingImageUrls.removeAt(oldIndex);
      _existingImageUrls.insert(newIndex, item);
    });
  }

  void _moveNewImage(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _newImageBytesList.length) return;
    if (newIndex < 0 || newIndex >= _newImageBytesList.length) return;
    setState(() {
      final item = _newImageBytesList.removeAt(oldIndex);
      _newImageBytesList.insert(newIndex, item);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _deliveryFeeController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _variationController.dispose();
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
              onTap: _pickImages,
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
            if (_existingImageUrls.isNotEmpty || _newImageBytesList.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImageUrls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: kPrimary.withOpacity(0.08),
                                  child: const Icon(Icons.image_not_supported_outlined, color: kPrimary),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _existingImageUrls.removeAt(index)),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                            if (_existingImageUrls.length > 1)
                              Positioned(
                                left: 2,
                                bottom: 2,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: index > 0 ? () => _moveExistingImage(index, index - 1) : null,
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
                                      onTap: index < _existingImageUrls.length - 1
                                          ? () => _moveExistingImage(index, index + 1)
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: index < _existingImageUrls.length - 1
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
                        ),
                      );
                    }),
                    ..._newImageBytesList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bytes = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _newImageBytesList.removeAt(index)),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                            if (_newImageBytesList.length > 1)
                              Positioned(
                                left: 2,
                                bottom: 2,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: index > 0 ? () => _moveNewImage(index, index - 1) : null,
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
                                      onTap: index < _newImageBytesList.length - 1
                                          ? () => _moveNewImage(index, index + 1)
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: index < _newImageBytesList.length - 1
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
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tip: First image becomes cover image. Reorder with arrows.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],

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

            _buildLabel('DELIVERY FEE (RM)'),
            _buildTextField(
              hint: '0.00 (Enter 0 for Free Delivery)',
              controller: _deliveryFeeController,
              icon: Icons.local_shipping_outlined,
              isNumber: true,
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
              Column(
                children: _variations.map((v) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              v,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: _buildTextField(
                            hint: 'Price',
                            controller: _variationPriceControllers[v]!,
                            icon: Icons.payments_outlined,
                            isNumber: true,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _variationPriceControllers[v]?.dispose();
                              _variationPriceControllers.remove(v);
                              _variations.remove(v);
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
    if (_newImageBytesList.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_newImageBytesList.first, fit: BoxFit.cover),
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

    if (_existingImageUrls.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _existingImageUrls.first,
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