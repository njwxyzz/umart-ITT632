import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../utils/product_status.dart';
import '../../utils/store_status.dart';
import '../../widgets/report_store_sheet.dart';
import '../../utils/store_deep_link.dart';
import 'chat_page.dart';
import 'product_detail_page.dart';

const kPrimary = Color(0xFF4C6B3F);
const kAccent = Color(0xFFF27B35);
const kBg = Color(0xFFF5F7F2);
const kWhite = Colors.white;
const kTextDark = Color(0xFF1A1A2E);

class _StoreProfile {
  final String storeName;
  final String location;
  final String description;
  final String photoUrl;
  final String category;
  final Map<String, dynamic> raw;

  const _StoreProfile({
    required this.storeName,
    required this.location,
    required this.description,
    required this.photoUrl,
    required this.category,
    required this.raw,
  });

  bool get isVerified => storeIsApproved(raw);
  bool get isPending => storeIsPending(raw);

  factory _StoreProfile.fromMap(Map<String, dynamic> data) {
    final storeName = (data['storeName'] ??
            data['shopName'] ??
            data['sellerName'] ??
            data['name'] ??
            'Store')
        .toString()
        .trim();
    final location = (data['storeLocation'] ??
            data['kolej'] ??
            data['college'] ??
            data['location'] ??
            data['address'] ??
            'Location not set')
        .toString()
        .trim();
    final description = (data['description'] ??
            data['storeDescription'] ??
            data['bio'] ??
            'No description yet.')
        .toString()
        .trim();
    final photoUrl = (data['storePhotoUrl'] ??
            data['bannerUrl'] ??
            data['coverImageUrl'] ??
            data['logoUrl'] ??
            data['imageUrl'] ??
            '')
        .toString()
        .trim();
    final category = (data['category'] ?? 'General').toString().trim();

    return _StoreProfile(
      storeName: storeName.isEmpty ? 'Store' : storeName,
      location: location.isEmpty ? 'Location not set' : location,
      description: description.isEmpty ? 'No description yet.' : description,
      photoUrl: photoUrl,
      category: category.isEmpty ? 'General' : category,
      raw: data,
    );
  }

  static const unknown = _StoreProfile(
    storeName: 'Store',
    location: 'Location not available',
    description: 'This seller has not set up a store profile yet.',
    photoUrl: '',
    category: 'General',
    raw: {},
  );
}

class StoreProfilePage extends StatelessWidget {
  final String sellerId;

  const StoreProfilePage({
    super.key,
    required this.sellerId,
  });

  Future<_StoreProfile> _fetchFallbackProfile() async {
    try {
      final byOwner = await FirebaseFirestore.instance
          .collection('stores')
          .where('ownerId', isEqualTo: sellerId)
          .limit(1)
          .get();
      if (byOwner.docs.isNotEmpty) {
        return _StoreProfile.fromMap(byOwner.docs.first.data());
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
      if (userDoc.exists) {
        final data = userDoc.data() ?? <String, dynamic>{};
        return _StoreProfile.fromMap({
          'storeName': data['fullName'] ?? data['name'],
          'storeLocation': data['college'] ?? data['kolej'],
          'description': data['bio'] ?? data['description'],
          'storePhotoUrl': data['profileImage'] ?? data['photoUrl'],
          'category': 'General',
          'status': 'Approved',
        });
      }
    } catch (_) {}

    return _StoreProfile.unknown;
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
    final existing =
        await chatsRef.where('participants', arrayContains: currentUser.uid).get();

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
    final storeLink = buildStoreShareLink(sellerId);
    await Clipboard.setData(ClipboardData(text: storeLink));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Link copied for $storeName. Open it in UMART to visit this store.',
        ),
      ),
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
                  subtitle: Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                    showReportStoreSheet(
                      context,
                      sellerId: sellerId,
                      storeName: storeName,
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .doc(sellerId)
            .snapshots(),
        builder: (context, storeSnap) {
          if (storeSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final storeData = storeSnap.data?.data();
          if (storeData != null) {
            return _buildBody(
              context,
              profile: _StoreProfile.fromMap(storeData),
            );
          }

          return FutureBuilder<_StoreProfile>(
            future: _fetchFallbackProfile(),
            builder: (context, fallbackSnap) {
              final profile = fallbackSnap.data ?? _StoreProfile.unknown;
              if (fallbackSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: kPrimary),
                );
              }
              return _buildBody(context, profile: profile);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required _StoreProfile profile}) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 168,
          pinned: true,
          backgroundColor: kPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kWhite,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_horiz_rounded, color: kWhite, size: 20),
              ),
              onPressed: () => _showStoreActionsSheet(context, profile.storeName),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _StoreBanner(imageUrl: profile.photoUrl),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreHeaderCard(
                  profile: profile,
                  sellerId: sellerId,
                  onChat: () => _openChatSeller(context, profile.storeName),
                  onFollow: () => _toggleFollowStore(context),
                  followStream: _isFollowingStoreStream(),
                ),
                const SizedBox(height: 28),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('sellerId', isEqualTo: sellerId)
                        .snapshots(),
                    builder: (context, productSnap) {
                      final approvedCount = (productSnap.data?.docs ?? [])
                          .where((d) => productIsApproved(d.data()))
                          .length;

                      return Row(
                        children: [
                          Text(
                            'Products',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$approvedCount',
                              style: const TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: sellerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load products',
                  subtitle: 'Pull down to refresh or try again later.',
                ),
              );
            }

            final docs = (snapshot.data?.docs ?? [])
                .where((d) => productIsApproved(d.data()))
                .toList()
              ..sort((a, b) {
                final nameA = (a.data()['name'] ?? '').toString().toLowerCase();
                final nameB = (b.data()['name'] ?? '').toString().toLowerCase();
                return nameA.compareTo(nameB);
              });

            if (docs.isEmpty) {
              return SliverToBoxAdapter(
                child: _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  subtitle:
                      'This store has not listed any approved items. Check back soon.',
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];
                    return _ProductCard(
                      productId: doc.id,
                      product: doc.data(),
                      sellerId: sellerId,
                    );
                  },
                  childCount: docs.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StoreBanner extends StatelessWidget {
  final String imageUrl;

  const _StoreBanner({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _BannerPlaceholder(),
          )
        else
          const _BannerPlaceholder(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A7D4C), kPrimary],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 72,
          color: kWhite.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _StoreHeaderCard extends StatelessWidget {
  final _StoreProfile profile;
  final String sellerId;
  final VoidCallback onChat;
  final VoidCallback onFollow;
  final Stream<bool> followStream;

  const _StoreHeaderCard({
    required this.profile,
    required this.sellerId,
    required this.onChat,
    required this.onFollow,
    required this.followStream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StoreAvatar(imageUrl: profile.photoUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.storeName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: kTextDark,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: kAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.location,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.category_rounded,
                label: profile.category,
                color: kPrimary,
              ),
              if (profile.isVerified)
                const _InfoChip(
                  icon: Icons.verified_rounded,
                  label: 'Verified',
                  color: Color(0xFF2E7D32),
                )
              else if (profile.isPending)
                const _InfoChip(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Pending approval',
                  color: Color(0xFFE65100),
                ),
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('stores')
                .doc(sellerId)
                .collection('followers')
                .snapshots(),
            builder: (context, followersSnap) {
              final followerCount = followersSnap.data?.docs.length ?? 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Followers',
                        value: '$followerCount',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey.shade300,
                    ),
                    const Expanded(
                      child: _StatTile(
                        label: 'Campus',
                        value: 'UiTM',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'About',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.description,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text(
                    'Chat Seller',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: kWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StreamBuilder<bool>(
                stream: followStream,
                builder: (context, followSnapshot) {
                  final isFollowing = followSnapshot.data ?? false;
                  return OutlinedButton(
                    onPressed: onFollow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFollowing ? kAccent : kPrimary,
                      side: BorderSide(
                        color: (isFollowing ? kAccent : kPrimary)
                            .withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Icon(
                      isFollowing
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  final String imageUrl;

  const _StoreAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _AvatarFallback(),
            )
          : const _AvatarFallback(),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary.withValues(alpha: 0.12),
      child: const Icon(Icons.storefront_rounded, color: kPrimary, size: 30),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: kPrimary.withValues(alpha: 0.45)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> product;
  final String sellerId;

  const _ProductCard({
    required this.productId,
    required this.product,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final productName = (product['name'] ?? 'Unnamed Product').toString();
    final productPrice = product['price'] is num
        ? (product['price'] as num).toDouble()
        : double.tryParse((product['price'] ?? '').toString()) ?? 0.0;
    final productImage =
        (product['imageUrl'] ?? product['image'] ?? '').toString();
    final productDescription =
        (product['description'] ?? 'No description available.').toString();
    final productSellerName =
        (product['sellerName'] ?? 'Unknown Seller').toString();
    final productVariations = (product['variations'] is List)
        ? (product['variations'] as List).whereType<String>().toList()
        : <String>[];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              productId: productId,
              name: productName,
              price: productPrice,
              imageUrl: productImage,
              sellerId: sellerId,
              sellerName: productSellerName,
              description: productDescription,
              variations: productVariations,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _productImageFallback(),
                      )
                    : _productImageFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: kTextDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RM ${productPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productImageFallback() {
    return Container(
      color: kPrimary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: kPrimary,
          size: 32,
        ),
      ),
    );
  }
}
