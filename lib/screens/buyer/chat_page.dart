import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class ChatPage extends StatefulWidget {
  final String runnerName;
  final String? chatId;
  final String? otherUserId;
  
  const ChatPage({
    super.key,
    this.runnerName = 'Ahmad Faizal',
    this.chatId,
    this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markCurrentUserAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final tod = TimeOfDay.fromDateTime(dt);
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _markCurrentUserAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.chatId == null) return;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final snap = await chatRef.get();
    final data = snap.data();
    if (data == null) return;

    final unreadRaw = (data['unreadCount'] as Map?) ?? {};
    final unreadMap = unreadRaw.map((k, v) {
      final parsed = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      return MapEntry(k.toString(), parsed);
    });
    unreadMap[uid] = 0;
    await chatRef.update({'unreadCount': unreadMap});
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (widget.chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open chat from inbox to start messaging.')),
      );
      return;
    }

    _messageController.clear();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    await chatRef.collection('messages').add({
      'text': text,
      'senderId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    final chatSnap = await chatRef.get();
    final chatData = chatSnap.data() ?? {};
    final participantsRaw = (chatData['participants'] as List?) ?? [];
    final participants = participantsRaw.whereType<String>().toList();

    final unreadRaw = (chatData['unreadCount'] as Map?) ?? {};
    final unreadMap = unreadRaw.map((k, v) {
      final parsed = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
      return MapEntry(k.toString(), parsed);
    });

    for (final p in participants) {
      if (p == uid) {
        unreadMap[p] = 0;
      } else {
        unreadMap[p] = (unreadMap[p] ?? 0) + 1;
      }
    }

    await chatRef.update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': unreadMap,
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final hasText = _messageController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1A1A2E), size: 22),
            onPressed: () {},
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
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100'),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: kPrimary.withOpacity(0.18), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.runnerName,
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.call_rounded, color: kPrimary, size: 19),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.chatId == null
                  ? Center(
                      child: Text(
                        'No chat room linked.\nOpen from Inbox to chat seller.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .collection('messages')
                          .orderBy('createdAt', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: kPrimary),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load messages',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No messages yet. Say hi 👋',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                          }
                        });
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final senderId = data['senderId']?.toString() ?? '';
                            final isMe = senderId == currentUserId;
                            return _buildChatBubble(
                              text: data['text']?.toString() ?? '',
                              isMe: isMe,
                              time: _formatTime(data['createdAt'] as Timestamp?),
                            );
                          },
                        );
                      },
                    ),
            ),
            
            Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 10),
              decoration: BoxDecoration(
                color: kWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 5,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.attach_file_rounded, color: Colors.grey.shade600),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.camera_alt_rounded, color: Colors.grey.shade600),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: hasText ? _sendMessage : () {},
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasText ? kAccent : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        hasText ? Icons.send_rounded : Icons.mic_rounded,
                        color: kWhite,
                        size: 22,
                      ),
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

  Widget _buildChatBubble({
    required String text,
    required bool isMe,
    required String time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? kPrimary.withOpacity(0.15) : kWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF111B21),
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 14, color: kPrimary.withOpacity(0.7)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}