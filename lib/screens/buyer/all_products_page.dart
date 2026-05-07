import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'cart_page.dart'; 
import 'product_detail_page.dart'; 
import 'chat_page.dart'; 

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
            // 🚨 TUKAR DARI GRIDVIEW KE LISTVIEW 🚨
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14), // Jarak antara kad
                itemBuilder: (context, index) {   
                  final item = items[index];  
                  return _ProductListCard(   
                    productId: item.productId,
                    title: item.label,  
                    price: item.price,
                    soldCount: item.soldCount,
                    sellerName: item.sellerName,
                    sellerId: item.sellerId, 
                    badge: item.badge,
                    badgeColor: item.badgeColor,
                    imageUrl: item.imageUrl,
                    description: item.description,
                  );
                },
              ),
      ),
    );
  }
}

// 🚨 DESIGN KAD BARU (MELINTANG MACAM REFERENCE) 🚨
class _ProductListCard extends StatelessWidget { 
  final String productId;
  final String title; 
  final double price; 
  final int soldCount; 
  final String sellerName; 
  final String sellerId; 
  final String? badge; 
  final Color? badgeColor; 
  final String imageUrl; 
  final String description;

  const _ProductListCard({
    required this.productId,
    required this.title, 
    required this.price, 
    required this.soldCount, 
    required this.sellerName, 
    required this.sellerId, 
    this.badge, 
    this.badgeColor, 
    required this.imageUrl,
    required this.description,
  }); 

  @override
  Widget build(BuildContext context) { 
    
    void openProductDetail() {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(
        productId: productId,
        name: title,        
        price: price,       
        imageUrl: imageUrl, 
        sellerId: sellerId,
        sellerName: sellerName, 
        description: description, 
      )));
    }

    Future<void> openChatSeller() async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first to start chat.')));
        return;
      }
      
      String targetSellerId = sellerId;

      if (targetSellerId.isEmpty) {
        final storeQuery = await FirebaseFirestore.instance.collection('stores').where('storeName', isEqualTo: sellerName).limit(1).get();
        if (storeQuery.docs.isNotEmpty) targetSellerId = storeQuery.docs.first.id; 
      }

      if (targetSellerId.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seller account not found.')));
        return;
      }

      if (targetSellerId == currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is your own product.')));
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
          'unreadCount': {currentUser.uid: 0, targetSellerId: 0},
        });
        chatId = newDoc.id;
      }

      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(runnerName: sellerName, chatId: chatId, otherUserId: targetSellerId)));
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          builder: (sheetContext) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 6),
                  Text('Sold by $sellerName', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext); 
                            openProductDetail(); 
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
                            Navigator.pop(sheetContext); 
                            openChatSeller(); 
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
        padding: const EdgeInsets.all(12), // Padding dalam kad
        decoration: BoxDecoration( 
          color: kWhite,
          borderRadius: BorderRadius.circular(22), // Lebih melengkung sikit
          boxShadow: [ 
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // ─── GAMBAR KIRI ───
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: kPrimary.withOpacity(0.05),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            
            // ─── DETAILS KANAN ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tajuk & Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title, 
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A1A2E)), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? kPrimary).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(color: badgeColor ?? kPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Description
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Harga & Butang Add
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM${price.toStringAsFixed(2)}', 
                        style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 16)
                      ),
                      
                      // Butang Bakul (Add to Cart icon) macam kat reference
                      Container(
                        width: 32, 
                        height: 32,
                        decoration: const BoxDecoration(
                          color: kPrimary, 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_shopping_cart_rounded, color: kWhite, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}