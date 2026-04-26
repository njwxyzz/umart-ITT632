import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  final List<String> _categories = [
    'Food & Beverages', 
    'Apparel', 
    'Books & Stationery', 
    'Electronics', 
    'Others'
  ];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Pre-fill basic text fields
    _nameController.text = widget.productData['name'] ?? widget.productData['productName'] ?? '';
    _priceController.text = widget.productData['price']?.toString() ?? '';
    _stockController.text = widget.productData['stock']?.toString() ?? '10'; // Default 10 if null
    _descController.text = widget.productData['description'] ?? '';

    // 2. Pre-fill variations list (kalau sebelum ni dia ada letak variations)
    if (widget.productData['variations'] != null) {
      _variations = List<String>.from(widget.productData['variations']);
    }

    // 3. Pre-fill category
    String currentCat = widget.productData['category'] ?? 'Others';
    if (_categories.contains(currentCat)) {
      _selectedCategory = currentCat;
    } else {
      _selectedCategory = 'Others';
    }
  }

  // --- Fungsi Update ke Firebase ---
  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in product name and price.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'variations': _variations, // Save list variations baru
        // Note: Image update logic boleh tambah kemudian
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Fungsi Tambah Variation UI ---
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Edit Product', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PRODUCT PHOTO ---
            const Text('PRODUCT PHOTO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 40, color: kPrimary.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text('Tap to update image', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // --- 2. PRODUCT NAME ---
            _buildLabel('PRODUCT NAME'),
            _buildTextField(hint: 'e.g. Chocojar Viral', controller: _nameController, icon: Icons.fastfood_outlined),
            const SizedBox(height: 20),
            
            // --- 3. PRICE & STOCK ROW ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('PRICE (RM)'),
                      _buildTextField(hint: '0.00', controller: _priceController, icon: Icons.attach_money_rounded, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('AVAILABLE STOCK'),
                      _buildTextField(hint: 'e.g. 10', controller: _stockController, icon: Icons.inventory_2_outlined, isNumber: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 4. VARIATIONS ---
            _buildLabel('VARIATIONS / FLAVORS (OPTIONAL)'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    hint: 'e.g. White Choc, Matcha...', 
                    controller: _variationController, 
                    icon: Icons.style_outlined
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _addVariation,
                  child: Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded, color: kPrimary, size: 28),
                  ),
                ),
              ],
            ),
            // Paparkan tag variations yang dah ditambah
            if (_variations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _variations.map((v) => Chip(
                  label: Text(v, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.cancel, size: 16),
                  onDeleted: () => setState(() => _variations.remove(v)),
                  backgroundColor: kWhite,
                  side: BorderSide(color: Colors.grey.shade300),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // --- 5. CATEGORY ---
            _buildLabel('CATEGORY'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: kWhite, 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _categories.map((String cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(color: Colors.black87)))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 6. DESCRIPTION ---
            _buildLabel('DESCRIPTION'),
            _buildTextField(
              hint: 'Describe your product... (ingredients, condition, size, etc.)', 
              controller: _descController, 
              icon: Icons.subject_rounded, 
              maxLines: 3
            ),
            
            const SizedBox(height: 40),

            // --- UPDATE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: kWhite) 
                    : const Text('Update Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField({required String hint, required TextEditingController controller, required IconData icon, bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0), // Adjust icon position for textarea
            child: Icon(icon, color: Colors.grey.shade400, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}