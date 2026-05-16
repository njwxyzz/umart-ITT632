import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const kPrimary = Color(0xFF4C6B3F);
const kAccent = Color(0xFFF27B35);
const kBg = Color(0xFFF5F7F2);
const kWhite = Colors.white;

const int _kMaxAttachmentBytes = 25 * 1024 * 1024;

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
  late final Future<Map<String, String>> _otherUserMetaFuture;

  Future<Map<String, String>> _loadOtherUserMeta() async {
    final fallback = <String, String>{
      'name': widget.runnerName,
      'photoUrl': '',
    };

    try {
      String? otherId = widget.otherUserId;

      if ((otherId == null || otherId.isEmpty) && widget.chatId != null) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        final chatDoc =
            await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
        final chatData = chatDoc.data() ?? <String, dynamic>{};
        final participantsRaw = (chatData['participants'] as List?) ?? [];
        final participants = participantsRaw.whereType<String>().toList();
        if (currentUid != null && participants.isNotEmpty) {
          for (final id in participants) {
            if (id != currentUid) {
              otherId = id;
              break;
            }
          }
        }
      }

      if (otherId == null || otherId.isEmpty) return fallback;

      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(otherId).get();
      if (storeDoc.exists) {
        final storeData = storeDoc.data() ?? <String, dynamic>{};
        final storeName = (storeData['storeName'] ?? widget.runnerName).toString();
        final storePhoto = (storeData['storePhotoUrl'] ??
                storeData['storePhoto'] ??
                storeData['logoUrl'] ??
                storeData['profileImage'] ??
                storeData['imageUrl'] ??
                '')
            .toString();
        return <String, String>{
          'name': storeName,
          'photoUrl': storePhoto,
        };
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() ?? <String, dynamic>{};
        final userName =
            (userData['fullName'] ?? userData['name'] ?? widget.runnerName).toString();
        final userPhoto = (userData['photoUrl'] ??
                userData['profilePic'] ??
                userData['profileImage'] ??
                userData['imageUrl'] ??
                '')
            .toString();
        return <String, String>{
          'name': userName,
          'photoUrl': userPhoto,
        };
      }
    } catch (_) {}

    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _otherUserMetaFuture = _loadOtherUserMeta();
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

  String _previewForStoredMessage(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'text').toString();
    if (type == 'image') {
      final caption = (data['text'] ?? '').toString().trim();
      return caption.isNotEmpty ? '📷 $caption' : '📷 Photo';
    }
    if (type == 'file') {
      final name = (data['fileName'] ?? 'Attachment').toString().trim();
      return name.isEmpty ? '📎 File' : '📎 $name';
    }
    return (data['text'] ?? '').toString();
  }

  String _inferStorageExtension(String fileLabel, String contentType) {
    final dot = fileLabel.lastIndexOf('.');
    if (dot != -1 && dot < fileLabel.length - 1) {
      final ext =
          fileLabel.substring(dot + 1).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (ext.isNotEmpty && ext.length <= 8) return ext;
    }
    final mime = contentType.toLowerCase();
    if (mime.contains('pdf')) return 'pdf';
    if (mime.contains('png')) return 'png';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('webp')) return 'webp';
    if (mime.contains('gif')) return 'gif';
    if (mime.contains('sheet') || mime.contains('excel')) return 'xlsx';
    if (mime.contains('word')) return 'docx';
    if (mime.contains('zip')) return 'zip';
    return 'bin';
  }

  Future<void> _syncChatLastMessage(
    DocumentReference<Map<String, dynamic>> chatRef,
    String senderUid,
    String lastMessagePreview,
  ) async {
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
      if (p == senderUid) {
        unreadMap[p] = 0;
      } else {
        unreadMap[p] = (unreadMap[p] ?? 0) + 1;
      }
    }

    await chatRef.update({
      'lastMessage': lastMessagePreview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': unreadMap,
    });
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid link')));
      }
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file')),
      );
    }
  }

  void _showImagePreview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  loadingBuilder: (c, child, prog) {
                    if (prog == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: kWhite)),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: kWhite),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSendAttachment({
    required Uint8List bytes,
    required String contentType,
    required String suggestedName,
    required String messageType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chatId = widget.chatId;
    if (uid == null || chatId == null) return;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    var uploadDialogShown = false;

    try {
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kPrimary),
                      SizedBox(height: 16),
                      Text('Sending…', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        uploadDialogShown = true;
      }

      final ext = _inferStorageExtension(suggestedName, contentType);
      final objectPath =
          '${DateTime.now().millisecondsSinceEpoch}_${uid.substring(0, 8)}.$ext';

      final ref = FirebaseStorage.instance.ref().child('chat_attachments/$chatId/$objectPath');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));

      final url = await ref.getDownloadURL();

      final payload = <String, dynamic>{
        'senderId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'type': messageType,
        'fileUrl': url,
        'text': '',
      };
      if (messageType == 'file') {
        payload['fileName'] = suggestedName.isNotEmpty ? suggestedName : 'Attachment';
      }

      await chatRef.collection('messages').add(payload);

      final preview =
          messageType == 'image' ? '📷 Photo' : '📎 ${payload['fileName']}';

      await _syncChatLastMessage(chatRef, uid, preview);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: $e')),
        );
      }
    } finally {
      if (uploadDialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (widget.chatId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open chat from inbox to start messaging.')),
        );
      }
      return;
    }
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _kMaxAttachmentBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large (max ~25 MB).')),
        );
        return;
      }
      final mime = xFile.mimeType ?? 'image/jpeg';
      await _uploadAndSendAttachment(
        bytes: bytes,
        contentType: mime,
        suggestedName: xFile.name,
        messageType: 'image',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (widget.chatId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open chat from inbox to start messaging.')),
        );
      }
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final f = result.files.single;
      final Uint8List? bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not load file in memory. Try another file or a smaller attachment.',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      if (bytes.length > _kMaxAttachmentBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large (max ~25 MB).')),
        );
        return;
      }
      final name =
          (f.name.isEmpty ? 'Attachment' : f.name).replaceAll(RegExp(r'[/\\\n\r]'), '_');
      // Derive MIME from extension
      String ct = 'application/octet-stream';
      final lower = name.toLowerCase();
      if (lower.endsWith('.pdf')) {
        ct = 'application/pdf';
      } else if (lower.endsWith('.png')) {
        ct = 'image/png';
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        ct = 'image/jpeg';
      } else if (lower.endsWith('.webp')) {
        ct = 'image/webp';
      } else if (lower.endsWith('.zip')) {
        ct = 'application/zip';
      }

      await _uploadAndSendAttachment(
        bytes: bytes,
        contentType: ct,
        suggestedName: name,
        messageType: 'file',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach file: $e')),
        );
      }
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: kPrimary),
              title: const Text('Photo — gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: kPrimary),
              title: const Text('Photo — camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file_rounded, color: kPrimary),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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

    await _syncChatLastMessage(chatRef, uid, text);
  }

  Future<void> _confirmAndDeleteMessage(QueryDocumentSnapshot<Map<String, dynamic>> messageDoc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chatId = widget.chatId;
    if (uid == null || chatId == null) return;

    final data = messageDoc.data();
    if ((data['senderId'] ?? '').toString() != uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own messages.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Remove this message from the chat? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      await messageDoc.reference.delete();

      final latest =
          await chatRef.collection('messages').orderBy('createdAt', descending: true).limit(1).get();
      if (latest.docs.isEmpty) {
        await chatRef.update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } else {
        final lastData = latest.docs.first.data();
        final lastPreview = _previewForStoredMessage(lastData);
        final lastTs = lastData['createdAt'];
        final update = <String, dynamic>{
          'lastMessage': lastPreview,
        };
        if (lastTs is Timestamp) {
          update['lastMessageTime'] = lastTs;
        } else {
          update['lastMessageTime'] = FieldValue.serverTimestamp();
        }
        await chatRef.update(update);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
              child: FutureBuilder<Map<String, String>>(
                future: _otherUserMetaFuture,
                builder: (context, snapshot) {
                  final info = snapshot.data ?? const <String, String>{};
                  final displayName = (info['name'] ?? widget.runnerName).trim();
                  final photoUrl = (info['photoUrl'] ?? '').trim();

                  return Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimary.withOpacity(0.18), width: 1.5),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, __) => Container(
                                  color: kPrimary.withOpacity(0.1),
                                  child:
                                      const Icon(Icons.person_rounded, color: kPrimary, size: 22),
                                ),
                              )
                            : Container(
                                color: kPrimary.withOpacity(0.1),
                                child: const Icon(Icons.person_rounded, color: kPrimary, size: 22),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isEmpty ? widget.runnerName : displayName,
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
                  );
                },
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
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Unable to load messages',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Check your connection and reopen this chat.',
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
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
                            final doc = docs[index];
                            final data = doc.data();
                            final senderId = data['senderId']?.toString() ?? '';
                            final isMe = senderId == currentUserId;
                            return _buildChatBubble(
                              messageDoc: doc,
                              messageData: data,
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
                            onPressed: _showAttachmentSheet,
                          ),
                          IconButton(
                            icon: Icon(Icons.camera_alt_rounded, color: Colors.grey.shade600),
                            onPressed: () => _pickAndUploadImage(ImageSource.camera),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return GestureDetector(
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
                      );
                    },
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
    required QueryDocumentSnapshot<Map<String, dynamic>> messageDoc,
    required Map<String, dynamic> messageData,
    required bool isMe,
    required String time,
  }) {
    final type = (messageData['type'] ?? 'text').toString();
    final text = messageData['text']?.toString() ?? '';
    final fileUrl = messageData['fileUrl']?.toString() ?? '';
    final fileName =
        (messageData['fileName'] ?? '').toString().trim().isEmpty
            ? 'File'
            : messageData['fileName'].toString();

    Widget content;
    if (type == 'image' && fileUrl.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showImagePreview(fileUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 220,
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, prog) {
                    if (prog == null) return child;
                    final total = prog.expectedTotalBytes;
                    return Container(
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: kPrimary,
                            strokeWidth: 3,
                            value: total != null && total > 0
                                ? prog.cumulativeBytesLoaded / total
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, __) => Container(
                    color: Colors.grey.shade200,
                    height: 100,
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500, size: 40),
                  ),
                ),
              ),
            ),
          ),
          if (text.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(color: Color(0xFF111B21), fontSize: 14, height: 1.3),
            ),
          ],
        ],
      );
    } else if (type == 'file' && fileUrl.isNotEmpty) {
      content = InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLink(context, fileUrl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_rounded, color: kPrimary, size: 26),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111B21),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 17, color: Colors.grey.shade600),
            ],
          ),
        ),
      );
    } else {
      content = Text(
        text,
        style: const TextStyle(
          color: Color(0xFF111B21),
          fontSize: 14,
          height: 1.3,
        ),
      );
    }

    return GestureDetector(
      onLongPress: isMe ? () => _confirmAndDeleteMessage(messageDoc) : null,
      behavior: HitTestBehavior.opaque,
      child: Align(
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
              content,
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
      ),
    );
  }
}
