import 'package:flutter/material.dart';
import 'checkout_page.dart';

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); // Olive Green
const kPrimaryLight = Color(0xFF799B61); // Lighter Olive
const kAccent       = Color(0xFFF27B35); // Oren Lembut
const kBg           = Color(0xFFF5F7F2); // Off-white hijau
const kWhite        = Colors.white;
const kGreen        = Color(0xFF00C48C); // Kekalkan untuk 'Free Delivery'

// ─── Cart Page ───────────────────────────────────────────────────────────────

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartItemData {
  final String id;
  final String name;
  final double price;
  int quantity;

  _CartItemData({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class _CartPageState extends State<CartPage> {
  static const double _freeDeliveryThreshold = 15.0;
  static const double _deliveryFee = 0.0;

  late List<_CartItemData> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      _CartItemData(id: 'nasi_lemak', name: 'Nasi Lemak Ayam', price: 8.50, quantity: 1),
      _CartItemData(id: 'iced_milo', name: 'Iced Milo', price: 3.00, quantity: 1),
    ];
  }

  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  double get _total => _subtotal + _deliveryFee;
  double get _amountNeededForFreeDelivery =>
      (_freeDeliveryThreshold - _subtotal).clamp(0.0, double.infinity);
  double get _freeDeliveryProgress =>
      (_subtotal / _freeDeliveryThreshold).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.black87,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      // MAGIK BACKGROUND PATTERN .JPG KAT SINI!
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SellerHeaderCard(
                    shopName: 'Mak Cik Nasi Lemak',
                    location: 'Kolej Dahlia',
                  ),
                  const SizedBox(height: 16),
                  _FreeDeliveryProgress(
                    amountNeeded: _amountNeededForFreeDelivery,
                    progress: _freeDeliveryProgress,
                  ),
                  const SizedBox(height: 20),
                  ..._items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935), // Warna merah standard untuk delete
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: kWhite,
                              size: 28,
                            ),
                          ),
                          onDismissed: (_) {
                            setState(() => _items.removeWhere((e) => e.id == item.id));
                          },
                          child: _CartItem(
                            name: item.name,
                            price: item.price,
                            quantity: item.quantity,
                            onDecrement: () {
                              if (item.quantity > 1) {
                                setState(() => item.quantity--);
                              }
                            },
                            onIncrement: () => setState(() => item.quantity++),
                          ),
                        ),
                      )),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline, size: 18, color: kPrimary),
                    label: const Text(
                      'Add more items from this shop',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StudentRemarksBox(),
                  const SizedBox(height: 20),
                  _OrderSummary(
                    subtotal: _subtotal,
                    deliveryFee: _deliveryFee,
                    total: _total,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomCheckoutBar(
                onProceed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CheckoutPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Free Delivery Progress Bar ─────────────────────────────────────────────

class _FreeDeliveryProgress extends StatelessWidget {
  final double amountNeeded;
  final double progress;

  const _FreeDeliveryProgress({
    required this.amountNeeded,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (amountNeeded <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🚚 ', style: TextStyle(fontSize: 16, color: kGreen)),
            const Text(
              "You've unlocked FREE delivery!",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: kGreen,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add RM${amountNeeded.toStringAsFixed(2)} more to unlock 🚚 FREE Delivery!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(kAccent), // Guna warna Oren
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Student Remarks Box ─────────────────────────────────────────────────────

class _StudentRemarksBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: '✍️ Add a note for seller (e.g., Sambal lebih, taknak taugeh pls 🙅‍♀️)',
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: kWhite.withOpacity(0.8), // Guna warna putih dengan opacity
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.5), // Guna hijau bila klik
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Seller Header Card ─────────────────────────────────────────────────────

class _SellerHeaderCard extends StatelessWidget {
  final String shopName;
  final String location;

  const _SellerHeaderCard({
    required this.shopName,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1), // Hijau Pudar
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 22), // Ikon Hijau
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('📍 ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart Item Row ───────────────────────────────────────────────────────────

class _CartItem extends StatelessWidget {
  final String name;
  final double price;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1), // Hijau pudar
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_rounded, color: kPrimary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: kAccent, // Warna oren untuk harga
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                _QuantitySelector(
                  value: quantity,
                  onDecrement: onDecrement,
                  onIncrement: onIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quantity Selector (pill) ───────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Icon(Icons.remove_rounded, size: 18, color: Colors.grey[700]),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Icon(Icons.add_rounded, size: 18, color: Colors.grey[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Summary ────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;

  const _OrderSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Subtotal', value: 'RM${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Delivery Fee',
            value: deliveryFee == 0 ? 'Free' : 'RM${deliveryFee.toStringAsFixed(2)}',
            valueColor: deliveryFee == 0 ? kGreen : null,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payment',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'RM${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: kPrimary, // Guna Hijau Utama supaya nampak legit
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom Checkout Bar ──────────────────────────────────────────────────────

class _BottomCheckoutBar extends StatelessWidget {
  final VoidCallback onProceed;

  const _BottomCheckoutBar({required this.onProceed});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, // Butang Checkout Hijau Premium
              foregroundColor: kWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            child: const Text('Proceed to Checkout'),
          ),
        ),
      ),
    );
  }
}