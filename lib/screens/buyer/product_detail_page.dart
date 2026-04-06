import 'package:flutter/material.dart';
import 'cart_page.dart';

// ─── Color Constants ───────────────────────────────────────
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

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.sellerName, 
    required this.description, 
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  
  bool _extraSambal = false;
  bool _addTelurMata = false;
  bool _extraRice = false;

  double get _totalPrice {
    double total = widget.price; 
    if (_extraSambal) total += 1.50;
    if (_addTelurMata) total += 2.00;
    if (_extraRice) total += 2.00;
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    // MAGIK: Check kalau nama barang ada perkataan "nasi lemak"
    bool isNasiLemak = widget.name.toLowerCase().contains('nasi lemak');

    return Scaffold(
      backgroundColor: kBg,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: kWhite,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: _quantity > 1 ? const Color(0xFF1A1A2E) : Colors.grey),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF1A1A2E)),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Added to cart! 🛒'),
                        backgroundColor: kPrimary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, 
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add to Cart - RM${_totalPrice.toStringAsFixed(2)}', 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, 
            pinned: true,
            backgroundColor: kPrimary,
            iconTheme: const IconThemeData(color: kWhite),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: kWhite),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20, color: kWhite),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.imageUrl, 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: kBg, 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.name, 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), height: 1.2),
                              ),
                            ),
                            Text(
                              'RM${widget.price.toStringAsFixed(2)}', 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kAccent), 
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: kAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(widget.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
                            const SizedBox(width: 8),
                            // --- NAMA SELLER KAT SINI ---
                            Icon(Icons.storefront_rounded, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Sold by ${widget.sellerName}', 
                                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // --- DESCRIPTION DARI FIREBASE KAT SINI ---
                        Text(
                          widget.description, 
                          style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // KOTAK ADD-ONS (Hanya keluar kalau makanan tu Nasi Lemak)
                  if (isNasiLemak)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customize Add-ons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 12),
                          
                          _buildAddonTile('Extra Sambal', '+RM1.50', _extraSambal, (val) => setState(() => _extraSambal = val!)),
                          _buildAddonTile('Add Telur Mata (Fried Egg)', '+RM2.00', _addTelurMata, (val) => setState(() => _addTelurMata = val!)),
                          _buildAddonTile('Extra Rice', '+RM2.00', _extraRice, (val) => setState(() => _extraRice = val!)),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonTile(String title, String price, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? kPrimary : Colors.grey.shade200, width: 1.5),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: kPrimary,
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        secondary: Text(price, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}