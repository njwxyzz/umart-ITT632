import 'package:flutter/material.dart';
import 'tracking_page.dart'; // Wajib import untuk lompat ke page tracking

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;
const kGreen        = Color(0xFF00C48C); 

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPayment = 'COD';

  // ─── FUNGSI MAGIK POPUP COMEL ───
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // User tak boleh tutup dengan klik luar kotak
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: kWhite,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animasi Melantun (Bouncing Pop)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut, // Ini yang buat dia melantun comel
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        // Ikon motor delivery
                        child: const Icon(Icons.moped_rounded, color: kPrimary, size: 60),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 24),
                const Text('Order Confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                Text('Getting your runner ready...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: kAccent, // Loading oren
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        );
      }
    );

    // Tunggu 2.5 saat, lepas tu tutup popup dan buka Tracking Page
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pop(context); // Tutup Dialog
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TrackingPage())); // Lompat ke Tracking!
    });
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DELIVERY ADDRESS SECTION
              const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, color: kAccent), 
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kolej Dahlia, Room 302', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                          SizedBox(height: 4),
                          Text('UiTM Perlis Branch', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {}, 
                      child: const Text('Edit', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)), 
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. PAYMENT METHOD SECTION
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontSize: 14)),
                      activeColor: kAccent, 
                      value: 'COD',
                      groupValue: _selectedPayment,
                      onChanged: (value) {
                        setState(() {
                          _selectedPayment = value!; 
                        });
                      },
                    ),
                    Divider(color: Colors.grey.shade100, height: 1),
                    RadioListTile<String>(
                      title: const Text('Online Transfer / QR Pay', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontSize: 14)),
                      activeColor: kAccent,
                      value: 'ONLINE',
                      groupValue: _selectedPayment,
                      onChanged: (value) {
                        setState(() {
                          _selectedPayment = value!;
                        });
                      },
                    ),
                    
                    if (_selectedPayment == 'ONLINE')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.03), 
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Sila imbas DuitNow QR penjual ini:',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Icon(Icons.qr_code_2, size: 100, color: Color(0xFF1A1A2E)),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.upload_file, color: kPrimary),
                              label: const Text('Upload Resit', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: kPrimary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. ORDER SUMMARY SECTION
              const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Items (2)', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const Text('RM11.50', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const Text('Free', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A2E))),
                        const Text('RM11.50', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: kAccent)), 
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
      
      // 4. BOTTOM ACTION BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kWhite,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showSuccessPopup, // <--- PANGGIL POPUP KAT SINI!
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: kWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}