import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart'; 

const kPrimary = Color(0xFF4C6B3F); 
const kAccent  = Color(0xFFF27B35); 
const kBg      = Color(0xFFF5F7F2); 
const kWhite   = Colors.white;

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState(); 
}

class _InboxPageState extends State<InboxPage> {
  bool _isSearching = false;
  String _searchQuery = '';
  final Map<String, Future<Map<String, String>>> _identityFutureCache = {};

  Future<Map<String, String>> _loadChatIdentity(String otherUid, String fallbackName) async {
    final fallback = <String, String>{
      'name': fallbackName,
      'photoUrl': '',
    };

    try {
      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(otherUid).get();
      if (storeDoc.exists) {
        final storeData = storeDoc.data() ?? <String, dynamic>{};
        final storeName = (storeData['storeName'] ?? fallbackName).toString().trim();
        final storePhoto = (storeData['storePhotoUrl'] ??
                storeData['storePhoto'] ??
                storeData['logoUrl'] ??
                storeData['profileImage'] ??
                storeData['imageUrl'] ??
                '')
            .toString()
            .trim();
        return <String, String>{
          'name': storeName.isEmpty ? fallbackName : storeName,
          'photoUrl': storePhoto,
        };
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() ?? <String, dynamic>{};
        final fullName = (userData['fullName'] ?? userData['name'] ?? fallbackName).toString().trim();
        final photoUrl = (userData['photoUrl'] ??
                userData['profilePic'] ??
                userData['profileImage'] ??
                userData['imageUrl'] ??
                '')
            .toString()
            .trim();
        return <String, String>{
          'name': fullName.isEmpty ? fallbackName : fullName,
          'photoUrl': photoUrl,
        };
      }
    } catch (_) {}

    return fallback;
  }

  Future<Map<String, String>> _getChatIdentityFuture(String otherUid, String fallbackName) {
    return _identityFutureCache.putIfAbsent(
      otherUid,
      () => _loadChatIdentity(otherUid, fallbackName),
    );
  }

  String _formatMessageTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    if (isToday) {
      final tod = TimeOfDay.fromDateTime(dt);
      final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final minute = tod.minute.toString().padLeft(2, '0');
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
    if (isYesterday) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: _isSearching
            ? TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              )
            : const Text(
                'Messages',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_pattern.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
          ),
        ),
        child: currentUserId == null
            ? Center(
                child: Text(
                  'Please sign in to view messages',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load conversations',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check your connection and try again shortly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = [...(snapshot.data?.docs ?? [])]
                    ..sort((a, b) {
                      final ta = a.data()['lastMessageTime'] as Timestamp?;
                      final tb = b.data()['lastMessageTime'] as Timestamp?;
                      final da =
                          ta?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final db =
                          tb?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return db.compareTo(da); 
                    });

                  final chatTiles = docs.map((doc) {
                    final data = doc.data();
                    final participantsRaw = (data['participants'] as List?) ?? [];
                    final participants = participantsRaw
                        .whereType<String>()
                        .toList(growable: false);
                    final otherUid = participants.firstWhere(
                      (uid) => uid != currentUserId,
                      orElse: () => currentUserId,
                    );

                    final namesRaw = (data['participantNames'] as Map?) ?? {};
                    final unreadRaw = (data['unreadCount'] as Map?) ?? {};

                    final names = namesRaw.map(
                      (key, value) =>
                          MapEntry(key.toString(), value.toString()),
                    );
                    final unreadMap = unreadRaw.map((key, value) {
                      final parsed = value is int
                          ? value
                          : int.tryParse(value?.toString() ?? '0') ?? 0;
                      return MapEntry(key.toString(), parsed);
                    });

                    final fallbackName = names[otherUid] ?? 'Unknown User';
                    final lastMessage =
                        (data['lastMessage']?.toString() ?? '').trim().isEmpty
                            ? 'No messages yet'
                            : data['lastMessage'].toString();
                    final lastMessageTime =
                        _formatMessageTime(data['lastMessageTime'] as Timestamp?);
                    final unread = unreadMap[currentUserId] ?? 0;

                    return {
                      'chatId': doc.id,
                      'otherUid': otherUid,
                      'fallbackName': fallbackName,
                      'lastMessage': lastMessage,
                      'lastMessageTime': lastMessageTime,
                      'unread': unread,
                    };
                  }).toList();

                  final query = _searchQuery.toLowerCase();
                  final filteredTiles = query.isEmpty
                      ? chatTiles
                      : chatTiles.where((chat) {
                          final name =
                              (chat['fallbackName']?.toString() ?? '').toLowerCase();
                          final message =
                              (chat['lastMessage']?.toString() ?? '').toLowerCase();
                          return name.contains(query) || message.contains(query);
                        }).toList();

                  if (filteredTiles.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No messages yet'
                                  : 'No results found',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Start chatting with sellers to see your inbox here.'
                                  : 'Try searching with another keyword.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredTiles.length,
                    itemBuilder: (context, index) {
                      final chat = filteredTiles[index];
                      final otherUid = chat['otherUid'] as String;
                      final lastMessage = chat['lastMessage'] as String;
                      final lastMessageTime = chat['lastMessageTime'] as String;
                      final unread = chat['unread'] as int;
                      final hasUnread = unread > 0;

                      return FutureBuilder<Map<String, String>>(
                        future: _getChatIdentityFuture(otherUid, chat['fallbackName'] as String),
                        builder: (context, identitySnap) {
                          final identity = identitySnap.data ?? const <String, String>{};
                          final finalDisplayName = (identity['name'] ?? (chat['fallbackName'] as String)).trim();
                          final profileUrl = (identity['photoUrl'] ?? '').trim();

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatPage(
                                        runnerName: finalDisplayName,
                                        chatId: chat['chatId'] as String,
                                        otherUserId: otherUid,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.045),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFE6ECD9),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: profileUrl.isNotEmpty
                                        ? Image.network(
                                            profileUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                finalDisplayName.isNotEmpty
                                                    ? finalDisplayName[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1A1A2E),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              finalDisplayName.isNotEmpty
                                                  ? finalDisplayName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A1A2E),
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          finalDisplayName.isEmpty
                                              ? (chat['fallbackName'] as String)
                                              : finalDisplayName,
                                          style: TextStyle(
                                            fontWeight: hasUnread
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 15,
                                            color: const Color(0xFF1A1A2E),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lastMessage,
                                          style: TextStyle(
                                            color: hasUnread
                                                ? const Color(0xFF1A1A2E)
                                                : Colors.grey.shade500,
                                            fontSize: 13,
                                            fontWeight: hasUnread
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        lastMessageTime,
                                        style: TextStyle(
                                          color: hasUnread
                                              ? kAccent
                                              : Colors.grey.shade400,
                                          fontSize: 11,
                                          fontWeight: hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (hasUnread)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: kAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unread.toString(),
                                            style: const TextStyle(
                                              color: kWhite,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}