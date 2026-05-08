import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_page.dart'; 
import 'cart_manager.dart'; // 🚨 IMPORT OTAK TROLI KAT SINI
import 'store_profile_page.dart';

const kPrimary      = Color(0xFF4C6B3F);
const kAccent       = Color(0xFFF27B35);
const kBg           = Color(0xFFF5F7F2);
const kWhite        = Colors.white;

class ProductDetailPage extends StatefulWidget {
  final String? productId;
  final String name;
  final double price;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String description;
  final List<String>? variations; 

  const ProductDetailPage({
    super.key,
    this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.description,
    this.variations, 
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PageController _imagePageController = PageController();
  int quantity = 1;
  int soldCount = 0;
  int selectedImageIndex = 0;
  String selectedVariation = '';
  List<String> displayVariations = [];
  List<String> displayImages = [];
  Map<String, double> variationPriceMap = {};
  String _resolvedProductId = '';
  double _productDeliveryFee = 0.0;

  bool get _isOwnStoreProduct {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return currentUserId.isNotEmpty && currentUserId == widget.sellerId;
  }

  @override
  void initState() {
    super.initState();
    displayImages = [widget.imageUrl];
    displayVariations = widget.variations ?? [];
    if (displayVariations.isNotEmpty) {
      selectedVariation = displayVariations.first;
    }
    _loadProductMeta();
  }

  double get _selectedUnitPrice {
    if (selectedVariation.isNotEmpty && variationPriceMap.containsKey(selectedVariation)) {
      return variationPriceMap[selectedVariation]!;
    }
    return widget.price;
  }

  Future<void> _loadProductMeta() async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? byIdDoc;
      if ((widget.productId ?? '').trim().isNotEmpty) {
        byIdDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId!.trim())
            .get();
      }

      Map<String, dynamic>? data;
      String resolvedId = '';

      if (byIdDoc != null && byIdDoc.exists) {
        data = byIdDoc.data();
        resolvedId = byIdDoc.id;
      } else {
        final query = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: widget.sellerId)
            .where('name', isEqualTo: widget.name)
            .limit(1)
            .get();
        if (query.docs.isEmpty) return;
        data = query.docs.first.data();
        resolvedId = query.docs.first.id;
      }
      if (data == null) return;
      final rawSoldCount = data['soldCount'] ?? data['sold'] ?? data['totalSold'];
      final rawVariations = data['variations'];
      final rawVariationPrices = data['variationPrices'];
      final rawImageUrls = data['imageUrls'] ?? data['images'] ?? data['gallery'];
      final rawDeliveryFee = data['deliveryFee'];

      final fetchedSoldCount = rawSoldCount is num
          ? rawSoldCount.toInt()
          : int.tryParse(rawSoldCount?.toString() ?? '0') ?? 0;
      final fetchedVariations = rawVariations is List
          ? rawVariations.whereType<String>().toList()
          : <String>[];
      final fetchedImages = rawImageUrls is List
          ? rawImageUrls.whereType<String>().where((url) => url.trim().isNotEmpty).toList()
          : <String>[];
      final fetchedVariationPrices = <String, double>{};
      final fetchedDeliveryFee = rawDeliveryFee is num
          ? rawDeliveryFee.toDouble()
          : double.tryParse(rawDeliveryFee?.toString() ?? '') ?? 0.0;

      if (rawVariationPrices is Map) {
        for (final entry in rawVariationPrices.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is num) {
            fetchedVariationPrices[key] = value.toDouble();
          } else {
            final parsed = double.tryParse(value?.toString() ?? '');
            if (parsed != null) fetchedVariationPrices[key] = parsed;
          }
        }
      } else if (rawVariationPrices is List) {
        for (final item in rawVariationPrices) {
          if (item is Map) {
            final variationName = (item['name'] ?? item['variation'] ?? '').toString();
            final priceValue = item['price'];
            if (variationName.isEmpty) continue;
            if (priceValue is num) {
              fetchedVariationPrices[variationName] = priceValue.toDouble();
            } else {
              final parsed = double.tryParse(priceValue?.toString() ?? '');
              if (parsed != null) fetchedVariationPrices[variationName] = parsed;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _resolvedProductId = resolvedId;
        soldCount = fetchedSoldCount;
        displayVariations = fetchedVariations.isNotEmpty
            ? fetchedVariations
            : (widget.variations ?? []);
        variationPriceMap = fetchedVariationPrices;
        _productDeliveryFee = fetchedDeliveryFee;
        displayImages = fetchedImages.isNotEmpty ? fetchedImages : [widget.imageUrl];
        if (selectedImageIndex >= displayImages.length) {
          selectedImageIndex = 0;
        }
        if (displayVariations.isNotEmpty) {
          if (!displayVariations.contains(selectedVariation)) {
            selectedVariation = displayVariations.first;
          }
        } else {
          selectedVariation = '';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvedProductId = widget.productId ?? '';
        soldCount = 0;
        displayVariations = widget.variations ?? [];
        displayImages = [widget.imageUrl];
        variationPriceMap = {};
        _productDeliveryFee = 0.0;
        selectedVariation = displayVariations.isNotEmpty ? displayVariations.first : '';
        selectedImageIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = _selectedUnitPrice;
    final totalPrice = unitPrice * quantity;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      _buildCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Product Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildCircleButton(
                        icon: Icons.shopping_cart_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 265,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: PageView.builder(
                            controller: _imagePageController,
                            itemCount: displayImages.length,
                            onPageChanged: (index) => setState(() => selectedImageIndex = index),
                            itemBuilder: (_, index) {
                              return GestureDetector(
                                onTap: () => _openFullScreenImage(index),
                                child: Container(
                                  color: const Color(0xFFF6F8F3),
                                  child: Image.network(
                                    displayImages[index],
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: kPrimary.withOpacity(0.1),
                                      child: const Icon(Icons.fastfood_rounded, size: 80, color: kPrimary),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (displayImages.length > 1) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F8F3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: displayImages.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (_, index) {
                                      final isSelected = index == selectedImageIndex;
                                      return GestureDetector(
                                        onTap: () {
                                          _imagePageController.animateToPage(
                                            index,
                                            duration: const Duration(milliseconds: 220),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected ? kPrimary : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: kPrimary.withOpacity(0.25),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: Image.network(
                                            displayImages[index],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: kPrimary.withOpacity(0.08),
                                              child: const Icon(Icons.image_not_supported_outlined, color: kPrimary),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${selectedImageIndex + 1}/${displayImages.length}',
                                  style: const TextStyle(
                                    color: kWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              size: 15,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Tap image to zoom',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A2E),
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'RM${unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: kAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '$soldCount Sold',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9EDE2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: kPrimary.withOpacity(0.12),
                              child: Text(
                                widget.sellerName.isNotEmpty
                                    ? widget.sellerName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.sellerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StoreProfilePage(sellerId: widget.sellerId),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              child: const Text(
                                'Visit Store',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),

                      if (displayVariations.isNotEmpty) ...[
                        const Text(
                          'Select Variation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: displayVariations.map((variation) {
                            bool isSelected = selectedVariation == variation;
                            return GestureDetector(
                              onTap: () => setState(() => selectedVariation = variation),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? kPrimary : kBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? kPrimary : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  variationPriceMap.containsKey(variation)
                                      ? '$variation (RM${variationPriceMap[variation]!.toStringAsFixed(2)})'
                                      : variation,
                                  style: TextStyle(
                                    color: isSelected ? kWhite : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── BOTTOM BAR (ADD TO CART) ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: kWhite,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (quantity > 1) setState(() => quantity--);
                          },
                          child: Icon(Icons.remove_rounded, color: quantity > 1 ? kPrimary : Colors.grey.shade400, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => setState(() => quantity++),
                          child: const Icon(Icons.add_rounded, color: kPrimary, size: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isOwnStoreProduct) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You cannot buy from your own shop.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // 🚨 MAGIK TROLI BERMULA DI SINI 🚨
                        if (CartManager.instance.items.isNotEmpty &&
                            CartManager.instance.items.first.sellerId != widget.sellerId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You can only add items from the same store in one order.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        bool itemExists = false;
                        
                        // 1. Kita check dulu dalam troli, ada tak barang yg SAMA & PERISA yg SAMA
                        for (var item in CartManager.instance.items) {
                          if (item.name == widget.name && item.addons == selectedVariation) {
                            // Kalau ada, kita tambah kuantiti je! Tak payah buat kotak baru.
                            item.quantity += quantity;
                            itemExists = true;
                            break;
                          }
                        }

                        // 2. Kalau takde, baru kita cipta item baru dan masukkan dalam memori
                        if (!itemExists) {
                          CartManager.instance.addToCart(
                            CartItem(
                              productId: _resolvedProductId,
                              name: widget.name,
                              price: unitPrice,
                              deliveryFee: _productDeliveryFee,
                              imageUrl: widget.imageUrl,
                              sellerName: widget.sellerName,
                              sellerId: widget.sellerId,
                              addons: selectedVariation,
                              quantity: quantity,
                            )
                          );
                        } else {
                          // Update walkie-talkie (badge) kalau kita just update kuantiti
                          CartManager.instance.cartItemCount.value = CartManager.instance.items.length;
                        }

                        // 3. Tunjuk mesej berjaya kat bawah!
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $quantity ${widget.name} ($selectedVariation) to cart!'),
                            backgroundColor: kPrimary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        
                        // Tutup page ni dan balik ke senarai produk 
                        // (Boleh buang baris bawah ni kalau nak buyer stay kat page ni lepas add)
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: kWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add to Cart - RM${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: kWhite,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(icon, color: const Color(0xFF1A1A2E), size: 20),
      ),
    );
  }

  void _openFullScreenImage(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) {
        final fullScreenController = PageController(initialPage: initialIndex);
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: fullScreenController,
                      itemCount: displayImages.length,
                      onPageChanged: (index) => setDialogState(() => currentIndex = index),
                      itemBuilder: (_, index) {
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: Image.network(
                              displayImages[index],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white70,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 8,
                      left: 12,
                      child: _buildCircleButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1}/${displayImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }
}