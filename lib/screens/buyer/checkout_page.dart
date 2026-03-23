import 'package:flutter/material.dart';
import 'tracking_page.dart'; // Required to route to tracking page

// --- Color Constants ---
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
  // Track selected payment method ('COD' or 'ONLINE')
  String _selectedPayment = 'COD';

  // --- THE CUTE BOUNCING SUCCESS POPUP ---
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: kWhite,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouncing Animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut, 
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
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
                  color: kAccent,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        );
      }
    );

    // Wait 2.5 seconds, pop dialog, and push to Tracking Page
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pop(context); // Close Dialog
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TrackingPage()));
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
        title: const Text('Checkout', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 18)),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. DELIVERY ADDRESS SECTION ---
              _buildSectionTitle('Delivery Address'),
              _buildDeliveryCard(),
              const SizedBox(height: 30),

              // --- 2. PAYMENT METHOD SECTION ---
              _buildSectionTitle('Payment Method'),
              _buildPaymentOption(
                title: 'Cash on Delivery (COD)',
                subtitle: 'Pay the runner when food arrives',
                icon: Icons.payments_rounded,
                value: 'COD',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                title: 'Online Transfer / QR Pay',
                subtitle: 'Scan seller\'s QR code & upload receipt',
                icon: Icons.qr_code_scanner_rounded,
                value: 'ONLINE',
              ),
              
              // Animated Expansion for QR Code
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _selectedPayment == 'ONLINE' 
                  ? _buildQRPaySection()
                  : const SizedBox.shrink(),
              ),

              const SizedBox(height: 30),

              // --- 3. ORDER SUMMARY SECTION ---
              _buildSectionTitle('Order Summary'),
              _buildOrderSummaryCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      
      // --- 4. BOTTOM ACTION BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Payment', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('RM 11.50', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _showSuccessPopup, // TRIGGER THE BOUNCING POPUP
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: kPrimary.withOpacity(0.4),
                    ),
                    child: const Text('Place Order', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER METHODS FOR CLEANER CODE ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on_rounded, color: kAccent, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kolej Dahlia 3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                SizedBox(height: 4),
                Text('Block A, Room 204\n012-3456789 (Najwa)', style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {}, 
            child: const Text('Edit', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Premium Selectable Payment Card
  Widget _buildPaymentOption({required String title, required String subtitle, required IconData icon, required String value}) {
    final isSelected = _selectedPayment == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary.withOpacity(0.05) : kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kPrimary : Colors.transparent, width: 2),
          boxShadow: [
            if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kPrimary : Colors.grey.shade400, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? kPrimary : const Color(0xFF1A1A2E))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? kPrimary : Colors.grey.shade300, width: 2),
                color: isSelected ? kPrimary : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: kWhite) : null,
            )
          ],
        ),
      ),
    );
  }

  // QR Section that expands when 'ONLINE' is selected
  Widget _buildQRPaySection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text(
            'Please scan the seller\'s DuitNow QR:',
            style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file_rounded, color: kPrimary),
              label: const Text('Upload Receipt', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildOrderItem('1x Nasi Lemak Ayam Goreng', 'RM 8.50'),
          const SizedBox(height: 12),
          _buildOrderItem('1x Teh Tarik', 'RM 3.00'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const Text('Free', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _buildOrderItem('Subtotal', 'RM 11.50', isBold: true),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, String price, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: TextStyle(color: isBold ? const Color(0xFF1A1A2E) : Colors.black87, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text(price, style: TextStyle(color: const Color(0xFF1A1A2E), fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }
}