import 'package:flutter/material.dart';
import 'cart_page.dart'; 
import 'cart_manager.dart'; // 🚨 IMPORT OTAK TROLI KAT SINI

const kPrimary      = Color(0xFF4C6B3F);
const kAccent       = Color(0xFFF27B35);
const kBg           = Color(0xFFF5F7F2);
const kWhite        = Colors.white;

class ProductDetailPage extends StatefulWidget {
  final String name;
  final double price;
  final String imageUrl;
  final double rating;
  final String sellerName;
  final String description;
  final List<String>? variations; 

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.sellerName,
    required this.description,
    this.variations, 
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  String selectedVariation = '';
  late List<String> displayVariations;

  @override
  void initState() {
    super.initState();
    displayVariations = (widget.variations != null && widget.variations!.isNotEmpty) 
        ? widget.variations! 
        : ['Standard', 'Matcha', 'Chocolate']; 

    if (displayVariations.isNotEmpty) {
      selectedVariation = displayVariations[0]; 
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.price * quantity;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: kPrimary.withOpacity(0.1),
                          child: const Icon(Icons.fastfood_rounded, size: 80, color: kPrimary),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            _buildCircleButton(
                              icon: Icons.shopping_cart_outlined,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Container(
                  transform: Matrix4.translationValues(0, -25, 0), 
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                            'RM${widget.price.toStringAsFixed(2)}',
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
                          const Icon(Icons.star_rounded, color: kAccent, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.storefront_rounded, color: Colors.grey.shade400, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Sold by ${widget.sellerName}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                      ),

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
                                variation,
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
                        // 🚨 MAGIK TROLI BERMULA DI SINI 🚨
                        
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
                              name: widget.name,
                              price: widget.price,
                              imageUrl: widget.imageUrl,
                              sellerName: widget.sellerName,
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
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kWhite, size: 20),
      ),
    );
  }
}