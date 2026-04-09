import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; // 🚨 IMPORT BARU UNTUK CHAT
import 'package:firebase_auth/firebase_auth.dart'; // 🚨 IMPORT BARU UNTUK CHAT
import 'cart_page.dart'; 
import 'product_detail_page.dart'; 
import 'chat_page.dart'; // 🚨 IMPORT BARU UNTUK BUKA BILIK CHAT

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kPrimaryLight = Color(0xFF799B61); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class AllProductPage extends StatelessWidget {
  final String title; 
  final List items;  

  const AllProductPage({super.key, required this.title, required this.items}); 

  @override
  Widget build(BuildContext context) { 
    return Scaffold( 
      backgroundColor: kBg, 
      appBar: AppBar( 
        backgroundColor: kBg,
        elevation: 0, 
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)), 
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 24),
            color: const Color(0xFF1A1A2E),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'), 
            repeat: ImageRepeat.repeat,
            opacity: 0.05, 
          ),
        ),
        child: items.isEmpty 
            ? Center( 
                child: Column( 
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [ 
                    Icon(Icons.inventory_2_outlined, size: 60, color: kPrimary.withOpacity(0.3)), 
                    const SizedBox(height: 16), 
                    Text('No products available for $title', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)), 
                  ],
                ),
              )
            : Padding( 
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), 
                child: GridView.builder (
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( 
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,  
                    crossAxisSpacing: 12,   
                    childAspectRatio: 0.72,   
                  ),
                  itemCount: items.length,    
                  itemBuilder: (context, index) {   
                    final item = items[index];  
                    return _ProductCard(   
                      title: item.label,  
                      price: item.price,
                      rating: item.rating,
                      sellerName: item.sellerName,
                      sellerId: item.sellerId, // 🚨 KITA PASS ID SELLER UNTUK CHAT
                      badge: item.badge,
                      badgeColor: item.badgeColor,
                      imageUrl: item.imageUrl,
                      description: item.description,
                    );
                  },
                )
              ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget { 
  final String title; 
  final double price; 
  final double rating; 
  final String sellerName; 
  final String sellerId; // 🚨 VARIABLE BARU UNTUK CHAT
  final String? badge; 
  final Color? badgeColor; 
  final String imageUrl; 
  final String description;

  const _ProductCard({
    required this.title, 
    required this.price, 
    required this.rating, 
    required this.sellerName, 
    required this.sellerId, // 🚨 WAJIB ADA
    this.badge, 
    this.badgeColor, 
    required this.imageUrl,
    required this.description,
  }); 

  @override
  Widget build(BuildContext context) { 
    
    // --- FUNGSI BUKA DETAIL PAGE ---
    void openProductDetail() {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(
        name: title,        
        price: price,       
        imageUrl: imageUrl, 
        rating: rating,     
        sellerName: sellerName, 
        description: description, 
      )));
    }

    // --- FUNGSI BUKA CHAT SELLER ---
    Future<void> openChatSeller() async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first to start chat.')),
        );
        return;
      }
      
      String targetSellerId = sellerId;

      if (targetSellerId.isEmpty) {
        final storeQuery = await FirebaseFirestore.instance
            .collection('stores')
            .where('storeName', isEqualTo: sellerName)
            .limit(1)
            .get();
        if (storeQuery.docs.isNotEmpty) {
          targetSellerId = storeQuery.docs.first.id; 
        }
      }

      if (targetSellerId.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller account not found. Please try another product.')),
        );
        return;
      }

      if (targetSellerId == currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own product.')),
        );
        return;
      }

      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final existing = await chatsRef.where('participants', arrayContains: currentUser.uid).get();

      String? chatId;
      for (final doc in existing.docs) {
        final data = doc.data();
        final participantsRaw = (data['participants'] as List?) ?? [];
        final participants = participantsRaw.whereType<String>().toList();
        if (participants.contains(targetSellerId)) {
          chatId = doc.id;
          break;
        }
      }

      if (chatId == null) {
        final newDoc = await chatsRef.add({
          'participants': [currentUser.uid, targetSellerId],
          'participantNames': {
            currentUser.uid: currentUser.displayName ?? 'Buyer',
            targetSellerId: sellerName,
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

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            runnerName: sellerName,
            chatId: chatId,
            otherUserId: targetSellerId,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // 🚨 KITA KELUARKAN BOTTOM SHEET SEJIBIK MACAM KAT HOME PAGE
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (sheetContext) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sold by $sellerName',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext); // Tutup pop-up
                            openProductDetail(); // Buka detail
                          },
                          icon: const Icon(Icons.info_outline_rounded, size: 18),
                          label: const Text('View Product'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimary,
                            side: const BorderSide(color: kPrimary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext); // Tutup pop-up
                            openChatSeller(); // Masuk bilik chat
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat Seller'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: kWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container( 
        decoration: BoxDecoration( 
          color: kWhite,
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [ 
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.hardEdge, 
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 120,
                      width: double.infinity, 
                      child: Image.network( 
                        imageUrl, 
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container( 
                          color: kPrimary.withOpacity(0.1), 
                          child: const Icon(Icons.shopping_bag_outlined, size: 40, color: kPrimary),
                        ),
                      ),
                    ),
                    if (badge != null) 
                      Positioned( 
                        top: 8,
                        left: 8,
                        child: Container( 
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                          decoration: BoxDecoration(
                            color: badgeColor ?? kAccent, 
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded( 
                  child: Padding(
                    padding: const EdgeInsets.all(10), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('RM${price.toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w800, fontSize: 13)), 
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: kAccent, size: 14), 
                                    const SizedBox(width: 3),
                                    Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.storefront_rounded, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(child: Text(sellerName, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(
                  color: kPrimary, 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ]
                ),
                child: const Icon(Icons.add, color: kWhite, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}