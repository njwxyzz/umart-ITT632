import 'package:flutter/material.dart';
import 'add_product_page.dart';
import 'seller_orders_page.dart';

// ─── Color Constants ─────────────────────────────────────────────────────────
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: kWhite, size: 24),
          onPressed: () => Navigator.pop(context), // Balik ke Home (Buyer mode)
        ),
        title: const Text('My Store', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kWhite),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersPage()));
            },
          )
        ],
      ),
      body: Container(
        // BACKGROUND PATTERN
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05, 
          ),
        ),
        child: Column(
          children: [
            // ─── HEADER (Store Info & Stats) ───
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mak Cik Siti Nasi Lemak', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('📍 Kolej Dahlia 3, Bilik 204', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Kotak Statistik (Sales & Orders)
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Sales', 'RM 0.00', Icons.account_balance_wallet_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Active Orders', '0', Icons.receipt_long_rounded)),
                    ],
                  ),
                ],
              ),
            ),

            // ─── EMPTY STATE (Bahagian Tengah) ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_outlined, size: 80, color: kPrimary.withOpacity(0.3)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your store is empty!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start adding food or items to let other students order from your dorm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // BUTANG BESAR ADD PRODUCT
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Nanti kat sini kita buat page Add Product pulak
                          Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => const AddProductPage()),
                         );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, color: kWhite, size: 22),
                        label: const Text('Add Your First Product', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: kAccent.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET BANTUAN: Kotak Statistik
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimary, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}