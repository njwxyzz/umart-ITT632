import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders_page.dart'; 
import 'chat_page.dart'; // 🚨 PANGGIL PAGE CHAT KITA

// ─── Color Constants ─────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

// ─── Order Detail Page ────────────────────────────────────────────────────────
class OrderDetailPage extends StatelessWidget {
  final OrderHistory order; 

  const OrderDetailPage({super.key, required this.order});

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // 🚨 MAGIK BUKA BILIK CHAT SEBELUM JUMPA SELLER 🚨
  Future<void> _openChatSeller(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to start chat.')),
      );
      return;
    }

    // Tunjuk bulatan loading kejap
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: kPrimary)),
    );

    try {
      String targetSellerId = "";

      // 1. Cari IC Seller pakai nama kedai dia
      final storeQuery = await FirebaseFirestore.instance
          .collection('stores')
          .where('storeName', isEqualTo: order.sellerName)
          .limit(1)
          .get();
          
      if (storeQuery.docs.isNotEmpty) {
        targetSellerId = storeQuery.docs.first.id; 
      }

      if (targetSellerId.isEmpty) {
        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller account not found. Cannot start chat.')),
        );
        return;
      }

      if (targetSellerId == currentUser.uid) {
        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own store order!')),
        );
        return;
      }

      // 2. Selongkar laci 'chats' tengok dah pernah sembang ke belum
      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final existing = await chatsRef
          .where('participants', arrayContains: currentUser.uid)
          .get();

      String? chatId;
      for (final doc in existing.docs) {
        final data = doc.data();
        final participantsRaw = (data['participants'] as List?) ?? [];
        final participants = participantsRaw.whereType<String>().toList();
        if (participants.contains(targetSellerId)) {
          chatId = doc.id; // Dah pernah chat, guna ID lama
          break;
        }
      }

      // 3. Kalau tak jumpa, kita buat bilik chat baru kat laci
      if (chatId == null) {
        final newDoc = await chatsRef.add({
          'participants': [currentUser.uid, targetSellerId],
          'participantNames': {
            currentUser.uid: currentUser.displayName ?? 'Buyer',
            targetSellerId: order.sellerName,
          },
          'participantRoles': {
            currentUser.uid: 'Buyer',
            targetSellerId: 'Seller',
          },
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            currentUser.uid: 0,
            targetSellerId: 0,
          },
        });
        chatId = newDoc.id;
      }

      // 4. Terus meroket ke ChatPage!
      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            runnerName: order.sellerName,
            chatId: chatId,
            otherUserId: targetSellerId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); 
      print("Error chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBg,
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
              padding: EdgeInsets.only(bottom: 100 + bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroHeader(context, topPad),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderMeta(),
                        const SizedBox(height: 14),
                        _buildSellerCard(),
                        const SizedBox(height: 14),
                        _buildRouteCard(),
                        const SizedBox(height: 14),
                        _buildOrderSummary(),
                        const SizedBox(height: 14),
                        _buildPriceBreakdown(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Floating Contact Button
            Positioned(
              left: 16, right: 16, bottom: bottomPad > 0 ? bottomPad : 16,
              child: _buildContactButton(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, double topPad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context), 
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1A1A2E))),
              ),
              const SizedBox(width: 12),
              const Text('Order Detail', style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [const Icon(Icons.check_circle_rounded, color: kPrimary, size: 13), const SizedBox(width: 4), Text(order.status, style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700))]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(order.itemName, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2)),
          const SizedBox(height: 4),
          Text('from ${order.sellerName}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  // ── Order Meta ─────────────────────────────────────────────────────────────
  Widget _buildOrderMeta() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(
        children: [
          _MetaChip(icon: Icons.tag_rounded, label: 'Order ID', value: order.orderId.substring(0, 5).toUpperCase(), color: kPrimary),
          const SizedBox(width: 10),
          _MetaChip(icon: Icons.calendar_today_rounded, label: 'Date', value: _formatDate(order.dateTime), color: kAccent),
          const SizedBox(width: 10),
          _MetaChip(icon: Icons.access_time_rounded, label: 'Time', value: _formatTime(order.dateTime), color: kPrimaryLight),
        ],
      ),
    );
  }

  // ── Seller Card ────────────────────────────────────────────────────────────
  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Seller Info', icon: Icons.storefront_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 60, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: kBg),
                clipBehavior: Clip.hardEdge,
                child: Image.network(order.sellerPhoto, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kPrimary.withOpacity(0.1), child: const Icon(Icons.person_rounded, color: kPrimary, size: 30))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.sellerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: kAccent),
                        const SizedBox(width: 3),
                        Expanded(child: Text(order.sellerAddress, style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [const Icon(Icons.star_rounded, color: kAccent, size: 12), const SizedBox(width: 3), Text(order.sellerRating.toStringAsFixed(1), style: const TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w700))]),
                        ),
                        const SizedBox(width: 6),
                        Text('(${order.sellerReviews} reviews)', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Route Card ─────────────────────────────────────────────────────────────
  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Delivery Route', icon: Icons.route_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
                  Container(width: 2, height: 36, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kPrimary, kAccent]))),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: kPrimary),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('From', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w600)), Text(order.sellerLocation, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13, fontWeight: FontWeight.w600))])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.home_rounded, size: 14, color: kAccent),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('To', style: TextStyle(color: kAccent, fontSize: 10, fontWeight: FontWeight.w600)), Text(order.buyerLocation, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13, fontWeight: FontWeight.w600))])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Order Summary ──────────────────────────────────────────────────────────
  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Order Summary', icon: Icons.receipt_long_rounded),
          const SizedBox(height: 14),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(width: 28, height: 28, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text('×${item.qty}', style: const TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500))),
                    Text('RM ${(item.price * item.qty).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Price Breakdown ────────────────────────────────────────────────────────
  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(
        children: [
          const _SectionTitle(title: 'Payment Summary', icon: Icons.payments_rounded),
          const SizedBox(height: 14),
          _PriceRow(label: 'Subtotal', value: order.subtotal),
          const SizedBox(height: 8),
          _PriceRow(label: 'Delivery Fee', value: order.deliveryFee, valueColor: kAccent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [Expanded(child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.grey.withOpacity(0.2), Colors.transparent]))))]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              Text('RM ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contact Button ─────────────────────────────────────────────────────────
  Widget _buildContactButton(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPrimary, Color(0xFF3A5230)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openChatSeller(context), // PANGGIL MAGIK KAT SINI!
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.chat_bubble_rounded, color: kWhite, size: 18),
              SizedBox(width: 10),
              Text('Contact Seller', style: TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small Reusable Widgets ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: kPrimary)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text('RM ${value.toStringAsFixed(2)}', style: TextStyle(color: valueColor ?? const Color(0xFF1A1A2E), fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}