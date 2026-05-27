import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/product_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'chat_page.dart';
import 'product_detail_page.dart'; // Make sure this matches your file name

// --- Color Constants ---
const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class StoreProfilePage extends StatelessWidget {
  final String sellerId;

  const StoreProfilePage({
    super.key,
    required this.sellerId,
  });

  Future<Map<String, String>> _fetchSellerDetails() async {
    Future<Map<String, String>?> tryCollection(String collectionName) async {
      final doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(sellerId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data() ?? <String, dynamic>{};
      final storeName =
          (data['storeName'] ?? data['shopName'] ?? data['sellerName'] ?? data['name'] ?? 'Unknown Store')
              .toString();
      final location =
          (data['kolej'] ?? data['college'] ?? data['location'] ?? data['address'] ?? 'Location not available')
              .toString();
      final description = (data['description'] ?? data['storeDescription'] ?? data['bio'] ?? 'No description available.')
          .toString();
      return {
        'storeName': storeName,
        'location': location,
        'description': description,
        'bannerUrl': (data['bannerUrl'] ?? data['coverImageUrl'] ?? data['imageUrl'] ?? '').toString(),
      };
    }

    final fromStores = await tryCollection('stores');
    if (fromStores != null) return fromStores;

    final fromUsers = await tryCollection('users');
    if (fromUsers != null) return fromUsers;

    final fromSellers = await tryCollection('sellers');
    if (fromSellers != null) return fromSellers;

    return {
      'storeName': 'Unknown Store',
      'location': 'Location not available',
      'description': 'No description available.',
      'bannerUrl': '',
    };
  }

  Future<void> _openChatSeller(BuildContext context, String sellerName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to start chat.')),
      );
      return;
    }

    if (sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller account not found.')),
      );
      return;
    }

    if (sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own store.')),
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
      if (participants.contains(sellerId)) {
        chatId = doc.id;
        break;
      }
    }

    if (chatId == null) {
      final newDoc = await chatsRef.add({
        'participants': [currentUser.uid, sellerId],
        'participantNames': {
          currentUser.uid: currentUser.displayName ?? 'Buyer',
          sellerId: sellerName,
        },
        'participantRoles': {
          currentUser.uid: 'Buyer',
          sellerId: 'Seller',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUser.uid: 0, sellerId: 0},
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
          otherUserId: sellerId,
        ),
      ),
    );
  }

  Stream<bool> _isFollowingStoreStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream<bool>.value(false);

    return FirebaseFirestore.instance
        .collection('stores')
        .doc(sellerId)
        .collection('followers')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> _toggleFollowStore(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to follow stores.')),
      );
      return;
    }

    if (sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot follow your own store.')),
      );
      return;
    }

    final followerRef = FirebaseFirestore.instance
        .collection('stores')
        .doc(sellerId)
        .collection('followers')
        .doc(currentUser.uid);

    final followerDoc = await followerRef.get();
    if (followerDoc.exists) {
      await followerRef.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from followed stores.')),
      );
      return;
    }

    await followerRef.set({
      'userId': currentUser.uid,
      'followedAt': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Store added to followed stores.')),
    );
  }

  Future<void> _copyStoreLink(BuildContext context, String storeName) async {
    final storeLink = 'umart://store/$sellerId';
    await Clipboard.setData(ClipboardData(text: storeLink));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Store link copied for $storeName')),
    );
  }

  void _showStoreActionsSheet(BuildContext context, String storeName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: kPrimary),
                  title: const Text('Copy Store Link'),
                  subtitle: Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _copyStoreLink(context, storeName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: kAccent),
                  title: const Text('Report Store'),
                  subtitle: const Text('Tell us if something looks wrong'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanks. Reporting tools will be available soon.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // --- COLLAPSING BANNER (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            backgroundColor: kPrimary,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [SizedBox(width: 8)],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Store Banner Image
                  Image.network(
                    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800', 
                    fit: BoxFit.cover,
                  ),
                  // Dark gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- STORE INFO SECTION ---
          SliverToBoxAdapter(
            child: FutureBuilder<Map<String, String>>(
              future: _fetchSellerDetails(),
              builder: (context, snapshot) {
                final seller = snapshot.data ??
                    {
                      'storeName': 'Loading...',
                      'location': 'Loading location...',
                      'description': 'Loading description...',
                      'bannerUrl': '',
                    };
                final storeName = seller['storeName'] ?? 'Store';
                return Container(
                  transform: Matrix4.translationValues(0.0, -20.0, 0.0), // Pull it up over the banner
                  decoration: const BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    storeName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1A2E),
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: kAccent, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          seller['location'] ?? 'Location not available',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildInfoChip(Icons.storefront_rounded, 'Campus Seller'),
                                      _buildInfoChip(Icons.verified_rounded, 'Verified'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          seller['description'] ?? 'No description available.',
                          style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openChatSeller(
                                  context,
                                  storeName,
                                ),
                                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                                label: const Text(
                                  'Chat Seller',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: kWhite,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            StreamBuilder<bool>(
                              stream: _isFollowingStoreStream(),
                              builder: (context, followSnapshot) {
                                final isFollowing = followSnapshot.data ?? false;
                                return OutlinedButton(
                                  onPressed: () => _toggleFollowStore(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isFollowing ? kAccent : kPrimary,
                                    side: BorderSide(
                                      color: (isFollowing ? kAccent : kPrimary).withOpacity(0.4),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Icon(
                                    isFollowing ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showStoreActionsSheet(context, storeName),
                            icon: const Icon(Icons.more_horiz_rounded, size: 18),
                            label: const Text('More Actions'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.black12, height: 1),
                        const SizedBox(height: 20),
                        const Text(
                          'All Items',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- PRODUCT GRID ---
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('sellerId', isEqualTo: sellerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: kPrimary)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Failed to load store items.')),
                  ),
                );
              }

              final docs = (snapshot.data?.docs ?? [])
                  .where((d) => productIsApproved(d.data()))
                  .toList();

              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: Center(
                      child: Text(
                        'No products available yet.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      return _buildProductCard(context, doc.data(), productId: doc.id);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // HELPER WIDGET: Product Card
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product, {required String productId}) {
    final productName = (product['name'] ?? 'Unnamed Product').toString();
    final productPrice = product['price'] is num
        ? (product['price'] as num).toDouble()
        : double.tryParse((product['price'] ?? '').toString()) ?? 0.0;
    final productImage = (product['imageUrl'] ?? product['image'] ?? '').toString();
    final productDescription = (product['description'] ?? 'No description available.').toString();
    final productSellerName = (product['sellerName'] ?? 'Unknown Seller').toString();
    final productVariations = (product['variations'] is List)
        ? (product['variations'] as List).whereType<String>().toList()
        : <String>[];

    return GestureDetector(
      onTap: () {
        // --- BAWA DATA BARANG MASUK KE BILIK DETAIL ---
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(
          productId: productId,
          name: productName,
          price: productPrice,
          imageUrl: productImage,
          sellerId: sellerId,
          sellerName: productSellerName,
          description: productDescription,
          variations: productVariations,
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  productImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: kPrimary.withOpacity(0.08),
                    child: const Icon(Icons.image_not_supported_outlined, color: kPrimary, size: 34),
                  ),
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('RM ${productPrice.toStringAsFixed(2)}', style: const TextStyle(color: kAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}