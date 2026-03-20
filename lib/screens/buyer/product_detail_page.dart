import 'package:flutter/material.dart';
import 'cart_page.dart';

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // State untuk Add-ons & Kuantiti
  int _quantity = 1;
  final double _basePrice = 12.50;
  
  bool _extraSambal = false;
  bool _addTelurMata = false;
  bool _extraRice = false;

  // Kira total harga (Base Price + Add-ons) * Kuantiti
  double get _totalPrice {
    double total = _basePrice;
    if (_extraSambal) total += 1.50;
    if (_addTelurMata) total += 2.00;
    if (_extraRice) total += 2.00;
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      // Bahagian Bawah (Bottom Bar) - Sticky Add To Cart
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
              // Quantity Selector
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
              // Add to Cart Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Tunjuk notification berjaya!
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
                    backgroundColor: kPrimary, // Butang Hijau Premium
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
      // Bahagian Body (Scrollable)
      body: CustomScrollView(
        slivers: [
          // Header Image (Gambar Besar)
          SliverAppBar(
            expandedHeight: 300, // Tinggi gambar
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
                'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800', // Gambar Nasi Lemak HD
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Bahagian Kandungan Bawah Gambar
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: kBg, // Kita pakai warna tema bg
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Corak pattern kat belakang text
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
                            // Nama Makanan
                            const Expanded(
                              child: Text(
                                'Nasi Lemak Ayam Berempah',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), height: 1.2),
                              ),
                            ),
                            // Harga Besar
                            Text(
                              'RM12.50',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kAccent), // Warna Oren
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Rating & Reviews
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: kAccent, size: 18),
                            const SizedBox(width: 4),
                            const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 6),
                            Text('(200+ reviews)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Deskripsi
                        Text(
                          'Our signature fragrant coconut milk rice served with spiced fried chicken, spicy house-made sambal, crispy anchovies, roasted peanuts, and a fresh hard-boiled egg on a traditional banana leaf.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bahagian Add-ons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customize Add-ons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 12),
                        
                        // Senarai Checkbox
                        _buildAddonTile('Extra Sambal', '+RM1.50', _extraSambal, (val) => setState(() => _extraSambal = val!)),
                        _buildAddonTile('Add Telur Mata (Fried Egg)', '+RM2.00', _addTelurMata, (val) => setState(() => _addTelurMata = val!)),
                        _buildAddonTile('Extra Rice', '+RM2.00', _extraRice, (val) => setState(() => _extraRice = val!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40), // Ruang kosong sikit kat bawah
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget bantuan untuk buat baris Checkbox nampak kemas
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