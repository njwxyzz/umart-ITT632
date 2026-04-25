import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SellerOrderDetailsPage extends StatelessWidget {
  // Nanti bila nak sambung Firebase, kita pass ID order atau data order masuk sini
  // Buat masa ni kita guna dummy data dulu untuk tengok UI.
  final String orderId = "#UM-XWGME";
  final String buyerName = "aminah";
  final String address = "Kolej Dahlia 3, Block A";
  final String phone = "012-3456789"; 

  const SellerOrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Details', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. PETA LOKASI BUYER ───
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(6.4497, 100.2704), // Koordinat UiTM Arau
                  zoom: 16.0,
                ),
                markers: {
                  const Marker(
                    markerId: MarkerId('buyer_location'),
                    position: LatLng(6.4497, 100.2704),
                    infoWindow: InfoWindow(title: 'Lokasi Buyer (Kolej Dahlia)'),
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),

            // ─── 2. MAKLUMAT PEMBELI ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order $orderId', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 16),
                  
                  // Kotak Info Buyer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Color(0xFFF27B35)),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Ikon Call (Nampak legit sikit ada button call runner/buyer)
                        IconButton(
                          icon: const Icon(Icons.call, color: Color(0xFF00C48C)),
                          onPressed: () {
                            // Fungsi call nanti
                          },
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // ─── 3. SENARAI BARANG ───
                  const Text('Items Ordered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('1x CHEESE & CHOCOLATE CAKE', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('RM 8.00', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // ─── 4. BUTANG MARK AS DELIVERED KAT BAWAH SEKALI ───
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27B35), // Warna Oren
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Nanti letak fungsi update Firebase status 'Delivered'
              Navigator.pop(context);
            },
            child: const Text('Mark as Delivered', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}