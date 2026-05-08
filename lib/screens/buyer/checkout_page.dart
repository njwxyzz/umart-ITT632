import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // MESTI ADA!
import 'package:firebase_auth/firebase_auth.dart'; // MESTI ADA!
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'tracking_page.dart'; 
import 'cart_manager.dart'; 

// --- Color Constants ---
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;
const kGreen        = Color(0xFF00C48C); 

/// Campus kolej pin (UiTM Perlis Arau area). Adjust lat/lng to match your GIS basemap.
class KolejOption {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const KolejOption({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

/// Placeholder coordinates around campus; replace with official points if you have them.
const List<KolejOption> kUiTMPerlisKolej = [
  KolejOption(id: 'dahlia', name: 'Kolej Dahlia', lat: 6.4438, lng: 100.2798),
  KolejOption(id: 'mawar', name: 'Kolej Mawar', lat: 6.4442, lng: 100.2812),
  KolejOption(id: 'cempaka', name: 'Kolej Cempaka', lat: 6.4426, lng: 100.2820),
  KolejOption(id: 'melati', name: 'Kolej Melati', lat: 6.4420, lng: 100.2795),
  KolejOption(id: 'kenanga', name: 'Kolej Kenanga', lat: 6.4445, lng: 100.2830),
  KolejOption(id: 'sakura', name: 'Kolej Sakura', lat: 6.4414, lng: 100.2810),
];

class CheckoutPage extends StatefulWidget {
  final String note; // KITA TANGKAP NOTA DARI CART PAGE
  
  const CheckoutPage({super.key, required this.note});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Track selected payment method ('COD' or 'ONLINE')
  String _selectedPayment = 'COD';
  String? _sellerPaymentQrUrl;
  bool _isFetchingSellerPaymentQr = true;
  Uint8List? _receiptBytes;
  String? _receiptUrl;
  bool _isUploadingReceipt = false;
  bool _isSavingQr = false;
  final ImagePicker _picker = ImagePicker();

  KolejOption _selectedKolej = kUiTMPerlisKolej.first;
  final TextEditingController _deliveryDetailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSellerPaymentQr();
  }

  Future<void> _loadSellerPaymentQr() async {
    if (_items.isEmpty) {
      setState(() => _isFetchingSellerPaymentQr = false);
      return;
    }
    try {
      final sellerIdFromItem = _items.first.sellerId;
      DocumentSnapshot<Map<String, dynamic>>? storeDoc;
      if (sellerIdFromItem.trim().isNotEmpty) {
        storeDoc = await FirebaseFirestore.instance.collection('stores').doc(sellerIdFromItem).get();
      }
      if (storeDoc == null || !storeDoc.exists) {
        final byName = await FirebaseFirestore.instance
            .collection('stores')
            .where('storeName', isEqualTo: _items.first.sellerName)
            .limit(1)
            .get();
        if (byName.docs.isNotEmpty) {
          storeDoc = byName.docs.first;
        }
      }
      if (!mounted) return;
      setState(() {
        _sellerPaymentQrUrl = storeDoc?.data()?['paymentQrUrl'] as String?;
      });
    } catch (_) {
      // Silent fail and keep empty state.
    } finally {
      if (mounted) setState(() => _isFetchingSellerPaymentQr = false);
    }
  }

  Future<void> _saveQrToPhone() async {
    if (_sellerPaymentQrUrl == null || _sellerPaymentQrUrl!.isEmpty) return;
    setState(() => _isSavingQr = true);
    try {
      final byteData = await NetworkAssetBundle(Uri.parse(_sellerPaymentQrUrl!)).load(_sellerPaymentQrUrl!);
      final bytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'umart_seller_qr_${DateTime.now().millisecondsSinceEpoch}',
      );
      final success = result['isSuccess'] == true || result['isSuccess'] == 1;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'QR saved to gallery.' : 'Could not save QR to gallery.'),
          backgroundColor: success ? kPrimary : Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save QR image.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSavingQr = false);
    }
  }

  Future<void> _uploadReceipt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _isUploadingReceipt = true;
      });

      final ref = FirebaseStorage.instance.ref().child(
        'payment_receipts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final snap = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await snap.ref.getDownloadURL();

      if (!mounted) return;
      setState(() => _receiptUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt uploaded successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt upload failed.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingReceipt = false);
    }
  }

  @override
  void dispose() {
    _deliveryDetailController.dispose();
    super.dispose();
  }

  // --- AMBIL DATA DARI CART MANAGER ---
  List<CartItem> get _items => CartManager.instance.items;
  double get _subtotal => CartManager.instance.totalPrice;
  double get _deliveryFee => _subtotal >= 15.0 ? 0.0 : 3.00; 
  double get _total => _subtotal + _deliveryFee;

  String get _composedBuyerLocation {
    final detail = _deliveryDetailController.text.trim();
    if (detail.isEmpty) return _selectedKolej.name;
    return '${_selectedKolej.name} — $detail';
  }

  // --- THE MATCHMAKER: FUNGSI HANTAR ORDER KE FIREBASE ---
  Future<void> _processOrder() async {
    if (_items.isEmpty) return;

    final detail = _deliveryDetailController.text.trim();
    if (detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add room number or drop-off detail (e.g. At lobby).')),
      );
      return;
    }
    if (_selectedPayment == 'ONLINE' && (_sellerPaymentQrUrl == null || _sellerPaymentQrUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller has not uploaded a payment QR yet.')),
      );
      return;
    }
    if (_selectedPayment == 'ONLINE' && (_receiptUrl == null || _receiptUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload payment receipt before placing order.')),
      );
      return;
    }

    // 1. Tunjuk loading spinner
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: kAccent)));

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Please login first!");

      // 🚨 TARIK PROFIL SEBENAR PEMBELI 🚨
      String realBuyerName = 'UMART Student'; // Fallback kalau takde nama
      try {
        var userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          // Ambil fullName, kalau takde, kita potong e-mel dia ambil nama depan je
          realBuyerName = userDoc.data()?['fullName'] ?? currentUser.email?.split('@')[0] ?? 'UMART Student';
        } else {
          // Kalau dia tak pernah setup profile, pakai nama depan emel (contoh: najwa dari najwa@student...)
          realBuyerName = currentUser.email?.split('@')[0].toUpperCase() ?? 'UMART Student';
        }
      } catch (e) {
        print("Gagal tarik nama profil: $e");
      }

      // 2. Kita kena cari IC (UID) Seller berdasarkan nama kedai
      String sellerName = _items.first.sellerName;
      String targetSellerId = "";
      
      var storeQuery = await FirebaseFirestore.instance.collection('stores').where('storeName', isEqualTo: sellerName).get();
      if (storeQuery.docs.isNotEmpty) {
        targetSellerId = storeQuery.docs.first.id; // Ini IC sebenar seller tu!
      } else {
        targetSellerId = "UNKNOWN_SELLER"; // Kalau kedai hantu
      }

      if (targetSellerId == currentUser.uid) {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot place order from your own shop.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Susun nama barang cantik-cantik untuk order
      String allItemsString = _items.map((e) => '${e.quantity}x ${e.name}').join(', ');
      final structuredItems = _items
          .map((e) => {
                'productId': e.productId,
                'name': e.name,
                'quantity': e.quantity,
                'unitPrice': e.price,
                'lineTotal': e.price * e.quantity,
                'sellerId': e.sellerId,
                'sellerName': e.sellerName,
                'addons': e.addons,
              })
          .toList();

      // 3. Tembak masuk laci 'orders' kat Firebase!
      final docRef = await FirebaseFirestore.instance.collection('orders').add({
        'buyerId': currentUser.uid,
        'buyerName': realBuyerName, // <--- NAMA SEBENAR DAH MASUK SINI! 💅
        'buyerLocation': _composedBuyerLocation,
        'kolejId': _selectedKolej.id,
        'kolejName': _selectedKolej.name,
        'deliveryDetail': detail,
        'buyerLat': _selectedKolej.lat,
        'buyerLng': _selectedKolej.lng,
        'sellerId': targetSellerId,
        'sellerName': sellerName,
        'productName': allItemsString,
        'items': structuredItems,
        'totalPrice': _total,
        'status': 'Pending',
        'note': widget.note, // Nota tak nak taugeh
        'paymentMethod': _selectedPayment,
        'sellerPaymentQrUrl': _selectedPayment == 'ONLINE' ? _sellerPaymentQrUrl : null,
        'paymentReceiptUrl': _selectedPayment == 'ONLINE' ? _receiptUrl : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Tutup loading spinner
      if (context.mounted) Navigator.pop(context);

      // 5. Tunjuk Bouncing Success Popup kau yang lawa tu!
      _showSuccessPopup(docRef.id);

    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Tutup loading kalau error
      print("Error buat order: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
    }
  }

  // --- THE CUTE BOUNCING SUCCESS POPUP ---
  void _showSuccessPopup(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false, 
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

    // Wait 2.5 seconds, clear cart, pop dialog, and push to Tracking Page
    Future.delayed(const Duration(milliseconds: 2500), () {
      CartManager.instance.clearCart(); // KOSONGKAN TROLI
      Navigator.pop(context); // Close Dialog
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TrackingPage(orderId: orderId)));
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
                subtitle: 'Scan seller QR, save QR, then upload receipt',
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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Payment', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('RM ${_total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    // 🚨 PANGGIL FUNGSI FIREBASE KITA BILA DITEKAN 🚨
                    onPressed: _items.isEmpty ? null : _processOrder, 
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.school_rounded, color: kAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deliver to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<KolejOption>(
                      value: _selectedKolej,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: kBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                      items: kUiTMPerlisKolej
                          .map((k) => DropdownMenuItem<KolejOption>(value: k, child: Text(k.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (k) {
                        if (k == null) return;
                        setState(() => _selectedKolej = k);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Room / meeting point',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _deliveryDetailController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'e.g. Block A Room 302, or At lobby',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_rounded, size: 16, color: kPrimary.withOpacity(0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Map pin: ${_selectedKolej.name} (UiTM)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
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
            'Seller payment QR:',
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
            clipBehavior: Clip.hardEdge,
            child: _isFetchingSellerPaymentQr
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : (_sellerPaymentQrUrl != null && _sellerPaymentQrUrl!.isNotEmpty)
                    ? Image.network(
                        _sellerPaymentQrUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF1A1A2E)),
                      )
                    : const Icon(Icons.qr_code_2_rounded, size: 120, color: Color(0xFF1A1A2E)),
          ),
          if (_receiptBytes != null) ...[
            const SizedBox(height: 14),
            Container(
              width: 110,
              height: 110,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_sellerPaymentQrUrl == null || _sellerPaymentQrUrl!.isEmpty || _isSavingQr)
                      ? null
                      : _saveQrToPhone,
                  icon: _isSavingQr
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                        )
                      : const Icon(Icons.download_rounded, color: kPrimary),
                  label: const Text('Save QR', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploadingReceipt ? null : _uploadReceipt,
                  icon: _isUploadingReceipt
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                        )
                      : const Icon(Icons.upload_file_rounded, color: kPrimary),
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
          if (!_isFetchingSellerPaymentQr && (_sellerPaymentQrUrl == null || _sellerPaymentQrUrl!.isEmpty)) ...[
            const SizedBox(height: 10),
            Text(
              'Seller QR is not available yet. Please choose COD or contact seller.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (_sellerPaymentQrUrl != null && _sellerPaymentQrUrl!.isNotEmpty && (_receiptUrl == null || _receiptUrl!.isEmpty)) ...[
            const SizedBox(height: 8),
            Text(
              'Upload payment receipt to continue placing order.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
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
          // LIVE ITEMS LOOPING
          if (_items.isEmpty)
            const Text("No items in cart", style: TextStyle(color: Colors.grey))
          else
            ..._items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderItem('${item.quantity}x ${item.name}', 'RM ${(item.price * item.quantity).toStringAsFixed(2)}'),
            )),
            
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFEEEEEE), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              Text(
                _deliveryFee == 0 ? 'Free' : 'RM ${_deliveryFee.toStringAsFixed(2)}', 
                style: TextStyle(color: _deliveryFee == 0 ? kGreen : const Color(0xFF1A1A2E), fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOrderItem('Total', 'RM ${_total.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String name, String price, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name, 
            style: TextStyle(color: isBold ? const Color(0xFF1A1A2E) : Colors.black87, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(price, style: TextStyle(color: const Color(0xFF1A1A2E), fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }
}