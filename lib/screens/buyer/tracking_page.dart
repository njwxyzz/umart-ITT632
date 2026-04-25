import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;
const kGreen        = Color(0xFF00C48C); // Hijau terang untuk tracking macam gambar

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Track Order', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. LIVE TRACKING MAP (PLACEHOLDER UNTUK GOOGLE MAPS) ───
            Container(
              height: 250, // Boleh adjust tinggi ni ikut kesesuaian design asal kau
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias, // Ni trik nak bagi bucu map tu bulat cantik
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.4497, 100.2704), // Koordinat ngam-ngam kat UiTM Arau, Perlis!
                  zoom: 15.0,
                ),
                myLocationEnabled: true, // Untuk tunjuk dot biru lokasi user nanti
                myLocationButtonEnabled: false, 
                zoomControlsEnabled: false, // Sorok butang +/- supaya design nampak clean
              ),
            ),
            const SizedBox(height: 24),

            // ─── 2. ORDER TIMELINE SECTION (MACAM GAMBAR KIRI) ───
            const Text('Order #UM-9824HGJF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 24),
            
            _buildTimelineStep(
              title: 'Order Placed',
              date: '10 Sep 2023, 04:25 PM',
              isCompleted: true,
              isLast: false,
              iconData: Icons.receipt_long_rounded,
            ),
            _buildTimelineStep(
              title: 'In Progress',
              date: '10 Sep 2023, 04:34 PM',
              isCompleted: true,
              isLast: false,
              iconData: Icons.inventory_2_outlined,
            ),
            _buildTimelineStep(
              title: 'Shipped',
              date: 'Expected 10 Sep 2023, 04:50 PM',
              isCompleted: true, // Warna hijau
              isLast: false,
              iconData: Icons.local_shipping_outlined,
            ),
            _buildTimelineStep(
              title: 'Delivered',
              date: '10 Sep 2023, 2023',
              isCompleted: false, // Kelabu sebab belum sampai
              isLast: true,
              iconData: Icons.check_box_outlined,
            ),

            const SizedBox(height: 32),

            // ─── 3. PRODUCTS SECTION ───
            const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            
            _buildProductCard(
              name: 'Cheese & Chocolate Cake',
              variant: 'Slice',
              price: 'RM 5.00',
              imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=200',
            ),
            const SizedBox(height: 12),
            _buildProductCard(
              name: 'Iced Latte',
              variant: 'Large',
              price: 'RM 6.50',
              imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=200',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── TIMELINE WIDGET ───
  Widget _buildTimelineStep({
    required String title,
    required String date,
    required bool isCompleted,
    required bool isLast,
    required IconData iconData,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kiri: Bulatan dan Garisan
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? kGreen : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isCompleted 
                  ? const Icon(Icons.check, color: kWhite, size: 14) 
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? kGreen : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Tengah: Teks (Title & Date)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600, 
                  color: isCompleted ? const Color(0xFF1A1A2E) : Colors.grey.shade500
                )
              ),
              const SizedBox(height: 4),
              Text(
                date, 
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)
              ),
              if (!isLast) const SizedBox(height: 24), // Spacing kalau bukan yang last
            ],
          ),
        ),

        // Kanan: Ikon kecil
        Icon(iconData, color: isCompleted ? kGreen : Colors.grey.shade400, size: 24),
      ],
    );
  }

  // ─── PRODUCT CARD WIDGET ───
  Widget _buildProductCard({
    required String name,
    required String variant,
    required String price,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl, width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: kPrimary.withOpacity(0.1), child: const Icon(Icons.image, color: kPrimary)),
            ),
          ),
          const SizedBox(width: 16),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(variant, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Text(price, style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}