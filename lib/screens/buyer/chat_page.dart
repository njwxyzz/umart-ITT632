import 'package:flutter/material.dart';

// ─── Color Constants (TEMA HIJAU BARU) ───────────────────────────────────────
const kPrimary      = Color(0xFF4C6B3F); 
const kAccent       = Color(0xFFF27B35); 
const kBg           = Color(0xFFF5F7F2); 
const kWhite        = Colors.white;

class ChatPage extends StatefulWidget {
  final String runnerName;
  
  const ChatPage({super.key, this.runnerName = 'Ahmad Faizal'});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// Model untuk Data Chat
class ChatMessage {
  final String text;
  final bool isMe; // true = Mesej dari student, false = Mesej dari runner
  final String time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  
  // Senarai mesej (Dummy data)
  final List<ChatMessage> _messages = [
    ChatMessage(text: 'Salam bang, order saya dah siap ke?', isMe: true, time: '12:35 PM'),
    ChatMessage(text: 'Wslm. Dah siap, saya tengah on the way pergi Kolej Dahlia ni.', isMe: false, time: '12:36 PM'),
    ChatMessage(text: 'Okay bang, nanti sampai call eh. Saya turun bawah.', isMe: true, time: '12:36 PM'),
    ChatMessage(text: 'Beres bos!', isMe: false, time: '12:37 PM'),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text,
        isMe: true,
        time: 'Now', // Acah-acah waktu sekarang
      ));
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          children: [
            // Gambar Profil Runner Kat Header
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100'), fit: BoxFit.cover),
                border: Border.all(color: kPrimary.withOpacity(0.2), width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.runnerName, style: const TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 15)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Online', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: kPrimary, size: 22),
            onPressed: () {
              // Fungsi Call nanti
            },
          ),
          const SizedBox(width: 8),
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
            // ─── KAWASAN CHAT BUBBLE ───
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            
            // ─── KAWASAN TAIP (BOTTOM INPUT BAR) ───
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: kWhite,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  // Ikon Attach Picture
                  Container(
                    decoration: BoxDecoration(color: kBg, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.grey, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kotak Taip
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Butang Hantar (Oren)
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: kAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: kWhite, size: 20),
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

  // WIDGET BANTUAN UNTUK BUBBLE CHAT
  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isMe ? kPrimary : kWhite, // Kalau aku taip: Hijau, Kalau runner: Putih
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4), // Ekor bubble
            bottomRight: Radius.circular(msg.isMe ? 4 : 16), // Ekor bubble
          ),
          boxShadow: [
            if (!msg.isMe) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? kWhite : const Color(0xFF1A1A2E),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: TextStyle(
                color: msg.isMe ? kWhite.withOpacity(0.7) : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}